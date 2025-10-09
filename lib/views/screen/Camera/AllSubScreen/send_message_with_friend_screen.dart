import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/controllers/contact_controller.dart';
import 'package:ree_social_media_app/controllers/message_controller.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_checkbox_screen.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

class SendMessageWithFriendScreen extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const SendMessageWithFriendScreen({
    super.key,
    required this.filePath,
    required this.isVideo,
  });

  @override
  State<SendMessageWithFriendScreen> createState() =>
      _SendMessageWithFriendScreenState();
}

class _SendMessageWithFriendScreenState
    extends State<SendMessageWithFriendScreen> {
  final ContactController _contactController = Get.put(ContactController());
  final MessageController _messageController = Get.put(MessageController());
  final ChatController chatController = Get.put(ChatController());
  final UserController _userController = Get.put(UserController());
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  bool _isLoading = true;

  /// Store selected user IDs
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFriends);
    _searchController.dispose();
    super.dispose();
  }

  /// 🧩 Initialize Contacts + Chats
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      await _contactController.fetchContacts();
      await _messageController.fetchChats();

      final contacts = _contactController.matchedContacts;
      final currentUserId = _userController.userInfo.value?.id;

      if (contacts.isEmpty) debugPrint("⚠️ No contacts found.");

      /// 🔁 Wait until privateChats are loaded (not empty)
      int retry = 0;
      while (_messageController.privateChats.isEmpty && retry < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retry++;
      }

      if (_messageController.privateChats.isEmpty) {
        debugPrint("⚠️ Still no private chats after waiting, skipping match.");
      }

      /// ✅ Collect private chat members (exclude self)
      final Set<String> existingChatUserIds = {};
      for (var chat in _messageController.privateChats) {
        if (chat['type'] == 'private' && chat['members'] != null) {
          for (var member in chat['members']) {
            final memberId = member['_id']?.toString();
            if (memberId != null && memberId != currentUserId) {
              existingChatUserIds.add(memberId);
            }
          }
        }
      }

      /// ✅ Match contacts with private chat users
      final matchedFriends = contacts.where((contact) {
        final contactId = contact['_id']?.toString();
        return existingChatUserIds.contains(contactId);
      }).map((contact) {
        final chat = _messageController.privateChats.firstWhereOrNull((chat) {
          if (chat['members'] == null) return false;
          final memberIds = (chat['members'] as List)
              .map((m) => m['_id'].toString())
              .toList();
          return memberIds.contains(contact['_id'].toString());
        });
        return {
          ...contact,
          'chatId': chat?['_id'],
          'hasChat': chat != null,
          'isInvite': false,
        };
      }).toList();

      debugPrint("✅ Found ${matchedFriends.length} matched friends");

      setState(() {
        _friends = matchedFriends;
        _filteredFriends = List.from(matchedFriends);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error initializing data: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Filter Friends by Search Query
  void _filterFriends() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredFriends = query.isEmpty
          ? List.from(_friends)
          : _friends
          .where((f) => (f['name'] ?? '').toLowerCase().contains(query))
          .toList();
    });
  }

  /// 🚀 Send the selected media file
  Future<void> _sendToSelectedFriends() async {
    if (_selectedIds.isEmpty) {
      if (Get.isSnackbarOpen!) Get.closeAllSnackbars();
      Get.snackbar("Error", "Please select at least one friend.");
      return;
    }

    try {
      final file = File(widget.filePath);
      final contentType = widget.isVideo ? 'video' : 'image';

      await chatController.sendMediaToMultipleChats(
        friends: _friends,
        selectedIds: _selectedIds,
        mediaFile: file,
        contentType: contentType,
      );

      // ✅ Close any open snackbars safely before showing new
      if (Get.isSnackbarOpen!) Get.closeAllSnackbars();

      // ✅ Show success message
      Get.snackbar(
        "Success",
        "Media sent to ${_selectedIds.length} friend${_selectedIds.length > 1 ? 's' : ''}!",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // ✅ Delay navigation slightly to let snackbar settle
      await Future.delayed(const Duration(milliseconds: 600));

      if (Get.isOverlaysOpen) {
        Get.back(closeOverlays: true);
      }
      Get.back();

    } catch (e) {
      if (Get.isSnackbarOpen!) Get.closeAllSnackbars();
      Get.snackbar("Error", "Failed to send media: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchField(),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                      : _buildFriendList(),
                  const SizedBox(height: 16),
                  CustomButton(
                    onTap: _sendToSelectedFriends,
                    text: "Send Now",
                  ),
                ],
              ),
            ),
            Obx(() {
              return chatController.isLoading.value
                  ? Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
                  : const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  /// 🏷 Header
  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        const SizedBox(width: 8),
        Text(
          "Send Message",
          style: TextStyle(
            color: AppColors.textColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 🔍 Search Bar
  Widget _buildSearchField() {
    return CustomTextField(
      controller: _searchController,
      borderColor: Colors.transparent,
      suffixIcon: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SvgPicture.asset('assets/icons/search.svg'),
      ),
      hintText: 'Search friends...',
    );
  }

  /// 👥 Friend List
  Widget _buildFriendList() {
    if (_filteredFriends.isEmpty) {
      return const Expanded(
        child: Center(child: Text("No chat friends found")),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _filteredFriends.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, index) {
          final friend = _filteredFriends[index];
          final imageUrl = _userController.addBaseUrl(friend['image']);
          final isSelected = _selectedIds.contains(friend['_id']);

          return Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl)
                    : const AssetImage("assets/images/dummy.jpg")
                as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  friend['name'] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              CustomCheckboxScreen(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds.add(friend['_id']);
                    } else {
                      _selectedIds.remove(friend['_id']);
                    }
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
