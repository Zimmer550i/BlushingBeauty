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
                    // 🎯 Request Camera Permission
                    final cameraStatus = await Permission.camera.request();
                    debugPrint('Camera permission status: $cameraStatus');

                    // 🎯 Request Microphone Permission
                    final micStatus = await Permission.microphone.request();
                    debugPrint('Microphone permission status: $micStatus');

                    // 🎯 Request Photo Library Permission (full access)
                    PermissionStatus photoStatus;
                    if (Platform.isIOS) {
                      photoStatus = await Permission.photos.request();
                      debugPrint(
                        'iOS Photo Library permission status: $photoStatus',
                      );
                      if (photoStatus == PermissionStatus.limited) {
                        // Request full photo library access if limited
                        photoStatus = await Permission.photos.request();
                        debugPrint(
                          'iOS Photo Library full access request status: $photoStatus',
                        );
                      }
                    } else if (Platform.isAndroid) {
                      final androidInfo = await DeviceInfoPlugin().androidInfo;
                      final sdkInt = androidInfo.version.sdkInt;
                      if (sdkInt >= 33) {
                        photoStatus = await Permission.photos.request();
                        debugPrint(
                          'Android 13+ Photo permission status: $photoStatus',
                        );
                      } else {
                        photoStatus = await Permission.storage.request();
                        debugPrint(
                          'Android <=12 Storage permission status: $photoStatus',
                        );
                      }
                    } else {
                      photoStatus = PermissionStatus.denied;
                      debugPrint('Unsupported platform for photo permission');
                    }

                    // 🎯 Request Contacts Permission
                    PermissionStatus contactStatus;
                    if (Platform.isIOS || Platform.isAndroid) {
                      contactStatus = await Permission.contacts.request();
                      debugPrint('Contacts permission status: $contactStatus');
                    } else {
                      contactStatus = PermissionStatus.denied;
                      debugPrint('Unsupported platform for contacts permission');
                    }

                    // 🎯 Check if all permissions granted
                    final allGranted =
                        cameraStatus.isGranted &&
                        micStatus.isGranted &&
                        photoStatus.isGranted &&
                        contactStatus.isGranted;

                    if (allGranted && Platform.isAndroid) {
                      Get.offAll(
                        () => LoginScreen(),
                        transition: Transition.rightToLeft,
                      );
                    } else if (Platform.isIOS) {
                      Get.offAll(
                        () => LoginScreen(),
                        transition: Transition.rightToLeft,
                      );
                    } else {
                      Get.snackbar(
                        "Permission Required",
                        "Camera, Microphone, Photo Library, and Contacts access are needed to continue.",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.redAccent.withValues(alpha: .8),
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 10,
                        duration: const Duration(seconds: 3),
                      );

                      // ⚙️ Open settings if permanently denied
                      if (cameraStatus.isPermanentlyDenied ||
                          micStatus.isPermanentlyDenied ||
                          photoStatus.isPermanentlyDenied ||
                          contactStatus.isPermanentlyDenied) {
                        debugPrint(
                          'One or more permissions permanently denied, opening app settings.',
                        );
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
