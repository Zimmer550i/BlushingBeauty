import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/contact_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/re_logo.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/SetUpProfile/enable_notification_screen.dart';

class InviteFriendScreen extends StatefulWidget {
  const InviteFriendScreen({super.key});

  @override
  State<InviteFriendScreen> createState() => _InviteFriendScreenState();
}

class _InviteFriendScreenState extends State<InviteFriendScreen> {
  final searchTextController = TextEditingController();
  final ContactController contactController = Get.put(ContactController());
  final UserController userController = Get.put(UserController());
  final RxSet<String> addedFriends = <String>{}.obs;

  @override
  void initState() {
    super.initState();
    contactController.fetchContacts();
    searchTextController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    contactController.filterContacts(searchTextController.text);
  }

  Widget _buildContactTile(
    Map<String, dynamic> contact, {
    bool isMatched = true,
  }) {
    final id = contact["_id"];
    final image = userController.addBaseUrl(contact["image"].toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image:
                    (contact["image"] != null &&
                        contact["image"].toString().isNotEmpty)
                    ? NetworkImage(image.toString())
                    : const AssetImage('assets/images/dummy.jpg')
                          as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Contact info (flexible to prevent overflow)
          Expanded(
            child: Text(
              "${contact["name"] ?? "Unknown"}\n${contact["phone"] ?? ""}",
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF676565),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Action Button (wrapped in Obx for reactive updates)
          isMatched == true
              ? GestureDetector(
                  onTap: () {
                    if (!addedFriends.contains(id)) {
                      addedFriends.add(id);
                      contactController.createPrivateChat(id);
                    }
                  },
                  child: Container(
                    height: 38,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF002329,
                          ).withValues(alpha: 0.07),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Obx(
                        () => Text(
                          addedFriends.contains(id) ? "Added" : "Add",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    contactController.sendInviteSms(
                      contact["phone"],
                      contact["name"],
                    );
                  },
                  child: Container(
                    height: 38,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 0),
                          blurRadius: 4,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: .5),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Obx(
                        () => Text(
                          addedFriends.contains(id) ? "Invited" : "Invite",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReeLogo(),
                  Text(
                    "2 of 4",
                    style: TextStyle(
                      color: const Color(0xFF413E3E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Obx(() {
                final matched = contactController.filteredMatchedContacts;
                final unmatched = contactController.filteredUnmatchedContacts;
                final isLoading = contactController.isLoading.value;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Connect With Friends",
                        style: TextStyle(
                          color: Color(0xFF413E3E),
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "To start your first messages on",
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
                              text: " invite 5 friends who matter most",
                              style: TextStyle(
                                color: Color(0xFF676565),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Search bar
                      CustomTextField(
                        controller: searchTextController,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: SvgPicture.asset('assets/icons/search.svg'),
                        ),
                        hintText: 'Search Contacts',
                      ),
                      const SizedBox(height: 24),

                      // Loading
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        // Friends on re:
                        if (matched.isNotEmpty) ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: matched.length,
                            itemBuilder: (context, index) => _buildContactTile(
                              matched[index],
                              isMatched: true,
                            ),
                          ),
                        ],

                        // Invite to join
                        if (unmatched.isNotEmpty) ...[
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: unmatched.length,
                            itemBuilder: (context, index) => _buildContactTile(
                              unmatched[index],
                              isMatched: false,
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 30),
                      Obx(() {
                        final canProceed = addedFriends.length >= 5;

                        return CustomButton(
                          // onTap: canProceed
                          //     ? () => Get.to(
                          //         () => const EnableNotificationScreen(),
                          //       )
                          //     : () {
                          //         Get.snackbar(
                          //           "Add More Friends",
                          //           "Please add at least 5 friends to continue.",
                          //           snackPosition: SnackPosition.BOTTOM,
                          //           backgroundColor: Colors.redAccent,
                          //           colorText: Colors.white,
                          //         );
                          //       },
                          onTap: () =>
                              Get.to(() => const EnableNotificationScreen()),
                          text: "Next",
                          color: canProceed
                              ? AppColors.primaryColor
                              : AppColors.primaryColor.withValues(alpha: .4),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
