import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../views/screen/Message/AllSubScreen/chat_screen.dart';

class ChatController extends GetxController {
  final api = ApiService();
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isPaginating = false.obs;

  int _currentPage = 1;
  final int _limit = 10;
  bool _hasMore = true;

  /// Reset pagination
  void resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    messages.clear();
  }

  /// Fetch first page (used in initState)
  Future<void> fetchMessages(String chatId) async {
    resetPagination();
    await _fetchPage(chatId);
  }

  /// Load next page (when user scrolls up)
  Future<void> loadMore(String chatId) async {
    if (!_hasMore || isPaginating.value) return;
    await _fetchPage(chatId);
  }

  Future<void> _fetchPage(String chatId) async {
    try {
      if (_currentPage == 1) {
        isLoading.value = true;
      } else {
        isPaginating.value = true;
      }

      final res = await api.get(
        "/chat/chat-inbox/$chatId?limit=$_limit&page=$_currentPage",
        authReq: true,
      );
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final List newMessages = body['data'];

        if (newMessages.isEmpty) {
          _hasMore = false; // no more pages
        } else {
          // prepend older messages (so order is maintained)
          messages.insertAll(0, List<Map<String, dynamic>>.from(newMessages));
          _currentPage++;
        }

        debugPrint("📩 Page $_currentPage loaded, total: ${messages.length}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching messages: $e");
    } finally {
      isLoading.value = false;
      isPaginating.value = false;
    }
  }

  /// Create a private chat and navigate
  Future<void> createPrivateChat(String memberId) async {
    isLoading.value = true;
    try {
      final response = await api.post(
        "/chat/create-private",
        {"member": memberId},
        authReq: true,
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatData = body['data'];
        final chatId = chatData['_id'];
        final createdBy = chatData['createdBy'];

        debugPrint("✅ Private chat created: $chatId");

        /// open ChatScreen with chatId
        Get.to(() => ChatScreen(chatId: chatId, receiverName: '', currentUserId: createdBy,));

      } else {
        debugPrint("⚠️ Failed: ${body['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error creating private chat: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
