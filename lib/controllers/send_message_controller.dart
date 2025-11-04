import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/helpers/route.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

class SendMessageController extends GetxController {
  final messageController = Get.put(MessageController());
  final chatController = Get.put(ChatController());
  final userController = Get.put(UserController());

  final RxSet<String> selectedIds = <String>{}.obs;
  final RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData() async {
    isLoading.value = true;

    try {
      // await GlobalCameraManager.dispose(); // optional

      if (userController.userInfo.value == null) {
        await userController.getInfo();
      }

      final currentUserId = userController.userInfo.value?.id
          ?.toString()
          .trim();
      if (currentUserId == null || currentUserId.isEmpty) {
        isLoading.value = false;
        return;
      }

      // Fetch chats first

      // Extract immediately
      final newFriends = _extractFriends(
        currentUserId,
        messageController.privateChats,
      );
      friends.assignAll(newFriends);

      // Now watch for live updates
      ever<List>(messageController.privateChats, (updatedChats) {
        final updatedFriends = _extractFriends(currentUserId, updatedChats);
        friends.assignAll(updatedFriends);
      });
    } catch (e) {
      Get.snackbar("Error", "Initialization failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> _extractFriends(
    String currentUserId,
    List<dynamic> chats,
  ) {
    final List<Map<String, dynamic>> chatFriends = [];

    for (var chat in chats) {
      if (chat['type'] == 'private' && chat['members'] != null) {
        for (var member in chat['members']) {
          final memberId = member['_id']?.toString().trim();
          if (memberId != null && memberId != currentUserId) {
            chatFriends.add({
              '_id': memberId,
              'name': member['name'] ?? 'Unknown',
              'image': member['image'],
              'chatId': chat['_id'],
              'hasChat': true,
            });
          }
        }
      }
    }

    final uniqueFriends = {
      for (var f in chatFriends) f['_id']: f,
    }.values.toList();
    return uniqueFriends;
  }

  Future<void> sendMedia({
    required String filePath,
    required bool isVideo,
  }) async {
    isLoading.value = true;
    if (selectedIds.isEmpty) {
      Get.snackbar("Error", "Please select at least one friend.");
      return;
    }

    try {
      // ✅ Ensure .mp4 extension or rename .temp file properly
      final correctedPath = isVideo ? await ensureMp4File(filePath) : filePath;

      final file = File(correctedPath);
      if (!await file.exists()) {
        throw Exception("File not found at path: $correctedPath");
      }
      await chatController.sendMediaToMultipleChats(
        friends: friends,
        selectedIds: selectedIds,
        mediaFile: file,
        contentType: isVideo ? 'video' : 'image',
      );

      // Get.snackbar(
      //   "Success",
      //   "Media sent to ${selectedIds.length} friend${selectedIds.length > 1 ? 's' : ''}!",
      // );
      Get.offAllNamed(AppRoutes.messageScreen);
    } catch (e) {
      Get.snackbar("Error", "Failed to send media: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMediaToSingleChat({
    required String chatId,
    required String filePath,
    required bool isVideo,
  }) async {
    try {
      isLoading.value = true;
      // ✅ Fix temp extension or ensure valid .mp4 file
      final correctedPath = isVideo ? await ensureMp4File(filePath) : filePath;

      final file = File(correctedPath);
      if (!await file.exists()) {
        throw Exception("File not found at path: $correctedPath");
      }

      // ✅ Send media to single user chat
      await chatController.sendVideoToSingleChat(
        chatId: chatId,
        mediaFile: file,
        contentType: isVideo ? 'video' : 'image',
      );
      Get.offAllNamed(AppRoutes.messageScreen);
      // Get.back(); // Close current screen after sending
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send ${isVideo ? 'video' : 'image'}: $e",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> ensureMp4File(String filePath) async {
    try {
      final file = File(filePath);

      // If file doesn’t exist, throw an error early
      if (!await file.exists()) {
        throw Exception("File not found at $filePath");
      }

      // If already ends with .mp4 and not .temp, just return
      if (filePath.toLowerCase().endsWith('.mp4') &&
          !filePath.toLowerCase().contains('.temp')) {
        return filePath;
      }

      // Otherwise, create a new .mp4 file in the same directory
      final newPath = p.join(
        p.dirname(filePath),
        '${p.basenameWithoutExtension(filePath)}.mp4',
      );

      // Rename (move) or copy the file
      final newFile = await file.rename(newPath);

      return newFile.path;
    } catch (e) {
      debugPrint('❗ Error converting file to .mp4: $e');
      rethrow;
    }
  }
}
