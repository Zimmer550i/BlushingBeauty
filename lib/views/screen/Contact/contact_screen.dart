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

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final searchTextController = TextEditingController();
  final ContactController contactController = Get.put(ContactController());
  final ChatController chatController = Get.put(ChatController());
  final UserController userController = Get.put(UserController());

  String? image;

  @override
  void initState() {
    super.initState();
    contactController.fetchContacts();
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
                if (contactController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final matched = contactController.matchedContacts;
                final unmatched = contactController.unmatchedContacts;
                final apiUsers = userController.allUsers;

                return ListView(
                  children: [
                    // ✅ Matched Contacts
                    if (matched.isNotEmpty) ...[
                      ...matched.map((c) {
                        // try to find the user with same id or phone
                        final matchedUser = apiUsers.firstWhereOrNull(
                          (u) =>
                              u.id == c["_id"] ||
                              u.phone == c["phone"] ||
                              u.image == c['image'],
                        );

                        final imageUrl = userController.addBaseUrl(c['image']);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : const AssetImage("assets/images/dummy.jpg")
                                      as ImageProvider,
                          ),
                          title: Text(c["name"] ?? "No Name"),
                          subtitle: Text(c["phone"] ?? ""),
                          trailing: InkWell(
                            onTap: () {
                              chatController.createPrivateChat(
                                c["name"],
                                c['image'],
                                c["_id"],
                              );
                            },
                            child: SvgPicture.asset(
                              "assets/icons/message.svg",
                              color: AppColors.primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    // ✅ Unmatched Contacts
                    if (unmatched.isNotEmpty) ...[
                      ...unmatched.map(
                        (c) => ListTile(
                          leading: const CircleAvatar(
                            backgroundImage: AssetImage(
                              "assets/images/dummy.jpg",
                            ),
                          ),
                          title: Text(c["name"] ?? "Unknown"),
                          subtitle: Text(c["phone"] ?? ""),
                          trailing: InkWell(
                            onTap: () => contactController.sendInviteSms(
                              c["phone"],
                              c["name"],
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Invite",
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),

            CustomButton(
              onTap: () {
                final matched = contactController.matchedContacts;
                Get.to(() => CreateGroupScreen(matchedContacts: matched));
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
