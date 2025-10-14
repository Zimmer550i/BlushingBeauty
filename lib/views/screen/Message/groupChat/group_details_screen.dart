import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_dropdown.dart';
import '../../../../controllers/group_chat_controller.dart';
import 'add_group_member.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String chatId;
  final String groupName;
  final String groupImage;

  const GroupDetailsScreen({
    super.key,
    required this.chatId,
    required this.groupName,
    required this.groupImage,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final GroupChatController controller = Get.put(GroupChatController());
  final UserController userController = Get.put(UserController());
  final TextEditingController _nameController = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? imageUrl;
  final List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();

    // 1️⃣ Fetch group details first
    controller.fetchGroupDetails(widget.chatId);

    // 2️⃣ Watch for group image change reactively
    ever(controller.groupImage, (_) {
      setState(() {
        imageUrl = controller.groupImage.value.isNotEmpty
            ? controller.groupImage.value.startsWith("http")
                  ? controller.groupImage.value
                  : userController.addBaseUrl(controller.groupImage.value)
            : "";
      });
    });

    // 3️⃣ Watch for members change reactively
    ever(controller.members, (_) {
      setState(() {
        members
          ..clear()
          ..addAll(
            controller.members.map((m) {
              return {
                "name": m["name"],
                "image": userController.addBaseUrl(m["image"]),
                "_id": m["_id"],
              };
            }),
          );
      });
    });
  }

  Future<void> _chooseImageSource() async {
    final XFile? pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Pick from Gallery"),
              onTap: () async {
                Navigator.pop(
                  ctx,
                  await _picker.pickImage(source: ImageSource.gallery),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () async {
                Navigator.pop(
                  ctx,
                  await _picker.pickImage(source: ImageSource.camera),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      controller.updateGroup(widget.chatId, image: _profileImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Top bar
                Row(
                  children: [
                    InkWell(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.groupName.value.isNotEmpty
                            ? controller.groupName.value
                            : "Group",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF413E3E),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                /// Group image
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: (imageUrl?.isNotEmpty ?? false)
                            ? NetworkImage(imageUrl!)
                            : null,
                        child: (imageUrl == null || imageUrl!.isEmpty)
                            ? Text(
                                controller.groupName.value.isNotEmpty
                                    ? controller.groupName.value[0]
                                          .toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _chooseImageSource,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// Change group name
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF56BBFF).withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Change Group Name",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF413E3E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: "Write here",
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            final newName = _nameController.text.trim();
                            if (newName.isNotEmpty) {
                              controller.updateGroup(
                                widget.chatId,
                                name: newName,
                              );
                            } else {
                              Get.snackbar(
                                "Error",
                                "Group name cannot be empty",
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Update",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                /// Members
                _buildMembersList(),

                /// Options
                _optionTile(
                  "Add members",
                  onTap: () {
                    Get.to(
                      () => AddGroupMemberScreen(
                        chatId: widget.chatId,
                        existMembers: members,
                      ),
                    );
                  },
                ),
                _optionTile(
                  "Delete chat",
                  onTap: () {
                    confirm(context, () {
                      controller.deleteGroup(widget.chatId);
                    },"delete this group chat");
                  },
                ),

                _optionTile(
                  "Leave chat",
                  onTap: () {
                    confirm(context, () {
                      controller.leaveGroup(widget.chatId);
                    },"leave this group chat");
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _optionTile(String title, {VoidCallback? onTap, Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF413E3E)),
            ),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Obx(() {
        final members = controller.members.map((m) {
          return {
            "name": m["name"],
            "image": userController.addBaseUrl(m["image"]),
            "_id": m["_id"],
          };
        }).toList();

        if (members.isEmpty) {
          return const Text(
            "No members yet.",
            style: TextStyle(color: Colors.grey),
          );
        }

        return CustomDropdown(items: members, chatId: widget.chatId);
      }),
    );
  }

  void confirm(BuildContext context, VoidCallback onYes, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFC4C3C3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you sure you want to $title?",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _dialogActions(context, onYes: () async {}),
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
