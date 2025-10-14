import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ree_social_media_app/views/base/blur_image_card.dart';
import 'package:ree_social_media_app/views/base/blur_video_card.dart';
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

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        BlurImageCard(imageUrl: imageUrl.toString()),
        const SizedBox(height: 4),
        Text(
          msg["time"] ?? "",
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildVideoMessage(Map<String, dynamic> msg) {
    final videoUrl = userController.addBaseUrl(msg["media"] ?? "");

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
              videoFile: localVideo,
              msg: msg,
              receiverImage: _receiverImage,
              receiverName: widget.receiverName,
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
    final timeText = Text(
      msg["time"] ?? "",
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );

    final saveRow = InkWell(
      onTap: () async => await saveVideoToGallery(context, path),
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
            SizedBox(width: 8),
            const Text(
              "Save to gallery",
              style: TextStyle(fontSize: 12, color: Color(0xFF56BBFF)),
            ),
            Spacer(),
            timeText,
          ],

          if (!isMe) ...[
            timeText,
            const Spacer(),
            const Text(
              "Save to gallery",
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

    return Padding(
      padding: EdgeInsets.only(left: isMe ? 50 : 0, right: isMe ? 0 : 50),
      child: saveRow,
    );
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
            onTap: () => chatController.pickAndSendVideo(),
            child: SvgPicture.asset(
              'assets/icons/add_more.svg',
              color: const Color(0xFF56BBFF),
              height: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
              onChanged: (val) {
                chatController.sendTyping(val.isNotEmpty);
              },
            ),
          ),
          InkWell(
            onTap: () => chatController.pickAndSendImage(),
            child: SvgPicture.asset(
              'assets/icons/camera.svg',
              height: 22,
              width: 22,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _sendTextMessage,
            child: SvgPicture.asset(
              'assets/icons/send.svg',
              color: const Color(0xFF56BBFF),
              height: 26,
            ),
          ),
        ],
      ),
    );
  }
}
