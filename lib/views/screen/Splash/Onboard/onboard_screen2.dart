import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/utils/statusbar_color.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Auth/login_screen.dart';
import 'dart:io';

class OnboardScreen2 extends StatefulWidget {
  const OnboardScreen2({super.key});

  @override
  State<OnboardScreen2> createState() => _OnboardScreen2State();
}

class _OnboardScreen2State extends State<OnboardScreen2> {
  @override
  void initState() {
    systemStatusBar();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// logo and text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReeLogo(),
                  Text(
                    "2 of 2",
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
              SizedBox(height: 90),

              Center(
                child: Container(
                  height: 114,
                  width: 114,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFECECEC).withValues(alpha: 0.50),
                    image: DecorationImage(
                      image: AssetImage('assets/images/comment2.png'),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 40),
              Center(
                child: Text(
                  "See Real Reactions \nin Real Time",
                  style: TextStyle(
                    color: Color(0xFF413E3E),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "When your media is revealed",
                      style: TextStyle(
                        color: Color(0xFF676565),
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
                      text: " captures genuine reactions instantly",
                      style: TextStyle(
                        color: Color(0xFF676565),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Text("When your media is revealed, re: captures genuine reactions instantly",
              //   style: TextStyle(
              //     color: Color(0xFF676565),
              //     fontSize: 16,
              //     fontWeight: FontWeight.w400,
              //   ),
              //   textAlign: TextAlign.center,),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: CustomButton(
                  onTap: () async {
                    // 🎯 1. Request camera permission
                    final cameraStatus = await Permission.camera.request();

                    // 🎯 2. Handle storage/media permission for all Android versions
                    PermissionStatus mediaStatus;

                    if (Platform.isAndroid) {
                      final androidInfo = await DeviceInfoPlugin().androidInfo;
                      final sdkInt = androidInfo.version.sdkInt;

                      if (sdkInt >= 33) {
                        // Android 13+ → uses READ_MEDIA_IMAGES or READ_MEDIA_VISUAL_USER_SELECTED
                        mediaStatus = await Permission.photos.request();
                      } else {
                        // Android 12 and below → uses storage permission
                        mediaStatus = await Permission.storage.request();
                      }
                    } else {
                      // iOS → use photos permission
                      mediaStatus = await Permission.photos.request();
                    }

                    // 🎯 3. Check if both granted
                    final allGranted =
                        cameraStatus.isGranted && mediaStatus.isGranted;

                    if (allGranted) {
                      // ✅ Navigate to LoginScreen
                      Get.offAll(
                        () => LoginScreen(),
                        transition: Transition.rightToLeft,
                      );
                    } else {
                      // ❌ Show user-friendly message
                      Get.snackbar(
                        "Permission Required",
                        "Camera and Media access are needed to continue.",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.redAccent.withValues(alpha: .8),
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 10,
                        duration: const Duration(seconds: 3),
                      );

                      // ⚙️ Open settings if permanently denied
                      if (cameraStatus.isPermanentlyDenied ||
                          mediaStatus.isPermanentlyDenied) {
                        await openAppSettings();
                      }
                    }
                  },
                  text: "Get Started",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
