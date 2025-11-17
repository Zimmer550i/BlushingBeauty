// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ree_social_media_app/helpers/route.dart';
import 'package:ree_social_media_app/views/base/blur_image_card.dart';
import 'package:ree_social_media_app/views/base/blur_video_card.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Camera/camera_screen.dart';
import '../../../../controllers/chat_controller.dart';
import '../../../../controllers/user_controller.dart';
import '../../../../services/shared_prefs_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/media_store.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String receiverImage;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.receiverImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController chatController = Get.put(
    ChatController(),
    permanent: true,
  );
  final UserController userController = Get.put(UserController());
  final TextEditingController messageController = TextEditingController();

  String? _token;
  String? _currentUserId;
  String? _receiverImage;

  @override
  void initState() {
    super.initState();
    _setupChat();
  }

  Future<void> _setupChat() async {
    _receiverImage = userController.addBaseUrl(widget.receiverImage);
    _token = await SharedPrefsService.get('token');
    _currentUserId = userController.userInfo.value?.id;

    if (_token != null && _currentUserId != null) {
      await chatController.initChat(
        chatId: widget.chatId,
        currentUserId: _currentUserId!,
        token: _token!,
      );
    } else {
      debugPrint("⚠️ Missing token or userId, cannot connect socket");
    }
  }

  @override
  void dispose() {
    chatController.disconnect();
    messageController.dispose();
    super.dispose();
  }

  void _sendTextMessage() {
    final text = messageController.text.trim();
    if (text.isNotEmpty) {
      chatController.sendText(text);
      messageController.clear();
    }
  }

  // 🧠 Cache map for already downloaded videos
  final Map<String, File> _videoCache = {};

  Future<File> _downloadVideoToLocal(String url) async {
    try {
      // If already cached in memory
      if (_videoCache.containsKey(url)) {
        return _videoCache[url]!;
      }

      // Generate unique file name (based on url hash)
      final fileName = "${url.hashCode}.mp4";

      // Create a cache directory for videos
      final dir = await getTemporaryDirectory();
      final videoDir = Directory("${dir.path}/videos");
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final filePath = "${videoDir.path}/$fileName";
      final cachedFile = File(filePath);

      // If file already exists locally, use it directly
      if (await cachedFile.exists()) {
        _videoCache[url] = cachedFile;
        debugPrint("✅ Using cached video for: $url");
        return cachedFile;
      }

      // Otherwise, download from network
      debugPrint("⬇️ Downloading video from: $url");
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await cachedFile.writeAsBytes(response.bodyBytes);
        _videoCache[url] = cachedFile;
        debugPrint("✅ Video downloaded & cached: ${cachedFile.path}");
        return cachedFile;
      } else {
        throw Exception("Failed to download video: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error downloading video: $e");
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

            // 🌀 Messages List
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    itemCount: msgs.length,
                    itemBuilder: (_, index) {
                      final msg = msgs[index];
                      debugPrint("Rendering message: $msg");
                      return Align(
                        alignment: msg["isMe"]
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: _buildMessageBubble(msg),
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

  // ==============================================
  // 🧱 HEADER
  // ==============================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          InkWell(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back, color: Color(0xFF0D1C12)),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppColors.primaryColor,
            radius: 22,
            backgroundImage: NetworkImage(_receiverImage ?? ""),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.receiverName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF413E3E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================
  // 💬 MESSAGE TYPES
  // ==============================================
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
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
    final rawTime = msg["time"];
    String formattedTime = "";

    if (rawTime != null && rawTime.isNotEmpty) {
      try {
        // Check if the time format is valid (hh.mm)
        final parts = rawTime.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);

          // Determine AM or PM
          String suffix = hour >= 12 ? 'PM' : 'AM';

          // Convert to 12-hour format
          hour = hour % 12;
          if (hour == 0) hour = 12; // 0 hour means 12 AM or 12 PM

          // Format with leading zero for minute
          formattedTime = "$hour:${minute.toString().padLeft(2, '0')} $suffix";
        } else {
          formattedTime = "Invalid time format";
        }
      } catch (e) {
        // Fallback if any error occurs during parsing
        formattedTime = "Error parsing time: $e";
      }
    }
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
          formattedTime,
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
          receiverName: widget.receiverName,
          chatId: widget.chatId,
          isView: isViewed,
          receiverImage: _receiverImage,
        ),

        const SizedBox(height: 4),
        _buildImageFooter(msg, imageUrl.toString()),
      ],
    );
  }

  Widget _buildVideoMessage(Map<String, dynamic> msg) {
    final videoUrl = userController.addBaseUrl(msg["media"] ?? "");
    bool isMe = msg["isMe"] ?? false;
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
    final bool isViewed = isMe ? true : (msg["view"] ?? false);

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
          crossAxisAlignment: msg["isMe"]
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            BlurVideoCard(
              hasThumbnail: hasThumbnail,
              isMe: isMe,
              thumbnail: thumbnail.toString(),
              isView: isViewed,
              videoFile: localVideo,
              msg: msg,
              receiverImage: _receiverImage,
              receiverName: widget.receiverName,
              chatId: widget.chatId,
              msgId: msg["_id"],
              chatController: chatController,
            ),
            const SizedBox(height: 6),

            // Footer (Save + Time)
            _buildVideoFooter(msg, localVideo.path),
          ],
        );
      },
    );
  }

  Widget _buildVideoFooter(Map<String, dynamic> msg, String path) {
    final isMe = msg['isMe'] ?? false;
    final formattedTime = msg["time"];
    //     String formattedTime = "";
    //     if (rawTime.isNotEmpty) {
    //       final DateFormat formatter = DateFormat("HH:mm");
    // final DateTime dt = formatter.parseLoose(rawTime);
    //       if (dt != null) {
    //         final now = DateTime.now();
    //         final DateFormat timeFormat = DateFormat('h:mm a'); // AM/PM format

    //         if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
    //           // If it's today, show time with AM/PM
    //           formattedTime = timeFormat.format(dt);
    //         } else if (dt.difference(now).inDays == -1) {
    //           // If it's yesterday
    //           formattedTime = "Yesterday";
    //         } else {
    //           // For older dates, show full date with month name
    //           formattedTime = "${dt.day} ${_monthName(dt.month)} ${dt.year}";
    //         }
    //       }
    //     }

    final timeText = Text(
      formattedTime,
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );

    final saveRow = InkWell(
      onTap: () async => await saveVideoToGallery(context, path, false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // mainAxisAlignment:  MainAxisAlignment.spaceBetween,
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2.25,
            child: Row(
              children: [
                if (isMe) ...[
                  SvgPicture.asset(
                    'assets/icons/download.svg',
                    color: const Color(0xFF56BBFF),
                    height: 18,
                  ),
                  SizedBox(width: 8),
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
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return saveRow;
  }

  Widget _buildImageFooter(Map<String, dynamic> msg, String path) {
    final isMe = msg['isMe'] ?? false;
    final rawTime = msg["time"];
    String formattedTime = "";

    if (rawTime != null && rawTime.isNotEmpty) {
      try {
        // Check if the time format is valid (hh.mm)
        final parts = rawTime.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);

          // Determine AM or PM
          String suffix = hour >= 12 ? 'PM' : 'AM';

          // Convert to 12-hour format
          hour = hour % 12;
          if (hour == 0) hour = 12; // 0 hour means 12 AM or 12 PM

          // Format with leading zero for minute
          formattedTime = "$hour:${minute.toString().padLeft(2, '0')} $suffix";
        } else {
          formattedTime = "Invalid time format";
        }
      } catch (e) {
        // Fallback if any error occurs during parsing
        formattedTime = "Error parsing time: $e";
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
        // mainAxisAlignment:  MainAxisAlignment.spaceBetween,
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2.25,
            child: Row(
              children: [
                if (isMe) ...[
                  
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
                  
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return saveRow;
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  // ==============================================
  // 📝 INPUT BAR
  // ==============================================
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
              controller: messageController,
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
            onTap: _sendTextMessage,
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
