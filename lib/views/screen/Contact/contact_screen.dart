import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/contact_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Contact/create_group_screen.dart';

import '../../base/bottom_menu.dart';

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

  @override
  void initState() {
    super.initState();
    contactController.fetchContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Contact List",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(child: _buildContactList()),
              const SizedBox(height: 12),
              _buildCreateGroupButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomMenu(2),
    );
  }

  // 🔍 Search Bar
  Widget _buildSearchBar() {
    return CustomTextField(
      controller: searchTextController,
      onChanged: contactController.filterContacts,
      borderColor: Colors.transparent,
      suffixIcon: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SvgPicture.asset('assets/icons/search.svg'),
      ),
      hintText: 'Search here',
    );
  }

  // 👥 Contact List (Reactive)
  Widget _buildContactList() {
    return Obx(() {
      if (contactController.isLoading.value) {
        return Center(child: SpinKitWave(color: AppColors.primaryColor, size: 30.0));
      }

      final matched = contactController.filteredMatchedContacts;
      final unmatched = contactController.filteredUnmatchedContacts;
      final apiUsers = userController.allUsers;

      if (matched.isEmpty && unmatched.isEmpty) {
        return const Center(
          child: Text(
            "No contacts found.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        );
      }

      return ListView(
        children: [
          if (matched.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Friends on re:",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ...matched.map((c) => _buildMatchedContactTile(c, apiUsers)),
          ],
          if (unmatched.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Invite Friends",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            ...unmatched.map(_buildUnmatchedContactTile),
          ],
        ],
      );
    });
  }

  // ✅ Friend already on app
  Widget _buildMatchedContactTile(Map<String, dynamic> c, List<dynamic> apiUsers) {
    

    final imageUrl = userController.addBaseUrl(c['image']);
    final name = c["name"] ?? "No Name";
    final phone = c["phone"] ?? "";

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: imageUrl != null
            ? NetworkImage(imageUrl)
            : const AssetImage("assets/images/dummy.jpg") as ImageProvider,
      ),
      title: Text(name),
      subtitle: Text(phone),
      trailing: InkWell(
        onTap: () => chatController.createPrivateChat(
          name,
          c['image'],
          c["_id"],
        ),
        child: SvgPicture.asset(
          "assets/icons/message.svg",
          color: AppColors.primaryColor,
          height: 22,
        ),
      ),
    );
  }

  // 📨 Friend not on app
  Widget _buildUnmatchedContactTile(Map<String, dynamic> c) {
    final name = c["name"] ?? "Unknown";
    final phone = c["phone"] ?? "";

    return ListTile(
      leading: const CircleAvatar(
        backgroundImage: AssetImage("assets/images/dummy.jpg"),
      ),
      title: Text(name),
      subtitle: Text(phone),
      trailing: InkWell(
        onTap: () => contactController.sendInviteSms(context, phone, name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  // ➕ Create Group Button
  Widget _buildCreateGroupButton() {
    return CustomButton(
      onTap: () {
        final matched = contactController.matchedContacts;
        if (matched.isEmpty) {
          Get.snackbar("No Friends", "You don’t have any friends to create a groupChat with.");
          return;
        }
        Get.to(() => CreateGroupScreen(matchedContacts: matched));
      },
      text: "Create Group",
    );
  }
}
