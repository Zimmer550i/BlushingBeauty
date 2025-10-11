import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import '../../controllers/group_chat_controller.dart';

class CustomDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String chatId;

  const CustomDropdown({super.key, required this.items, required this.chatId});

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  final GroupChatController controller = Get.put(GroupChatController());
  final UserController userController = Get.put(UserController());
  bool expanded = false;

  // Keep a local copy of members so we can update it
  late List<Map<String, dynamic>> members;
  String? myId;

  @override
  void initState() {
    super.initState();
    myId = userController.userInfo.value!.id;
    members = List<Map<String, dynamic>>.from(widget.items);
  }

  void _confirmRemove(Map<String, dynamic> member) async {
    Get.defaultDialog(
      title: "Remove Member",
      middleText: "Are you sure you want to remove ${member['name']}?",
      textCancel: "No",
      textConfirm: "Yes",
      confirmTextColor: Colors.white,
      onCancel: () => Get.back(),
      onConfirm: () async {
        final result = await controller.removeMemberFromGroup(
          groupId: widget.chatId,
          memberId: member["_id"],
        );

        if (result == "success") {
          // 🔥 Re-fetch group details to refresh UI
          await controller.fetchGroupDetails(widget.chatId);
          Get.back();
          Get.snackbar("Removed", "${member['name']} removed from groupChat");
        }
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header (See members)
        InkWell(
          onTap: () => setState(() => expanded = !expanded),
          child: Row(
            children: [
              const Text(
                "See members",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Members List
        if (expanded)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: members.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: item['image'] != null &&
                                item['image'].toString().isNotEmpty
                                ? NetworkImage(item['image'])
                                : null,
                            child: (item['image'] == null ||
                                item['image'].toString().isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item['name'] ?? "Unknown",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textColor,
                              ),
                            ),
                          ),
                          // inside Row children
                          if (item["_id"] != myId)
                            InkWell(
                              onTap: () => _confirmRemove(item),
                              child: Container(
                                height: 24,
                                width: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFc4c3c3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            )

                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          )
      ],
    );
  }
}
