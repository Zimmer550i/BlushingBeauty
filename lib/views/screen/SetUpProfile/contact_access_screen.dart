import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/SetUpProfile/invite_friend_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'enable_notification_screen.dart';

class ContactAccessScreen extends StatefulWidget {
  const ContactAccessScreen({super.key});

  @override
  State<ContactAccessScreen> createState() => _ContactAccessScreenState();
}

class _ContactAccessScreenState extends State<ContactAccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 36,
                    width: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "re:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "1 of 4",
                    style: TextStyle(
                      color: Color(0xFF413E3E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 110),
              Text(
                "Access Your \nContacts",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),

              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "We'll use your contacts to invite friends to",
                      style: TextStyle(
                        color: Color(0xFF413E3E),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: " re:",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text:
                          " and show you who is already on the app. Your info stays private",
                      style: TextStyle(
                        color: Color(0xFF413E3E),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 80),

              InkWell(
                onTap: (){
                  Get.to(()=> EnableNotificationScreen());
                },
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFC4C3C3), width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      "Not Now",
                      style: TextStyle(
                        color: Color(0xFF676565),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              CustomButton(
                onTap: () async {
                  // Request permission
                  var status = await Permission.contacts.request();

                  if (status.isGranted) {
                    // Permission granted ✅
                    final contacts = await FlutterContacts.getContacts();
                    print("Total contacts: ${contacts.length}");

                    Get.to(() => InviteFriendScreen());
                  } else if (status.isDenied) {
                    // Show a snackbar or alert
                    Get.snackbar("Permission Denied", "You need to allow access to continue");
                  } else if (status.isPermanentlyDenied) {
                    // Open settings
                    openAppSettings();
                  }
                },
                text: "Allow Access",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
