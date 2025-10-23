import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/change_password_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/edit_profile_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/report_problem_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/all_data_page.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/user_controller.dart';
import '../../base/bottom_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController authController = Get.put(AuthController());
  final UserController userController = Get.put(UserController());

  bool isSwitch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Profile Card
              Obx(() {
                final imageUrl = userController.getImageUrl();
                final userName =
                    userController.userInfo.value?.name ?? "Loading...";
                final userPhone = userController.userInfo.value?.phone ?? "N/A";
                final userDob =
                    userController.userInfo.value?.dob ?? DateTime.now();
                return Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF56BBFF), Color(0xFFFFFFFF)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          "re:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      /// Avatar + Logo Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                (imageUrl != null && imageUrl.isNotEmpty)
                                ? NetworkImage(imageUrl)
                                : const AssetImage("assets/images/demo1.png")
                                      as ImageProvider,
                          ),

                          // ReeLogo(),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// User Info
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userPhone,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 40),

              /// Push Notifications
              // Row(
              //   children: [
              //     SvgPicture.asset('assets/icons/notification_fill.svg'),
              //     const SizedBox(width: 13),
              //     const Text(
              //       "Push Notifications",
              //       style: TextStyle(
              //         color: Color(0xFF676565),
              //         fontSize: 16,
              //         fontWeight: FontWeight.w400,
              //       ),
              //     ),
              //     const Spacer(),
              //     CustomSwitch(
              //       value: isSwitch,
              //       onChanged: (val) => setState(() => isSwitch = val),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 18),

              /// Settings List
              _customRow(
                onTap: () => Get.to(() => const EditProfileScreen()),
                imagePath: 'assets/icons/personal.svg',
                title: 'Change Personal Information',
              ),
              const SizedBox(height: 17),
              _customRow(
                onTap: () => Get.to(() => const ChangePasswordScreen()),
                title: 'Change Password',
                imagePath: 'assets/icons/change_password.svg',
              ),
              const SizedBox(height: 17),
              _customRow(
                onTap: () => _confirmDeleteAccount(context),
                title: 'Delete my account',
                imagePath: 'assets/icons/delete.svg',
              ),
              const SizedBox(height: 17),
              _customRow(
                onTap: () => Get.to(() => const ReportProblemScreen()),
                title: 'Report a Problem',
                imagePath: 'assets/icons/report.svg',
              ),
              const SizedBox(height: 17),
              _customRow(
                onTap: () => Get.to(
                  () => AllDataScreen(
                    title: "Terms of Service",
                    endPoint: '/terms',
                  ),
                ),
                title: 'Terms of service',
                imagePath: 'assets/icons/terms.svg',
              ),
              const SizedBox(height: 17),
              _customRow(
                onTap: () => Get.to(
                  () => AllDataScreen(
                    title: "Privacy Policy",
                    endPoint: '/privacy',
                  ),
                ),
                title: 'Privacy Policy',
                imagePath: 'assets/icons/privacy.svg',
              ),
              const SizedBox(height: 17),
              _customRow(
                onTap: () => Get.to(
                  () => AllDataScreen(title: "About Us", endPoint: '/about'),
                ),

                title: 'About',
                imagePath: 'assets/icons/about.svg',
              ),
              const SizedBox(height: 17),

              /// Logout
              InkWell(
                onTap: () => _confirmLogout(context),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/logout.svg'),
                    const SizedBox(width: 13),
                    const Text(
                      "Logout",
                      style: TextStyle(
                        color: Color(0xFFF04B4C),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomMenu(3),
    );
  }

  /// Reusable row for settings
  Widget _customRow({
    required String title,
    required String imagePath,
    required Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(imagePath),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF676565),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF799777),
            size: 16,
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFC4C3C3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to delete your account?",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _dialogActions(
              context,
              onYes: () {
                authController.deleteAccount();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFC4C3C3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to log out?",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _dialogActions(
              context,
              onYes: () {
                authController.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogActions(BuildContext context, {required VoidCallback onYes}) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onYes,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text("No", style: TextStyle(color: Color(0xFF676565))),
          ),
        ),
      ],
    );
  }
}
