import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart'; // Import sms_autofill package
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Auth/reset_password_screen.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/show_snackbar.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String emailOrPhone;
  const OtpVerificationScreen({super.key, required this.emailOrPhone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  final AuthController authController = Get.put(AuthController());
  final controllers = List.generate(6, (_) => TextEditingController());
  final nodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    listenForCode(); // Start listening for OTP code automatically
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final n in nodes) {
      n.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleChange(int i, String v) {
    if (v.length > 1) {
      final chars = v.replaceAll(RegExp(r'\D'), '').split('');
      for (int j = 0; j < chars.length && i + j < controllers.length; j++) {
        controllers[i + j].text = chars[j];
      }
      final next = (i + chars.length).clamp(0, controllers.length - 1);
      nodes[next].requestFocus();
      setState(() {});
      return;
    }

    if (v.isNotEmpty && i < 5) {
      nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      nodes[i - 1].requestFocus();
    }
    setState(() {});
  }

  // This method is called automatically when OTP is received
  @override
  void codeUpdated() async {
    // Fetch the OTP code from SmsAutoFill and autofill OTP in the text fields
    String? code = await SmsAutoFill().getAppSignature;
    for (int i = 0; i < code.length; i++) {
      controllers[i].text = code[i];
    }
    setState(() {});
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReeLogo(),
              const SizedBox(height: 110),
              const Text(
                "Check Your\nMessages",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We've sent a 6-digit code",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => _otpBox(i)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: _secondsRemaining == 0
                        ? () {
                            _startTimer();
                            authController.sendOtp(widget.emailOrPhone);
                          }
                        : null,
                    child: Text(
                      _secondsRemaining == 0
                          ? "Resend code"
                          : "Resend code after",
                      style: const TextStyle(
                        color: Color(0xFF413E3E),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _secondsRemaining == 0 ? "" : "${_secondsRemaining}s",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 92),
              Obx(
                () => CustomButton(
                  loading: authController.isLoading.value,
                  onTap: _verifyCode,
                  text: "Verify and Continue",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyCode() async {
    final code = controllers
        .map((c) => c.text)
        .join(); // OTP from the controllers
    final message = await authController.verifyAccount(
      widget.emailOrPhone,
      code,
    );
    if (message == "success") {
      Get.to(() => const ResetPasswordScreen());
    } else {
      showSnackBar(message, true);
    }
  }

  Widget _otpBox(int i) {
    final filled = controllers[i].text.isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      margin: EdgeInsets.only(right: i == 5 ? 0 : 5),
      decoration: BoxDecoration(
        color: filled ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: filled ? Colors.transparent : const Color(0xFFC4C3C3),
          width: 1.2,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: .35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controllers[i],
        focusNode: nodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : AppColors.textColor,
        ),
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          isCollapsed: true,
          border: InputBorder.none,
          hintText: '*',
          hintStyle: TextStyle(fontSize: 16, color: Color(0xFFB6B6B6)),
          
        ),
        cursorColor: AppColors.primaryColor,
        onChanged: (v) => _handleChange(i, v),
      ),
    );
  }
}
