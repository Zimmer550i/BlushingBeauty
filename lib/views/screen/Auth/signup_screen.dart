import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
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
  CountryCode selectedCountryCode = CountryCode.fromDialCode('+1'); // ✅ Added

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ReeLogo(),
              const SizedBox(height: 110),
              Text(
                "Sign Up in \nSeconds",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Create an account to capture and share real reactions",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),

              // ✅ Phone number with country code
              CustomNumberField(
                controller: phoneTextController,
                hintText: 'Enter your phone number',
                borderSide: const BorderSide(
                  color: Color(0xFFC4C3C3),
                  width: 1,
                ),
                onCountryCodeChanged: (code) {
                  setState(() => selectedCountryCode = code);
                },
              ),

              const SizedBox(height: 12),
              CustomTextField(
                controller: passwordTextController,
                hintText: 'Enter your Password',
                borderSide: const BorderSide(
                  color: Color(0xFFC4C3C3),
                  width: 1,
                ),
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

              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    activeColor: AppColors.primaryColor,
                    value: isCheck,
                    onChanged: (val) => setState(() => isCheck = val!),
                  ),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: "You agree to the ",
                        style: const TextStyle(
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
                          const TextSpan(
                            text: " and acknowledge you have read the ",
                            style: TextStyle(
                              color: Color(0xFF676565),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: "Privacy\nPolicy",
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),
              Obx(
                () => CustomButton(
                  onTap: () async {
                    final String rawPhone = phoneTextController.text.trim();
                    final String password = passwordTextController.text.trim();

                    if (rawPhone.isEmpty || password.isEmpty) {
                      showSnackBar('Please fill all the fields', true);
                      return;
                    }

                    if (!isCheck) {
                      showSnackBar(
                        'Please agree to the terms and conditions',
                        true,
                      );
                      return;
                    }

                    // ✅ Combine country code and phone number
                    final String fullPhone =
                        '${selectedCountryCode.dialCode}${rawPhone.replaceAll(RegExp(r'[^0-9]'), '')}';
                    debugPrint('📞 Full Phone: $fullPhone');

                    final message = await authController.signup(
                      fullPhone,
                      password,
                      true,
                    );

                    if (message == "success") {
                      Get.to(() => EmailVerifyScreen(emailOrPhone: fullPhone));
                    } else {
                      showSnackBar(message, true);
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
