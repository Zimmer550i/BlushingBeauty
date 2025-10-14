import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:uuid/uuid.dart';
import '../models/multi_body.dart';
import '../services/api_service.dart';
import '../services/shared_prefs_service.dart';
import '../services/socket_manager.dart';
import '../views/screen/Message/AllSubScreen/chat_screen.dart';
import '../views/screen/Message/groupChat/group_chat.dart';

class ChatController extends GetxController {
  final api = ApiService();

  /// Reactive State
  final RxBool isLoading = false.obs;
  final RxBool isPaginating = false.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  final ImagePicker _picker = ImagePicker();
  late ScrollController scrollController;

  /// Pagination
  int _currentPage = 1;
  final int _limit = 15;
  bool _hasMore = true;

  /// Session data
  late String _chatId;
  late String _currentUserId;
  late String token;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  void disconnect() {
    SocketService.clearChatListeners(_chatId);
    SocketService.disconnect();
  }

  // ==============================
  // CHAT FLOW
  // ==============================

  Future<void> initChat({
    required String chatId,
    required String currentUserId,
    required String token,
  }) async {
    _chatId = chatId;
    _currentUserId = currentUserId;
    token = token;

    /// 1️⃣ Fetch initial messages
    await fetchMessages();

    /// 2️⃣ Connect to socket
    SocketService.connect(token);

    /// 3️⃣ Delay a bit to ensure connection is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      /// ✅ Listen for messages only for this chat
      SocketService.onChatMessage(_chatId, (data) {
        final msg = _mapMessage(data, _currentUserId);

        if (msg["isMe"]) {
          final idx = messages.indexWhere(
                (m) => m["temp"] == true && m["message"] == msg["message"],
          );
          if (idx != -1) {
            messages[idx] = msg;
          } else {
            messages.insert(0, msg);
          }
        } else {
          messages.insert(0, msg);
        }
        _scrollToBottom();
      });

      /// ✍️ Typing listener
      SocketService.onTyping(_chatId, (data) {
        debugPrint("✍️ Typing: $data");
      });
    });
  }

  // ==============================
  // CREATE CHATS
  // ==============================

  Future<void> createPrivateChat(
      String name, String image, String memberId) async {
    isLoading.value = true;
    try {
      final response = await api.post(
        "/chat/create-private",
        {"member": memberId},
        authReq: true,
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatId = body['data']['_id'];
        Get.to(() => ChatScreen(
          chatId: chatId,
          receiverName: name,
          receiverImage: image,
        ));
      } else {
        debugPrint("⚠️ Failed: ${body['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error creating private chat: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createGroupChat(List<String> memberIds) async {
    isLoading.value = true;
    try {
      final response = await api.post(
        "/chat/create-group",
        {"members": memberIds},
        authReq: true,
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatId = body['data']['_id'];
        Get.to(() => GroupChatScreen(
          chatId: chatId,
          groupName: "Group Chat",
          groupImage: "",
        ));
      } else {
        debugPrint("⚠️ Failed: ${body['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error creating groupChat chat: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ==============================
  // FETCH MESSAGES (API)
  // ==============================

  Future<void> fetchMessages() async {
    _resetPagination();
    await _fetchPage(appendBottom: true);
    _scrollToBottom();
  }

  Future<void> loadOlder() async {
    if (!_hasMore || isPaginating.value) return;
    await _fetchPage(appendBottom: false);
  }

  Future<void> _fetchPage({bool appendBottom = true}) async {
    try {
      if (_currentPage == 1) {
        isLoading.value = true;
      } else {
        isPaginating.value = true;
      }

      final res = await api.get(
        "/chat/chat-inbox/$_chatId?limit=$_limit&page=$_currentPage",
        authReq: true,
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List rawMessages = body['data'];

        if (rawMessages.isEmpty) {
          _hasMore = false;
        } else {
          final mapped = rawMessages
              .map<Map<String, dynamic>>((m) => _mapMessage(m, _currentUserId))
              .toList();

          if (appendBottom) {
            messages.insertAll(0, mapped);
            _scrollToBottom();
          } else {
            messages.addAll(mapped);
          }
          _currentPage++;
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching messages: $e");
    } finally {
      isLoading.value = false;
      isPaginating.value = false;
    }
  }

  void _resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    messages.clear();
  }

  // ==============================
  // SOCKET SEND EVENTS
  // ==============================

  void sendText(String text) {
    final tempId = const Uuid().v4();

    SocketService.sendText(
      chatId: _chatId,
      senderId: _currentUserId,
      message: text,
    );

    messages.insert(0, {
      "_id": tempId,
      "isMe": true,
      "type": "text",
      "message": text,
      "media": "",
      "time":
      "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
      "temp": true,
    });
    _scrollToBottom();
  }

  Future<String?> uploadMedia(File file, {String type = "image"}) async {
    final multipartBody = [MultipartBody(key: type, file: file)];
    final response = await api.postMultipartData(
      "/message/upload",
      {},
      multipartBody: multipartBody,
      authReq: true,
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      return resData['mediaUrl'];
    } else {
      debugPrint("❗ Upload failed: ${response.body}");
      return null;
    }
  }

  Future<void> pickAndSendImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final mediaUrl = await uploadMedia(File(file.path), type: "image");
    if (mediaUrl != null) {
      SocketService.sendImage(
        chatId: _chatId,
        senderId: _currentUserId,
        mediaUrl: mediaUrl,
      );
    }
  }

  Future<void> pickAndSendVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final mediaUrl = await uploadMedia(File(file.path), type: "video");
    if (mediaUrl != null) {
      SocketService.sendVideo(
        chatId: _chatId,
        senderId: _currentUserId,
        mediaUrl: mediaUrl,
      );
    }
  }

  void sendTyping(bool isTyping) {
    SocketService.sendTyping(
      chatId: _chatId,
      senderId: _currentUserId,
      isTyping: isTyping,
    );
  }

  /// 📤 Send Image or Video to Multiple Chats
  Future<void> sendMediaToMultipleChats({
    required List<Map<String, dynamic>> friends,
    required Set<String> selectedIds,
    required File mediaFile,
    required String contentType, // 'image' or 'video'
  }) async {
    if (selectedIds.isEmpty) {
      debugPrint("⚠️ No friends selected to send media.");
      return;
    }

    try {
      isLoading.value = true;

      // 1️⃣ Upload media once
      final mediaUrl = await uploadMedia(mediaFile, type: contentType);
      if (mediaUrl == null) {
        debugPrint("❌ Media upload failed.");
        return;
      }

      // 2️⃣ Get user session info
      final userCtrl = Get.find<UserController>();
      final token = await SharedPrefsService.get('token');
      final senderId = userCtrl.userInfo.value?.id;

      if (token == null || senderId == null) {
        debugPrint("⚠️ Missing token or user ID.");
        return;
      }

      // ✅ Maintain one socket connection
      SocketService.connect(token);

      // 3️⃣ Loop and send to all friends
      for (final friend in friends) {
        if (!selectedIds.contains(friend['_id'])) continue;

        final chatId = friend['chatId'];
        if (chatId == null) {
          debugPrint("⚠️ No chatId found for ${friend['name']}");
          continue;
        }

        // Join specific chat
        await initChat(
          chatId: chatId,
          currentUserId: senderId,
          token: token,
        );

        // Send via socket
        if (contentType == 'image') {
          SocketService.sendImage(
            chatId: chatId,
            senderId: senderId,
            mediaUrl: mediaUrl,
          );
        } else {
          SocketService.sendVideo(
            chatId: chatId,
            senderId: senderId,
            mediaUrl: mediaUrl,
          );
        }

        // // ✅ Wait for backend to process the event
        // await Future.delayed(const Duration(milliseconds: 500));

        // // 🧩 Optional fallback: ensure DB persistence
        // try {
        //   await api.post(
        //     "/message/create",
        //     {
        //       "chatId": chatId,
        //       "sender": senderId,
        //       "media": mediaUrl,
        //       "contentType": contentType,
        //     },
        //     authReq: true,
        //   );
        //   debugPrint("💾 Message stored via REST for ${friend['name']}");
        // } catch (e) {
        //   debugPrint("⚠️ Skipped REST save fallback: $e");
        // }

        debugPrint("✅ Sent $contentType to ${friend['name']}");
      }

      Get.back();

      debugPrint("🎉 Media sent to ${selectedIds.length} friends successfully!");

    } catch (e) {
      debugPrint("❌ Error sending media to multiple chats: $e");
    } finally {
      // 🔌 Disconnect once after all sends are done
      SocketService.clearAllListeners();
      SocketService.disconnect();
      isLoading.value = false;
    }
  }





  // ==============================
  // HELPERS
  // ==============================

  Map<String, dynamic> _mapMessage(dynamic m, String currentUserId) {
    final createdAt = DateTime.tryParse(m['createdAt'] ?? '');
    final formattedTime = createdAt != null
        ? "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}"
        : "";

    return {
      "_id": m["_id"] ?? "",
      "isMe": m["sender"] is Map
          ? m["sender"]["_id"] == currentUserId
          : m["sender"] == currentUserId,
      "type": m["contentType"] ?? "text",
      "message": m["message"] ?? "",
      "media": m["media"] ?? "",
      "time": formattedTime,
      "temp": false,
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
