import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/auth_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_email_number_field.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Auth/email_verify_screen.dart';
import '../../../utils/show_snackbar.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthController authController = Get.put(AuthController());
  bool isCheck = false;
  final phoneTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReeLogo(),
              SizedBox(height: 110),
              Text(
                "Sign Up in \nSeconds",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Create an account to capture and share real reactions",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40),
              CustomEmailNumberField(
                controller: phoneTextController,
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
                      child: SvgPicture.asset('assets/icons/phone.svg'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              CustomTextField(
                controller: passwordTextController,
                hintText: 'Enter your Password',
                borderSide: BorderSide(color: Color(0xFFC4C3C3), width: 1),
                isPassword: true,
                validator: (_) {
                  return authController.validatePassword()
                      ? null
                      : authController.passwordError.value;
                },
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
                      child: SvgPicture.asset('assets/icons/lock.svg'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    activeColor: AppColors.primaryColor,
                    value: isCheck,
                    onChanged: (val) {
                      setState(() {
                        isCheck = val!;
                      });
                    },
                  ),

                  RichText(
                    text: TextSpan(
                      text: "You agree to the",
                      style: TextStyle(
                        color: Color(0xFF676565),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: "Terms of Service",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: " and\n acknowledge you have read the ",
                          style: TextStyle(
                            color: Color(0xFF676565),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: "Privacy \nPolicy",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 80),
              Obx(
                () => CustomButton(
                  onTap: () async {
                    final String phone = phoneTextController.text.trim();
                    final String password = passwordTextController.text.trim();
                    if (phone.isEmpty || password.isEmpty) {
                      showSnackBar('Please fill all the fields', true);
                    } else {
                      if (isCheck) {
                        if(phoneTextController.text.contains('@')) {
                          final message = await authController.signup(
                          phone,
                          password,
                          false
                        );
                          if (message == "success") {
                            Get.to(() => EmailVerifyScreen(emailOrPhone: phone));
                          } else {
                            showSnackBar("Please enter a valid phone number", true);
                          }
                          return;
                        }else{
                          final message = await authController.signup(
                          phone,
                          password,
                          true
                        );
                          if (message == "success") {
                            Get.to(() => EmailVerifyScreen(emailOrPhone: phone));
                          } else {
                            showSnackBar(message, true);
                          }
                          return;
                        }
                      } else {
                        showSnackBar(
                          'Please agree to the terms and conditions',
                          true,
                        );
                      }
                    }
                  },
                  text: "Agree and Continue",
                  loading: authController.isLoading.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
