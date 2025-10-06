import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/group_details_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../../services/shared_prefs_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../utils/media_store.dart';

class GroupChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String currentUserId;
  final String receiverImage;

  const GroupChatScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.currentUserId,
    required this.receiverImage,
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

  @override
  void initState() {
    super.initState();
    setData();

    /// Initialize chat (fetch + socket)
    chatController.initChat(
      chatId: widget.chatId,
      currentUserId: widget.currentUserId,
      token: token.toString(),
    );
  }

  @override
  void dispose() {
    messageTextController.dispose();
    chatController.disconnect();

    super.dispose();
  }

  Future<void> setData() async {
    image = userController.addBaseUrl(widget.receiverImage);
    token = await SharedPrefsService.get('token');
  }

  /// Send message
  void _sendMessage() {
    final text = messageTextController.text.trim();
    if (text.isNotEmpty) {
      chatController.sendText(text);
      messageTextController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Get.back(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0D1C12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => Get.to(() => GroupDetailsScreen()),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(image.toString()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      color: Color(0xFF413E3E),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            /// Messages
            Expanded(
              child: Obx(() {
                final msgs = chatController.messages;

                if (chatController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.minScrollExtent) {
                      // reached top → load older
                      chatController.loadOlder();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    reverse: true,
                    controller: chatController.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
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

            /// Input
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildInputBar(),
            ),
          ],
        ),
      ),
    );
  }

  /// Render message type
  Widget _buildMessage(Map<String, dynamic> msg) {
    switch (msg["type"]) {
      case "text":
        return _buildTextMessage(msg);
      case "video":
        return _buildVideoMessage(msg);
      case "image":
        return _buildImageMessage(msg);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Text bubble
  Widget _buildTextMessage(Map<String, dynamic> msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: msg["isMe"] ? const Color(0xFF56BBFF) : const Color(0xFFECECEC),
        borderRadius: msg["isMe"]
            ? const BorderRadius.only(
          topLeft: Radius.circular(100),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(100),
        )
            : const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(100),
          bottomRight: Radius.circular(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            msg["message"] ?? "",
            style: TextStyle(
              color: msg["isMe"] ? Colors.white : const Color(0xFF676565),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            msg["time"] ?? "",
            style: TextStyle(
              color: msg["isMe"] ? Colors.white70 : const Color(0xFF676565),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Image bubble
  Widget _buildImageMessage(Map<String, dynamic> msg) {
    final UserController userController = Get.find<UserController>();

    // Add base URL to media path
    final imageUrl = userController.addBaseUrl(msg["media"] ?? "");
    debugPrint("Image:=========> $imageUrl");
    return Column(
      crossAxisAlignment: msg["isMe"]
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
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
        Text(
          msg["time"] ?? "",
          style: const TextStyle(fontSize: 10, color: Color(0xFF676565)),
        ),
      ],
    );
  }

  /// Video bubble
  Widget _buildVideoMessage(Map<String, dynamic> msg) {
    final UserController userController = Get.find<UserController>();
    final videoUrl = userController.addBaseUrl(msg["media"] ?? "");
    debugPrint("Video:=========> $videoUrl");

    return FutureBuilder<File>(
      future: _downloadVideoToLocal(videoUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            width: 240,
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return Image.asset(
            "assets/images/receiver.jpg",
            height: 180,
            width: 240,
            fit: BoxFit.cover,
          );
        }

        final localVideo = snapshot.data!;

        return Column(
          crossAxisAlignment: msg["isMe"]
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            /// ==== Video Thumbnail with Play Button ====
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPreviewScreen(
                      videoUrl: localVideo.path, // pass local file
                      countdownSeconds: 3,
                      userProfile: image.toString(),
                      userName: widget.receiverName,
                    ),
                  ),
                );
              },
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
                      builder: (context, thumbSnap) {
                        if (thumbSnap.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            height: 180,
                            width: 240,
                            color: Colors.black12,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (!thumbSnap.hasData) {
                          return Image.asset(
                            "assets/images/receiver.jpg",
                            height: 180,
                            width: 240,
                            fit: BoxFit.cover,
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

                  /// Play Button Overlay
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF56BBFF),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            /// ==== Row with Time (left) & Save Button (right) ====
            InkWell(
              onTap: () async {
                await saveVideoToGallery(context, localVideo.path);
              },
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 60),
                  const Spacer(),

                  /// Save to Gallery (right)
                  SvgPicture.asset(
                    'assets/icons/download.svg',
                    color: const Color(0xFF56BBFF),
                    height: 20,
                    width: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Save to gallery",
                    style: TextStyle(fontSize: 14, color: Color(0xFF56BBFF)),
                  ),
                  const Spacer(),

                  /// Time (left)
                  Text(
                    msg["time"],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF676565),
                    ),
                  ),
                ],
              ),
            )

          ],
        );
      },
    );
  }

  Future<File> _downloadVideoToLocal(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File(
      "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4",
    );
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  /// Input bar
  Widget _buildInputBar() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            chatController.pickAndSendVideo();
          },
          child: SvgPicture.asset(
            'assets/icons/add_more.svg',
            color: const Color(0xFF56BBFF),
            height: 24,
            width: 24,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomTextField(
            controller: messageTextController,
            hintText: 'Type your message',
            borderSide: const BorderSide(color: Colors.transparent),
          ),
        ),
        InkWell(
          onTap: () {
            chatController.pickAndSendImage();
          },
          child: SvgPicture.asset(
            'assets/icons/camera.svg',
            height: 20,
            width: 20,
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: _sendMessage,
          child: SvgPicture.asset(
            'assets/icons/send.svg',
            color: const Color(0xFF56BBFF),
          ),
        ),
      ],
    );
  }
}
