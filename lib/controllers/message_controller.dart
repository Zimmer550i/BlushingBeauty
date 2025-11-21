import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import '../models/multi_body.dart';
import '../services/api_service.dart';

class MessageController extends GetxController {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final chatController = Get.put(ChatController());

  /// -----------------------------
  /// 🧩 CHATS (Private & Group)
  /// -----------------------------
  final privateChats = <dynamic>[].obs;
  final groupChats = <dynamic>[].obs;
  final isLoadingChats = false.obs;
  final chatPage = 1.obs;
  final hasMoreChats = true.obs;

  /// -----------------------------
  /// 🧩 STORIES
  /// -----------------------------
  final stories = <dynamic>[].obs;
  final isLoadingStories = false.obs;
  final isLoading = false.obs;
  final storyPage = 1.obs;
  final hasMoreStories = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChats();
    fetchStories();
  }

  Future<String?> getOrCreatePrivateChat(
    String userId,
    String name,
    String image,
  ) async {
    try {
      // Check if a private chat already exists with the given userId
      final existingChat = privateChats.firstWhere((chat) {
        // Check if any member in the chat has the userId
        return chat['members'].any((member) => member['_id'] == userId);
      }, orElse: () => null);

      if (existingChat != null) {
        // If a chat exists, return the existing chatId
        return existingChat['_id'];
      } else {
        // If no chat exists, create a new one
        await createChatAndSendReaction(name, image, userId);

        // After creating the chat, check if the new chat was added to the list
        final newChat = privateChats.firstWhere((chat) {
          // Check again after creation
          return chat['members'].any((member) => member['_id'] == userId);
        }, orElse: () => null);

        debugPrint("Chat ID: ${newChat?['_id']}");

        return newChat?['_id'];
      }
    } catch (e) {
      debugPrint("❌ Error in getOrCreatePrivateChat: $e");
      return null;
    }
  }
