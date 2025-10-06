import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/services/api_service.dart';

class HomeController extends GetxController {
  var privateChats = <dynamic>[].obs;
  var groupChats = <dynamic>[].obs;
  var isLoading = false.obs;
  var page = 1.obs;
  var hasMore = true.obs;

  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    fetchChats();
  }

  Future<void> fetchChats({bool loadMore = false}) async {
    if (isLoading.value || !hasMore.value) return;

    isLoading.value = true;

    try {
      final response = await _apiService.get(
        "/chat/private-chat-list",
        queryParams: {
          "limit": "10",
          "page": page.value.toString(),
        },
        authReq: true,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;

        // Separate private and group chats
        final privates = data.where((c) => c['type'] == "private").toList();
        final groups = data.where((c) => c['type'] == "group").toList();

        if (loadMore) {
          privateChats.addAll(privates);
          groupChats.addAll(groups);
        } else {
          privateChats.assignAll(privates);
          groupChats.assignAll(groups);
        }

        // Pagination check
        final meta = body['meta'];
        hasMore.value = page.value < meta['totalPage'];
        if (hasMore.value) {
          page.value++;
        }
      } else {
        debugPrint("⚠️ Fetch chats failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching chats: $e");
    } finally {
      isLoading.value = false;
    }
  }

  String getLastMessage(Map<String, dynamic> chat) {
    if (chat["lastMessage"] == null) return "";
    final msg = chat["lastMessage"];
    if (msg["contentType"] == "image") return "📷 Image";
    if (msg["contentType"] == "video") return "🎥 Video";
    return msg["message"] ?? "";
  }
}
