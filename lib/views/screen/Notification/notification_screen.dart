import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/show_snackbar.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/user_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController controller = Get.put(NotificationController());
  final UserController userController = Get.put(UserController());

  @override
  void initState() {
    super.initState();
    controller.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            SizedBox(height: 24),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Icon(Icons.arrow_back, color: AppColors.textColor),
                ),
                SizedBox(width: 12),
                Text(
                  "Notifications",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFC4C3C3), width: 0.5),
                    ),
                    child: Icon(Icons.close),
                  ),
                ),
                SizedBox(width: 12),
              ],
            ),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: SpinKitWave(color: AppColors.primaryColor, size: 30.0));
                }

                if (controller.notifications.isEmpty) {
                  return const Center(child: Text("No notifications found"));
                }

                return ListView.separated(
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemCount: controller.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = controller.notifications[index];
                    final image = userController.addBaseUrl(
                      notif.senderImage.toString(),
                    );

                    return Dismissible(
                      key: ValueKey(notif.id),
                      // unique ID
                      direction: DismissDirection.endToStart,
                      // swipe left
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: Text("Remove",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: Colors.white),),
                      ),
                      onDismissed: (direction) async {
                        controller.notifications.removeAt(index);
                        final message = await controller.deleteNotification(notif.id);

                        if (message == "success") {
                      
                          return;
                        }else{
                          showSnackBar("ERROR $message", true);

                        }

                      },
                      child: notificationCard(
                        name: notif.senderName ?? "Unknown",
                        image: image,
                        content: notif.content,
                        time:
                            "${notif.createdAt.hour}:${notif.createdAt.minute.toString().padLeft(2, '0')}",
                      ),
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

  Container notificationCard({
    required String name,
    String? image,
    required String content,
    required String time,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF56BBFF).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: image != null && image.isNotEmpty
                    ? NetworkImage(image)
                    : const AssetImage("assets/images/dummy.jpg")
                          as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Text (name + content)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Time
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF807E7E),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