Future<void> createChatAndSendReaction(
    String name,
    String image,
    String memberId,
  ) async {
    isLoading.value = true;
    try {
      final response = await _api.post("/chat/create-private", {
        "member": memberId,
      }, authReq: true);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // final chatId = body['data']['_id'];
      } else {
        debugPrint("⚠️ Failed: ${body['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error creating private chat: $e");
    } finally {
      isLoading.value = false;
    }
  }


  /// =====================================================
  /// STORIES SECTION
  /// =====================================================
  Future<void> fetchStories({int limit = 20, bool loadMore = false}) async {
    if (isLoadingStories.value || (loadMore && !hasMoreStories.value)) return;

    if (!loadMore) {
      storyPage.value = 1;
      stories.clear();
    }

    isLoadingStories.value = true;

    try {
      final response = await _api.get(
        "/story/all-stories",
        queryParams: {
          "page": storyPage.value.toString(),
          "limit": limit.toString(),
        },
        authReq: true,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["success"] == true) {
          final newStories = body["data"] ?? [];
          if (loadMore) {
            stories.addAll(newStories);
          } else {
            stories.assignAll(newStories);
          }

          final meta = body["meta"] ?? {};
          final totalPage = meta["totalPage"] ?? 1;
          hasMoreStories.value = storyPage.value < totalPage;
          if (hasMoreStories.value) storyPage.value++;
        } else {
          debugPrint("⚠️ Fetch stories failed: ${body["message"]}");
        }
      } else {
        debugPrint("⚠️ Story fetch failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching stories: $e");
    } finally {
      isLoadingStories.value = false;
    }
  }

  /// =====================================================
  /// CHATS SECTION
  /// =====================================================
  Future<void> fetchChats({bool loadMore = false}) async {
    if (isLoadingChats.value || !hasMoreChats.value) return;

    if (!loadMore) {
      chatPage.value = 1;
      privateChats.clear();
      groupChats.clear();
    }

    isLoadingChats.value = true;

    try {
      final response = await _api.get(
        "/chat/private-chat-list",
        queryParams: {"limit": "10", "page": chatPage.value.toString()},
        authReq: true,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body["success"] == true) {
          final List data = body["data"] ?? [];

          final privates = data.where((c) => c['type'] == "private").toList();
          final groups = data.where((c) => c['type'] == "group").toList();

          if (loadMore) {
            privateChats.addAll(privates);
            groupChats.addAll(groups);
          } else {
            privateChats.assignAll(privates);
            groupChats.assignAll(groups);
          }

          final meta = body['meta'] ?? {};
          final totalPage = meta['totalPage'] ?? 1;
          hasMoreChats.value = chatPage.value < totalPage;
          if (hasMoreChats.value) chatPage.value++;
        } else {
          debugPrint("⚠️ Fetch chats failed: ${body["message"]}");
        }
      } else {
        debugPrint("⚠️ Chat fetch failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching chats: $e");
    } finally {
      isLoadingChats.value = false;
    }
  }

  /// Helper - Get last message
  String getLastMessage(Map<String, dynamic> chat) {
    final msg = chat["lastMessage"];
    final sender = msg?["sender"];
    final currentUserId = Get.find<UserController>().userInfo.value!.id;

    if (msg == null) return "";

    // Check if the current user sent the message
    if (sender == currentUserId) {
      switch (msg["contentType"]) {
        case "image":
          return "Photo";
        case "video":
          return "Video"; 
        default:
          return msg["message"] ?? "";
      }
    } else {
      // Current user received a video or photo
      switch (msg["contentType"]) {
        case "image":
          return "Sent a photo";
        case "video":
          return "Sent a video";
        default:
          return msg["message"] ?? "";
      }
    }
  }

  /// =====================================================
  /// REFRESH (Both Chats & Stories)
  /// =====================================================
  Future<void> refreshAll() async {
    chatPage.value = 1;
    storyPage.value = 1;
    hasMoreChats.value = true;
    hasMoreStories.value = true;
    privateChats.clear();
    groupChats.clear();
    stories.clear();

    await Future.wait([fetchChats(), fetchStories()]);
  }

  /// =====================================================
  /// UPLOAD MEDIA (Story)
  /// =====================================================
  Future<void> createStory() async {
    final mediaType = await Get.bottomSheet<String>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Add Image Story'),
              onTap: () => Get.back(result: 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.deepPurple),
              title: const Text('Add Video Story'),
              onTap: () => Get.back(result: 'video'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.redAccent),
              title: const Text('Cancel'),
              onTap: () => Get.back(result: null),
            ),
          ],
        ),
      ),
    );

    if (mediaType == null) return;

    try {
      XFile? pickedFile;
      if (mediaType == 'image') {
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      } else {
        pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      }

      if (pickedFile == null) return;

      final mediaFile = File(pickedFile.path);
      final uploadedUrl = await _uploadStoryMedia(mediaFile, mediaType);

      if (uploadedUrl != null) {
        Get.snackbar(
          "Success",
          "Your $mediaType story uploaded successfully!",
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "Upload Failed",
          "Could not upload your $mediaType story.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: .2),
        );
      }
    } catch (e) {
      debugPrint("❌ Error picking/uploading media: $e");
      Get.snackbar(
        "Error",
        "Something went wrong while uploading story.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: .2),
      );
    }
  }

  /// Upload media file (image/video)
  Future<String?> _uploadStoryMedia(File file, String type) async {
    try {
      final multipartBody = [MultipartBody(key: type, file: file)];
      final response = await _api.postMultipartData(
        "/story/create-story",
        {},
        multipartBody: multipartBody,
        authReq: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        debugPrint("✅ $type uploaded: ${resData['data']['contentType']}");
        return resData['data']['contentType'];
      } else {
        debugPrint("❗ Upload failed: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception during upload: $e");
      return null;
    }
  }

  Future<String> deleteChat(String chatId) async {
    try {
      isLoading.value = true;
      final res = await _api.delete("/chat/delete-chat/$chatId", authReq: true);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return "success";
      } else {
        return body["message"] ?? "Failed to delete chat";
      }
    } catch (e) {
      debugPrint(e.toString());
      return "Unexpected error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }
}
