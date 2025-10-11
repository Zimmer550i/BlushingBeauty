import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../../controllers/chat_controller.dart';
import '../../../../controllers/user_controller.dart';
import '../../../../services/shared_prefs_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/media_store.dart';
import 'AllSubScreen/video_preview_screen.dart';

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
  final ChatController chatController = Get.put(ChatController(), permanent: true);
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

  Future<File> _downloadVideoToLocal(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4");
    await file.writeAsBytes(response.bodyBytes);
    return file;
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
                  return Center(child: SpinKitWave(color: AppColors.primaryColor, size: 30.0));
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      crossAxisAlignment:
      msg["isMe"] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
    return Column(
      crossAxisAlignment:
      msg["isMe"] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl.toString(),
            height: 180,
            width: 240,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              "assets/images/receiver.jpg",
              height: 180,
              width: 240,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(msg["time"] ?? "", style: const TextStyle(fontSize: 10)),
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
            child: Center(child: SpinKitWave(color: AppColors.primaryColor, size: 30.0)),
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
          crossAxisAlignment:
          msg["isMe"] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPreviewScreen(
                    videoUrl: localVideo.path,
                    countdownSeconds: 3,
                    userProfile: _receiverImage ?? "",
                    userName: widget.receiverName,
                  ),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder<String?>(
                      future: VideoThumbnail.thumbnailFile(
                        video: localVideo.path,
                        imageFormat: ImageFormat.JPEG,
                        maxHeight: 180,
                        quality: 75,
                      ),
                      builder: (_, thumbSnap) {
                        if (!thumbSnap.hasData) {
                          return Container(
                            height: 180,
                            width: 240,
                            color: Colors.black12,
                            child: Center(child: SpinKitWave(color: AppColors.primaryColor, size: 30.0)),
                          );
                        }
                        return Image.file(
                          File(thumbSnap.data!),
                          height: 180,
                          width: 240,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF56BBFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            msg['isMe'] ?
            InkWell(
              onTap: () async => await saveVideoToGallery(context, localVideo.path),
              child: Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Spacer(),
                    SvgPicture.asset(
                      'assets/icons/download.svg',
                      color: const Color(0xFF56BBFF),
                      height: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Save to gallery",
                      style: TextStyle(fontSize: 12, color: Color(0xFF56BBFF)),
                    ),
                    Spacer(),
                    Text(
                      msg["time"] ?? "",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ) : InkWell(
              onTap: () async => await saveVideoToGallery(context, localVideo.path),
              child: Padding(
                padding: const EdgeInsets.only(right: 50),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg["time"] ?? "",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Spacer(),
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
                    Spacer(),
                  ],
                ),
              ),
            )
          ],
        );
      },
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
