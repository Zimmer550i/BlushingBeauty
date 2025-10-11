import 'dart:io';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/services/camera_manager.dart';

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

      final currentUserId = userController.userInfo.value?.id?.toString().trim();
      if (currentUserId == null || currentUserId.isEmpty) {
        isLoading.value = false;
        return;
      }

      // Fetch chats first
      await messageController.fetchChats();

      // Extract immediately
      final newFriends = _extractFriends(currentUserId, messageController.privateChats);
      friends.assignAll(newFriends);

      // Now watch for live updates
      ever<List>(
        messageController.privateChats,
            (updatedChats) {
          final updatedFriends = _extractFriends(currentUserId, updatedChats);
          friends.assignAll(updatedFriends);
        },
      );

    } catch (e) {
      Get.snackbar("Error", "Initialization failed: $e");
    } finally {
      isLoading.value = false;
    }
  }


  List<Map<String, dynamic>> _extractFriends(String currentUserId, List<dynamic> chats) {
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

    final uniqueFriends = {for (var f in chatFriends) f['_id']: f}.values.toList();
    return uniqueFriends;
  }

  Future<void> sendMedia({
    required String filePath,
    required bool isVideo,
  }) async {
    if (selectedIds.isEmpty) {
      Get.snackbar("Error", "Please select at least one friend.");
      return;
    }

    try {
      await chatController.sendMediaToMultipleChats(
        friends: friends,
        selectedIds: selectedIds,
        mediaFile: File(filePath),
        contentType: isVideo ? 'video' : 'image',
      );

      Get.snackbar("Success", "Media sent to ${selectedIds.length} friend${selectedIds.length > 1 ? 's' : ''}!");
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "Failed to send media: $e");
    }
  }
}

