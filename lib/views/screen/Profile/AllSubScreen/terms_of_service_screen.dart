import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Icon(Icons.arrow_back, color: Color(0xFF0D1C12))),
                  SizedBox(width: 15),
                  Text(
                    "Terms of Service",
                    style: TextStyle(
                      color: Color(0xFF0D1C12),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32,),
            Expanded(child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
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
                  SizedBox(height: 16,),
                  Text("This Privacy Policy explains how re: (“we,” “our,” or “us”) collects, uses, and protects your information when you use our mobile application and services.  1. Information We Collect - Account Data: Name, email, phone number (for sign-up and invites). - Media: Photos/videos sent by users, and reactions (photo/video) captured on receipt. - Usage Data: Device type, app interactions, crash logs, and analytics.  2. How We Use Information - To deliver app functionality (sending media + capturing reactions). - To provide secure storage and pairing of media and reactions. - To improve the app experience and troubleshoot issues.  3. Sharing and Disclosure - Private by default: Media and reactions are only visible to sender and recipient. - Opt-in Sharing: Users control what content is shared beyond private interactions. - Third-Party Services: Hosting, APIs (e.g., storage, video processing, notifications). These vendors are contractually bound to protect your data.  4. Data Retention - Media and reactions are stored until expired after 48 hours. - Declined reactions are auto-deleted. - Accounts can request full deletion.  5. Your Rights - Access, update, or delete account information. - Withdraw consent at any time.  6. Security We use encryption, access controls, and secure hosting to protect your information.  7. Contact If you have questions, contact us at: re.socialize.app@gmail.com Attn: re: Support",
                    style: TextStyle(
                      color: Color(0xFF696767),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),)
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}
