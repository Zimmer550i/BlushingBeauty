import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ree_social_media_app/services/api_service.dart';

import '../models/multi_body.dart';
import '../services/socket_manager.dart';

class HomeController extends GetxController {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  ///Private & Group Chats
  var privateChats = <dynamic>[].obs;
  var groupChats = <dynamic>[].obs;
  var isLoadingChats = false.obs;
  var chatPage = 1.obs;
  var hasMoreChats = true.obs;

  /// Stories
  var stories = <dynamic>[].obs;
  var isLoadingStories = false.obs;
  var storyPage = 1.obs;
  var hasMoreStories = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChats();
    getAllStories();
  }

  ///Fetch Stories (with pagination)
  Future<String?> getAllStories({int limit = 20, bool loadMore = false}) async {
    // stop if already loading or no more stories when loading more
    if (isLoadingStories.value || (loadMore && !hasMoreStories.value)) {
      return null;
    }

    if (!loadMore) {
      storyPage.value = 1;
      stories.clear();
    }

    isLoadingStories.value = true;

    try {
      final response = await _apiService.get(
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
          final List<dynamic> newStories = body["data"] ?? [];

          if (newStories.isNotEmpty) {
            if (loadMore) {
              stories.addAll(newStories);
            } else {
              stories.assignAll(newStories);
            }
          }

          // ✅ Pagination check (with null safety)
          final meta = body["meta"] ?? {};
          final totalPage = meta["totalPage"] ?? 1;
          final currentPage = storyPage.value;

          hasMoreStories.value = currentPage < totalPage;
          if (hasMoreStories.value) storyPage.value++;

          return "success";
        } else {
          return body["message"] ?? "Failed to fetch stories";
        }
      } else {
        debugPrint("⚠️ Fetch stories failed: ${response.body}");
        return "Something went wrong (${response.statusCode})";
      }
    } catch (e) {
      debugPrint("❌ Error fetching stories: $e");
      return "Failed to fetch stories";
    } finally {
      isLoadingStories.value = false;
    }
  }

  ///Fetch Chats (with pagination)
  Future<void> fetchChats({bool loadMore = false}) async {
    if (isLoadingChats.value || !hasMoreChats.value) return;

    isLoadingChats.value = true;

    try {
      final response = await _apiService.get(
        "/chat/private-chat-list",
        queryParams: {
          "limit": "10",
          "page": chatPage.value.toString(),
        },
        authReq: true,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body["success"] == true) {
          final data = body["data"] as List;

          final privates = data.where((c) => c['type'] == "private").toList();
          final groups = data.where((c) => c['type'] == "group").toList();

          if (loadMore) {
            privateChats.addAll(privates);
            groupChats.addAll(groups);
          } else {
            privateChats.assignAll(privates);
            groupChats.assignAll(groups);
          }

          // pagination check
          final meta = body['meta'];
          hasMoreChats.value = chatPage.value < meta['totalPage'];
          if (hasMoreChats.value) {
            chatPage.value++;
          }
        }
      } else {
        debugPrint("⚠️ Fetch chats failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching chats: $e");
    } finally {
      isLoadingChats.value = false;
    }
  }

  /// Helper: Last Message
  String getLastMessage(Map<String, dynamic> chat) {
    if (chat["lastMessage"] == null) return "";
    final msg = chat["lastMessage"];
    if (msg["contentType"] == "image") return "📷 Image";
    if (msg["contentType"] == "video") return "🎥 Video";
    return msg["message"] ?? "";
  }

  ///Refresh All Data
  Future<void> refreshAll() async {
    chatPage.value = 1;
    hasMoreChats.value = true;
    privateChats.clear();
    groupChats.clear();

    storyPage.value = 1;
    hasMoreStories.value = true;
    stories.clear();

    await Future.wait([
      fetchChats(),
      getAllStories(),
    ]);
  }

  /// Upload media file to API and return URL
  Future<String?> uploadMedia(File file, {String type = "image"}) async {
    final multipartBody = [MultipartBody(key: type, file: file)];

    final response = await _apiService.postMultipartData(
      "/story/create-story",
      {},
      multipartBody: multipartBody,
      authReq: true,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final resData = jsonDecode(response.body);

      return resData['content'];
    } else {
      debugPrint("❗ Upload failed: ${response.body}");
      return null;
    }
  }


  /// Pick and send image
  Future<void> createStory() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await uploadMedia(File(file.path), type: "image");
  }

  /// Pick and send video
  Future<void> pickAndSendVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await uploadMedia(File(file.path), type: "video");
  }

}
