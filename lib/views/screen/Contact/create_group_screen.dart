import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_checkbox_screen.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/chat_screen.dart';

import '../../../controllers/chat_controller.dart';

class CreateGroupScreen extends StatefulWidget {
  final List<Map<String, dynamic>> matchedContacts;

  const CreateGroupScreen({super.key, required this.matchedContacts});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}


class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final searchTextController = TextEditingController();

  late List<Map<String, dynamic>> searchFriendList;

  @override
  void initState() {
    super.initState();
    searchFriendList = widget.matchedContacts.map((c) {
      return {
        "_id": c["_id"],  // ✅ keep user ID
        "name": c["name"] ?? "No Name",
        "image": c["image"] ?? "assets/images/dummy.jpg",
        "isInvite": false,
      };
    }).toList();

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
              "Create Group",
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
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final item = searchFriendList[index];
                  final imageUrl = item['image'].toString().startsWith("http")
                      ? NetworkImage(item['image'])
                      : AssetImage("assets/images/dummy.jpg") as ImageProvider;

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: imageUrl,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item['name'],
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      CustomCheckboxScreen(
                        value: item['isInvite'],
                        onChanged: (val) {
                          setState(() {
                            item['isInvite'] = val!;
                          });
                        },
                      ),
                    ],
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: searchFriendList.length,
              ),
            ),
            CustomButton(
              onTap: () {
                final selected = searchFriendList
                    .where((c) => c['isInvite'] == true)
                    .map((c) => c["_id"].toString()) // ✅ collect IDs
                    .toList();

                if (selected.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select at least one member")),
                  );
                  return;
                }

                final chatController = Get.find<ChatController>();
                chatController.createGroupChat(selected);
              },
              text: "Create Now",
            ),

          ],
        ),
      ),
    );
  }
}

