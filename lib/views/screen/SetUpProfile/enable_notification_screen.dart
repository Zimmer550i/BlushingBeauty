import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/SetUpProfile/setup_profile_screen.dart';

class EnableNotificationScreen extends StatefulWidget {
  const EnableNotificationScreen({super.key});

  @override
  State<EnableNotificationScreen> createState() => _EnableNotificationScreenState();
}

class _EnableNotificationScreenState extends State<EnableNotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
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
                  ),
                  Text(
                    "3 of 4",
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
              SizedBox(height: 110,),
              
              Text("Enable Push Notifications",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),),
              SizedBox(height: 12,),
              Text("Allow notifications to see friend's messages and respond in real time",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),),
              SizedBox(height: 80,),
              InkWell(
                onTap: (){
                  Get.to(()=> SetupProfileScreen());
                },
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFC4C3C3), width: 0.5)
                  ),
                  child: Center(
                    child: Text("Not Now",
                    style: TextStyle(
                      color: Color(0xFF676565),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),),
                  ),
                ),
              ),
              SizedBox(height: 24,),
              CustomButton(onTap: (){
                Get.to(()=> SetupProfileScreen());
              },
                  text: "Enable Notifications")
            ],
          ),
        ),
      ),
    );
  }
}
