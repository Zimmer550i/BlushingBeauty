import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/home_controller.dart';
import 'package:ree_social_media_app/services/api_service.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

import '../../base/bottom_menu..dart';
import '../Notification/notification_screen.dart';
import 'AllSubScreen/AllSubScreen/search_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final HomeController controller = Get.put(HomeController());
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _storyScrollController = ScrollController();

  bool _isFetchingMoreChats = false;
  bool _isFetchingMoreStories = false;

  @override
  void initState() {
    super.initState();

    /// Pagination listener for chats
    _chatScrollController.addListener(() {
      if (_chatScrollController.position.pixels >=
              _chatScrollController.position.maxScrollExtent - 200 &&
          !_isFetchingMoreChats &&
          controller.hasMoreChats.value) {
        _loadMoreChats();
      }
    });

    /// Pagination listener for stories
    _storyScrollController.addListener(() {
      if (_storyScrollController.position.pixels >=
              _storyScrollController.position.maxScrollExtent - 100 &&
          !_isFetchingMoreStories &&
          controller.hasMoreStories.value) {
        _loadMoreStories();
      }
    });
  }

  Future<void> _loadMoreChats() async {
    setState(() => _isFetchingMoreChats = true);
    await controller.fetchChats(loadMore: true);
    setState(() => _isFetchingMoreChats = false);
  }

  Future<void> _loadMoreStories() async {
    setState(() => _isFetchingMoreStories = true);
    await controller.getAllStories(loadMore: true);
    setState(() => _isFetchingMoreStories = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomMenu(0, messageCount: 1),
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildTopBar(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: _chatScrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStoriesSection(),
                      const SizedBox(height: 24),
                      _buildChatList(),
                      if (_isFetchingMoreChats)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ============================
  /// 🔹 Top Bar
  /// ============================
  Widget _buildTopBar() {
    return Row(
      children: [
        _logoBox(),
        const Spacer(),
        _iconButton('assets/icons/add.svg'),
        const SizedBox(width: 12),
        _iconButton(
          'assets/icons/search.svg',
          onTap: () => Get.to(() => const SearchScreen()),
        ),
        const SizedBox(width: 12),
        _notificationButton(),
      ],
    );
  }

  Widget _notificationButton() {
    return Stack(
      children: [
        _iconButton(
          'assets/icons/notification.svg',
          onTap: () => Get.to(() => const NotificationScreen()),
        ),
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

  /// ============================
  /// 🔹 Stories Section
  /// ============================
  Widget _buildStoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            // navigate to SeeAllStoryScreen
          },
          child: Align(
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
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: Obx(() {
            if (controller.isLoadingStories.value &&
                controller.stories.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              controller: _storyScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: controller.stories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildAddStoryCard();

                if (index > controller.stories.length) {
                  return _isFetchingMoreStories
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox();
                }

                var story = controller.stories[index - 1];
                final isVideo = story["contentType"] == "video";
                final mediaUrl = (story["image"] as String).isNotEmpty
                    ? "${ApiService().devUrl}${story["image"]}"
                    : "${ApiService().devUrl}${story["video"]}";

                return _buildStoryCard(
                  mediaUrl,
                  story["author"]?["name"] ?? "User",
                  isVideo,
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAddStoryCard() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade300,
      ),
      child: const Center(
        child: Icon(Icons.add, size: 30, color: Colors.black),
      ),
    );
  }

  Widget _buildStoryCard(String url, String name, bool isVideo) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          if (isVideo)
            Center(
              child: Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              color: Colors.black54,
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ============================
  /// 🔹 Chats Section
  /// ============================
  Widget _buildChatList() {
    return Obx(() {
      if (controller.isLoadingChats.value &&
          controller.privateChats.isEmpty &&
          controller.groupChats.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final allChats = [...controller.privateChats, ...controller.groupChats];

      if (allChats.isEmpty) {
        return const Center(child: Text("No chats found"));
      }

      return Column(
        children: allChats.map((chat) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: Text(chat["name"]?[0] ?? "?"),
            ),
            title: Text(chat["name"] ?? "Unknown"),
            subtitle: Text(controller.getLastMessage(chat)),
            onTap: () {
              // Navigate to chat detail screen
            },
          );
        }).toList(),
      );
    });
  }
}
