import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/services/api_service.dart';

class HomeController extends GetxController {
  final ApiService _apiService = ApiService();

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
    if (isLoadingStories.value || !hasMoreStories.value) return null;

    if (!loadMore) {
      storyPage.value = 1; // reset on fresh load
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
          final List newStories = body["data"] ?? [];

          if (loadMore) {
            stories.addAll(newStories);
          } else {
            stories.assignAll(newStories);
          }

          // pagination check
          final meta = body["meta"];
          hasMoreStories.value = storyPage.value < meta["totalPage"];
          if (hasMoreStories.value) storyPage.value++;
        }
        return "success";
      } else {
        debugPrint("⚠️ Fetch stories failed: ${response.body}");
        return "Something went wrong";
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
}
