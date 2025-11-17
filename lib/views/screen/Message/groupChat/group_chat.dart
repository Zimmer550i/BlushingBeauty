// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ree_social_media_app/helpers/route.dart';
import 'package:ree_social_media_app/views/screen/Camera/camera_screen.dart';
import '../../../../controllers/chat_controller.dart';
import '../../../../controllers/user_controller.dart';
import '../../../../services/shared_prefs_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/media_store.dart';
import '../../../base/blur_image_card.dart';
import '../../../base/blur_video_card.dart';
import '../../../base/custom_text_field.dart';
import 'group_details_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String chatId;
  final String groupName;
  final String groupImage;

  const GroupChatScreen({
    super.key,
    required this.chatId,
    required this.groupName,
    required this.groupImage,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final UserController userController = Get.put(UserController());
  final ChatController chatController = Get.put(ChatController());
  final messageTextController = TextEditingController();

  String? image;
  String? token;
  String? currentUserId;

  final Map<String, File> _videoCache = {};

  @override
  void initState() {
    super.initState();
    _initGroupChat();
  }

  Future<void> _initGroupChat() async {
    image = userController.addBaseUrl(widget.groupImage);
    currentUserId = userController.userInfo.value?.id;
    token = await SharedPrefsService.get('token');

    if (token != null && currentUserId != null) {
      await chatController.initChat(
        chatId: widget.chatId,
        currentUserId: currentUserId!,
        token: token!,
      );
    } else {
      debugPrint("⚠️ Missing token or userId, cannot connect socket");
    }
  }

  @override
  void dispose() {
    messageTextController.dispose();
    chatController.disconnect();
    super.dispose();
  }

  void _sendMessage() {
    final text = messageTextController.text.trim();
    if (text.isNotEmpty) {
      chatController.sendText(text);
      messageTextController.clear();
    }
  }

  // ✅ Download + cache video
  Future<File> _downloadVideoToLocal(String url) async {
    try {
      if (_videoCache.containsKey(url)) {
        return _videoCache[url]!;
      }

      final fileName = "${url.hashCode}.mp4";
      final dir = await getTemporaryDirectory();
      final videoDir = Directory("${dir.path}/group_videos");
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final filePath = "${videoDir.path}/$fileName";
      final cachedFile = File(filePath);

      if (await cachedFile.exists()) {
        _videoCache[url] = cachedFile;
        debugPrint("✅ Using cached group video for: $url");
        return cachedFile;
      }

      debugPrint("⬇️ Downloading group video from: $url");
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await cachedFile.writeAsBytes(response.bodyBytes);
        _videoCache[url] = cachedFile;
        debugPrint("✅ Group video downloaded & cached: ${cachedFile.path}");
        return cachedFile;
      } else {
        throw Exception("Failed to download video: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error downloading group video: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            // 💬 Chat messages
            Expanded(
              child: Obx(() {
                final msgs = chatController.messages;

                if (chatController.isLoading.value && msgs.isEmpty) {
                  return Center(
                    child: SpinKitWave(
                      color: AppColors.primaryColor,
                      size: 30.0,
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.minScrollExtent) {
                      chatController.loadOlder();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    reverse: true,
                    controller: chatController.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: msgs.length,
                    itemBuilder: (_, index) {
                      final msg = msgs[index];
                      return Align(
                        alignment: msg["isMe"]
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: _buildMessage(msg),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
            Obx(
              () => chatController.isLoading.value
                  ? LinearProgressIndicator(
                      color: AppColors.primaryColor,
                      backgroundColor: AppColors.primaryColor,
                    )
                  : const SizedBox.shrink(),
            ),

            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          InkWell(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back, color: Color(0xFF0D1C12)),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => Get.to(
              () => GroupDetailsScreen(
                chatId: widget.chatId,
                groupName: widget.groupName,
                groupImage: widget.groupImage,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryColor,
              backgroundImage: widget.groupImage.isNotEmpty
                  ? NetworkImage(image!)
                  : null,
              child: widget.groupImage.isEmpty
                  ? Text(
                      widget.groupName.isNotEmpty
                          ? widget.groupName[0].toUpperCase()
                          : "?",
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.groupName,
              style: const TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => Get.to(
              () => GroupDetailsScreen(
                chatId: widget.chatId,
                groupName: widget.groupName,
                groupImage: widget.groupImage,
              ),
            ),
            child: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.black100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset('assets/icons/more.svg'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MESSAGE TYPES ==================
  Widget _buildMessage(Map<String, dynamic> msg) {
    switch (msg["type"]) {
      case "image":
        return _buildImageMessage(msg);
      case "video":
        return _buildVideoMessage(msg);
      default:
        return _buildTextMessage(msg);
    }
  }

  Widget _buildTextMessage(Map<String, dynamic> msg) {
    return Column(
      crossAxisAlignment: msg["isMe"]
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color: msg["isMe"]
                ? const Color(0xFF56BBFF)
                : const Color(0xFFECECEC),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(32),
              topRight: const Radius.circular(32),
              bottomLeft: msg["isMe"]
                  ? const Radius.circular(32)
                  : const Radius.circular(0),
              bottomRight: msg["isMe"]
                  ? const Radius.circular(0)
                  : const Radius.circular(32),
            ),
          ),
          child: Text(
            msg["message"] ?? "",
            style: TextStyle(
              color: msg["isMe"] ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          msg["time"] ?? "",
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildImageMessage(Map<String, dynamic> msg) {
    final imageUrl = userController.addBaseUrl(msg["media"] ?? "");
    bool isMe = msg["isMe"] ?? false;
    bool view = msg["view"] ?? false;
    final bool isViewed = isMe ? true : view;
    bool hasThumbnail = false;

    String thumbnail = "";

    if (msg["thumbnail"] != null && msg["thumbnail"].toString().isNotEmpty) {
      final thumbnailUrl = userController.addBaseUrl(msg["thumbnail"]);
      debugPrint("🚀 URL: $thumbnailUrl");
      thumbnail = thumbnailUrl.toString();
      hasThumbnail = true;
    } else {
      hasThumbnail = false;
      thumbnail = "";
    }

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        BlurImageCard(
          hasThumbnail: hasThumbnail,
          thumbnail: thumbnail,
          isMe: isMe,
          chatController: chatController,
          msgId: msg["_id"],
          imageUrl: imageUrl.toString(),
          receiverName: widget.groupName,
          receiverImage: image,
          chatId: widget.chatId,
          isView: isViewed,
        ),
        const SizedBox(height: 4),
        _buildImageFooter(msg, imageUrl.toString()),
      ],
    );
  }

  Widget _buildVideoMessage(Map<String, dynamic> msg) {
    final videoUrl = userController.addBaseUrl(msg["media"] ?? "");
    final thumbnail = userController.addBaseUrl(msg["thumbnail"] ?? "");
    bool isMe = msg["isMe"] ?? false;
    bool view = msg["view"] ?? false;
    final bool isViewed = isMe ? true : view;
    bool hasThumbnail = msg["thumbnail"] != null;

    return FutureBuilder<File>(
      future: _downloadVideoToLocal(videoUrl.toString()),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 180,
            width: 240,
            child: Center(
              child: SpinKitWave(color: AppColors.primaryColor, size: 30.0),
            ),
          );
        }

        if (!snap.hasData) {
          return const SizedBox(
            height: 180,
            width: 240,
            child: Center(child: Icon(Icons.error)),
          );
        }

        final localVideo = snap.data!;

        return Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            BlurVideoCard(
              hasThumbnail: hasThumbnail,
              thumbnail: thumbnail.toString(),
              isMe: isMe,
              chatController: chatController,
              msgId: msg["_id"],
              isView: isViewed,
              videoFile: localVideo,
              msg: msg,
              receiverImage: image,
              receiverName: widget.groupName,
              chatId: widget.chatId,
            ),
            const SizedBox(height: 6),
            _buildVideoFooter(msg, localVideo.path),
          ],
        );
      },
    );
  }

  Widget _buildVideoFooter(Map<String, dynamic> msg, String path) {
    final isMe = msg['isMe'] ?? false;
    final rawTime =
        msg["time"]; // e.g. "2025-11-04T15:45:00" or "2025-11-04 15:45:00"
    String formattedTime = "";

    if (rawTime != null && rawTime.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(rawTime);
        int hour = dateTime.hour;
        int minute = dateTime.minute;

        // Determine AM or PM
        String suffix = hour >= 12 ? 'PM' : 'AM';

        // Convert to 12-hour format
        hour = hour % 12;
        if (hour == 0) hour = 12; // 0 hour means 12 AM or 12 PM

        // Format with leading zero for minute
        formattedTime =
            "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix";
      } catch (e) {
        formattedTime = rawTime; // fallback if parsing fails
      }
    }

    final timeText = Text(
      formattedTime,
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );

    final saveRow = InkWell(
      onTap: () async => await saveVideoToGallery(context, path, false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMe) ...[
            Spacer(),
            SvgPicture.asset(
              'assets/icons/download.svg',
              color: const Color(0xFF56BBFF),
              height: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              "Save",
              style: TextStyle(fontSize: 12, color: Color(0xFF56BBFF)),
            ),
            Spacer(),
            timeText,
          ],
          if (!isMe) ...[
            timeText,
            const Spacer(),
            const Text(
              "Save",
              style: TextStyle(fontSize: 12, color: Color(0xFF56BBFF)),
            ),
            const SizedBox(width: 6),
            SvgPicture.asset(
              'assets/icons/download.svg',
              color: const Color(0xFF56BBFF),
              height: 18,
            ),
            const Spacer(),
          ],
        ],
      ),
    );

    return saveRow;
  }

  Widget _buildImageFooter(Map<String, dynamic> msg, String path) {
    final isMe = msg['isMe'] ?? false;
    final rawTime =
        msg["time"]; // e.g. "2025-11-04T15:45:00" or "2025-11-04 15:45:00"
    String formattedTime = "";

    if (rawTime != null && rawTime.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(rawTime);
        int hour = dateTime.hour;
        int minute = dateTime.minute;

        // Determine AM or PM
        String suffix = hour >= 12 ? 'PM' : 'AM';

        // Convert to 12-hour format
        hour = hour % 12;
        if (hour == 0) hour = 12;

        // Format with leading zero for minute
        formattedTime =
            "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix";
      } catch (e) {
        formattedTime = rawTime;
      }
    }

    final timeText = Text(
      formattedTime,
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );

    final saveRow = InkWell(
      onTap: () async => await saveVideoToGallery(context, path, true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMe) ...[
            Spacer(),
            SvgPicture.asset(
              'assets/icons/download.svg',
              color: const Color(0xFF56BBFF),
              height: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              "Save",
              style: TextStyle(fontSize: 12, color: Color(0xFF56BBFF)),
            ),
            Spacer(),
            timeText,
          ],
          if (!isMe) ...[
            timeText,
            const Spacer(),
            const Text(
              "Save",
              style: TextStyle(fontSize: 12, color: Color(0xFF56BBFF)),
            ),
            const SizedBox(width: 6),
            SvgPicture.asset(
              'assets/icons/download.svg',
              color: const Color(0xFF56BBFF),
              height: 18,
            ),
            const Spacer(),
          ],
        ],
      ),
    );

    return saveRow;
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => chatController.pickAndSendMedia(),
            child: SvgPicture.asset(
              'assets/icons/add_more.svg',
              color: AppColors.primaryColor,
              height: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomTextField(
              controller: messageTextController,
              hintText: 'Type your message...',
              borderSide: const BorderSide(color: Colors.transparent),
            ),
          ),
          InkWell(
            onTap: () {
              Get.to(
                () => CameraScreen(
                  cameras: AppRoutes.cameras ?? [],
                  isChatBox: true,
                  chatId: widget.chatId,
                ),
              );
            },
            child: SvgPicture.asset(
              'assets/icons/camera.svg',
              height: 22,
              width: 22,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 20),
          InkWell(
            onTap: _sendMessage,
            child: SvgPicture.asset(
              'assets/icons/send.svg',
              color: AppColors.primaryColor,
              height: 26,
            ),
          ),
        ],
      ),
    );
  }
}
