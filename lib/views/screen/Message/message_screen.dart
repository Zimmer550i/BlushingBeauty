import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/home_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/bottom_menu..dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/search_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/chat_screen.dart';
import 'package:ree_social_media_app/views/screen/Notification/notification_screen.dart';

import 'AllSubScreen/AllSubScreen/see_all_story_screen.dart';

class MessageScreen extends StatelessWidget {
  MessageScreen({super.key});

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomMenu(0, messageCount: 1),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildTopBar(),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeeAll(),
                    const SizedBox(height: 12),
                    _buildChatList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Top Bar
  Widget _buildTopBar() {
    return Row(
      children: [
        _logoBox(),
        const Spacer(),
        _iconButton('assets/icons/add.svg'),
        const SizedBox(width: 12),
        _iconButton('assets/icons/search.svg', onTap: () => Get.to(() => const SearchScreen())),
        const SizedBox(width: 12),
        _notificationButton(),
      ],
    );
  }

  /// ✅ "See All" link
  Widget _buildSeeAll() {
    return InkWell(
      onTap: () => Get.to(() => SeeAllStoryScreen()),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Text(
          "See All",
          style: TextStyle(
            color: Color(0xFF413E3E),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// ✅ Chats list with Refresh + Obx
  Widget _buildChatList() {
    return RefreshIndicator(
      onRefresh: () async {
        controller.page.value = 1;
        await controller.fetchChats();
      },
      child: Obx(() {
        if (controller.isLoading.value &&
            controller.privateChats.isEmpty &&
            controller.groupChats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const Text(
              "Chats",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildChatSection(controller.groupChats),
            const SizedBox(height: 24),
            _buildChatSection(controller.privateChats),
          ],
        );
      }),
    );
  }

  /// ✅ Chat Section
  Widget _buildChatSection(List chats) {
    if (chats.isEmpty) return const SizedBox();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final chat = chats[index];
        final name = chat["name"] ?? "Unknown";
        final image = chat["image"] ?? "";
        final lastMessage = controller.getLastMessage(chat);
        final time = chat["lastMessage"]?["createdAt"] ?? "";

        return InkWell(
          onTap: () {
            Get.to(() => ChatScreen(
              chatId: chat["_id"],
              receiverName: name,
              currentUserId: "CURRENT_USER_ID",
              receiverImage: image,
            ));
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryColor,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty
                    ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF676565),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF676565),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTime(time),
                style: const TextStyle(
                  color: Color(0xFF807E7E),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Safe time formatter
  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return "";
    final timeStr = createdAt.toString();

    try {
      final dateTime = DateTime.tryParse(timeStr);
      if (dateTime != null) {
        return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      }
      if (timeStr.length >= 16) {
        return timeStr.substring(11, 16);
      }
    } catch (_) {
      return "";
    }
    return "";
  }

  /// 🔹 Reusable widgets
  Widget _logoBox() {
    return Container(
      height: 36,
      width: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          "re:",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _iconButton(String asset, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC4C3C3), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: SvgPicture.asset(asset),
        ),
      ),
    );
  }

  Widget _notificationButton() {
    return Stack(
      children: [
        _iconButton('assets/icons/notification.svg',
            onTap: () => Get.to(() => const NotificationScreen())),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Text(
                "1",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
