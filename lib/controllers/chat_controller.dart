import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/socket_manager.dart';
import '../views/screen/Message/AllSubScreen/chat_screen.dart';

class ChatController extends GetxController {
  final api = ApiService();

  /// Reactive state
  final RxBool isLoading = false.obs;
  final RxBool isPaginating = false.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  /// Pagination
  int _currentPage = 1;
  final int _limit = 15;
  bool _hasMore = true;

  /// Scroll
  late ScrollController scrollController;

  /// Current session
  late String _chatId;
  late String _currentUserId;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
  }

  void disconnect() {
    scrollController.dispose();
    SocketService.clearListeners();
    SocketService.disconnect();
    super.onClose();
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

    // 1. Fetch initial messages
    await fetchMessages();

    // 2. Connect socket
    SocketService.connect(token);

    // 3. Listen for new messages
    SocketService.onMessage((data) {
      final msg = _mapMessage(data, _currentUserId);
      messages.insert(0, msg); // 👈 insert at top because reverse:true
      _scrollToBottom();
    });

    // 4. Typing
    SocketService.onTyping((data) {
      debugPrint("✍️ Typing: $data");
    });
  }

  Future<void> createPrivateChat(
      String name, String image, String memberId, String currentUserId) async {
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
          currentUserId: currentUserId,
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

  // ==============================
  // API MESSAGES
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
            // 👇 for first load or new fetch: reverse insert
            messages.insertAll(0, mapped);
            _scrollToBottom();
          } else {
            // 👇 load older → append at end (because reverse: true flips it)
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
  // SOCKET SEND
  // ==============================

  void sendText(String text) {
    SocketService.sendText(
      chatId: _chatId,
      senderId: _currentUserId,
      message: text,
    );

    messages.insert(0, {
      "isMe": true,
      "type": "text",
      "message": text,
      "media": "",
      "time":
      "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
    });
    _scrollToBottom();
  }

  void sendImage(String mediaUrl) {
    SocketService.sendImage(
      chatId: _chatId,
      senderId: _currentUserId,
      mediaUrl: mediaUrl,
    );
  }

  void sendVideo(String mediaUrl) {
    SocketService.sendVideo(
      chatId: _chatId,
      senderId: _currentUserId,
      mediaUrl: mediaUrl,
    );
  }

  void sendTyping(bool isTyping) {
    SocketService.sendTyping(
      chatId: _chatId,
      senderId: _currentUserId,
      isTyping: isTyping,
    );
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
      "isMe": m["sender"] is Map
          ? m["sender"]["_id"] == currentUserId
          : m["sender"] == currentUserId,
      "type": m["contentType"] ?? "text",
      "message": m["message"] ?? "",
      "media": m["media"] ?? "",
      "time": formattedTime,
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0, // 👈 because reverse:true, "0" is bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
