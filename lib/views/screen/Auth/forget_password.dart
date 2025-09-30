import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Auth/otp_verification_screen.dart';

import '../../../controllers/auth_controller.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final AuthController authController = Get.put(AuthController());
  final emailTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(height: 110),
              Text(
                "Let’s get you \n back in",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 40),
              CustomTextField(
                controller: emailTextController,
                hintText: 'Enter your phone number or email',
                borderSide: BorderSide(color: Color(0xFFC4C3C3), width: 1),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SvgPicture.asset('assets/icons/mobile.svg'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 80),
              Obx(()=> CustomButton(
                loading: authController.isLoading.value,
                onTap: () async {
                  final message = await authController.forgotPassword(
                    emailTextController.text,
                  );
                  if (message == "success") {
                    Get.snackbar("Success", "Check your email");
                    Get.offAll(
                          () => OtpVerificationScreen(
                        emailOrPhone: emailTextController.text,
                      ),
                    );
                  } else {
                    Get.snackbar("Error", message);
                  }
                },
                text: "Send Code",
              ),),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Back to",
                    style: TextStyle(
                      color: Color(0xFF676565),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 5),
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Text(
                      "Log In",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
