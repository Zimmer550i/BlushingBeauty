import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/story_details_screen.dart';
import 'package:ree_social_media_app/controllers/home_controller.dart';

class SeeAllStoryScreen extends StatelessWidget {
  SeeAllStoryScreen({super.key});
  final UserController userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: Icon(Icons.arrow_back, color: AppColors.textColor),
                ),
                const SizedBox(width: 12),
                Text(
                  "All Stories",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// ✅ Stories grid from controller
            Expanded(
              child: Obx(() {
                if (homeController.isLoadingStories.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (homeController.stories.isEmpty) {
                  return const Center(
                    child: Text("No stories available"),
                  );
                }

                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: homeController.stories.length,
                  itemBuilder: (context, index) {
                    var story = homeController.stories[index];

                    final type = story["contentType"];
                    final name = story["author"]?["name"] ?? "Unknown";

                    // pick image or video url
                    String? mediaUrl;
                    if (type == "image" && (story["image"] ?? "").isNotEmpty) {
                      mediaUrl = userController.addBaseUrl(story["image"]);
                    } else if (type == "video" && (story["video"] ?? "").isNotEmpty) {
                      mediaUrl = userController.addBaseUrl(story["video"]);
                    }

                    return _buildStoryCard(
                      mediaUrl,
                      name,
                      type == "video",
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(String? mediaUrl, String name, bool isVideo) {
    return InkWell(
      onTap: () => Get.to(() => const StoryDetailsScreen()),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 100,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          image: DecorationImage(
            image: (mediaUrl != null && mediaUrl.isNotEmpty)
                ? NetworkImage(mediaUrl)
                : const AssetImage("assets/images/dummy.jpg") as ImageProvider,
            fit: BoxFit.cover,
          ),
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
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 16),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                color: Colors.black.withValues(alpha: 0.42),
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
      ),
    );
  }
}
