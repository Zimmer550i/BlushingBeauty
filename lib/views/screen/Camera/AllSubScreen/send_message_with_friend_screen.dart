import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_checkbox_screen.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

import '../../../../controllers/send_message_controller.dart';

class SendMessageWithFriendScreen extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const SendMessageWithFriendScreen({
    super.key,
    required this.filePath,
    required this.isVideo,
  });

  @override
  State<SendMessageWithFriendScreen> createState() => _SendMessageWithFriendScreenState();
}

class _SendMessageWithFriendScreenState extends State<SendMessageWithFriendScreen> {
  late final SendMessageController controller;
  late final UserController userController;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SendMessageController());
    userController = Get.put(UserController());
    searchController = TextEditingController();

    searchController.addListener(() {
      controller.searchQuery.value = searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSearchBar(searchController),
                    const SizedBox(height: 24),
                    _buildFriendList(controller, userController),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: "Send Now",
                      onTap: () => controller.sendMedia(
                        filePath: widget.filePath,
                        isVideo: widget.isVideo,
                      ),
                    ),
                  ],
                ),
              ),

              if (controller.chatController.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  // 🧱 Header
  Widget _buildHeader() => Row(
    children: [
      IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back_ios),
      ),
      const SizedBox(width: 8),
      Text(
        "Send Message",
        style: TextStyle(
          color: AppColors.textColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  // 🔍 Search Bar
  Widget _buildSearchBar(TextEditingController searchController) => CustomTextField(
    controller: searchController,
    borderColor: Colors.transparent,
    suffixIcon: Padding(
      padding: const EdgeInsets.all(10.0),
      child: SvgPicture.asset('assets/icons/search.svg'),
    ),
    hintText: 'Search friends...',
  );

  // 👥 Friend List
  Widget _buildFriendList(SendMessageController controller, UserController userController) {
    return Expanded(
      child: Obx(() {
        final filtered = controller.friends.where((friend) {
          final name = (friend['name'] ?? '').toLowerCase();
          return controller.searchQuery.value.isEmpty || name.contains(controller.searchQuery.value);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("No private chat friends found."));
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, index) {
            final friend = filtered[index];
            final imageUrl = userController.addBaseUrl(friend['image']);
            final id = friend['_id'];

            return InkWell(
              onTap: () {
                if (controller.selectedIds.contains(id)) {
                  controller.selectedIds.remove(id);
                } else {
                  controller.selectedIds.add(id);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: imageUrl != null
                        ? NetworkImage(imageUrl)
                        : const AssetImage("assets/images/dummy.jpg") as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      friend['name'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Obx(() => CustomCheckboxScreen(
                    value: controller.selectedIds.contains(id),
                    onChanged: (val) {
                      if (val == true) {
                        controller.selectedIds.add(id);
                      } else {
                        controller.selectedIds.remove(id);
                      }
                    },
                  )),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
