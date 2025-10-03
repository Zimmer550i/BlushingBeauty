import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/contact_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/bottom_menu..dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Contact/create_group_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final searchTextController = TextEditingController();
  final UserController userController = Get.put(UserController());
  final ContactController contactController = Get.put(ContactController());
  final ChatController chatController = Get.put(ChatController());

  @override
  void initState() {
    super.initState();
    contactController.fetchContacts();   // fetch & save contacts
    userController.fetchAllUsers();      // fetch app users
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              "Contact List",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: searchTextController,
              borderColor: Colors.transparent,
              suffixIcon: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SvgPicture.asset('assets/icons/search.svg'),
              ),
              hintText: 'Search here',
            ),

            Expanded(
              child: Obx(() {
                if (userController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (contactController.contacts.isEmpty) {
                  return const Center(child: Text("No contacts found"));
                }

                final apiUsers = userController.allUsers;
                final contacts = contactController.contacts;

                return ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final number = contact["number"] ?? "";
                    final name = contact["name"] ?? "Unknown";

                    final matchedUser = apiUsers.firstWhereOrNull(
                          (u) => u.phone == number || u.email == number,
                    );

                    if (matchedUser != null) {
                      final image = userController.addBaseUrl(matchedUser.image);
                      return Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: matchedUser.image.isNotEmpty
                                    ? NetworkImage(image.toString())
                                    : const AssetImage("assets/images/dummy.jpg")
                                as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            matchedUser.name.isEmpty ? "No Name" : matchedUser.name,
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap:(){
                              chatController.createPrivateChat(matchedUser.id);
                            },
                            child: SvgPicture.asset(
                              "assets/icons/message.svg",
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage("assets/images/dummy.jpg"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textColor,
                                ),
                              ),
                              Text(
                                number,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () async {
                              await contactController.sendInviteSms(number, name);
                            },
                            child: Container(
                              height: 38,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFC4C3C3),
                                  width: 0.5,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Invite",
                                  style: TextStyle(
                                    color: Color(0xFF676565),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                );
              }),
            ),

            CustomButton(
              onTap: () {
                Get.to(() => CreateGroupScreen());
              },
              text: "Create Group",
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomMenu(2),
    );
  }
}
