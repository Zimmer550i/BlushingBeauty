import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/user_controller.dart';
import 'package:ree_social_media_app/controllers/chat_controller.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/group_details_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';
import '../../../../services/shared_prefs_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String currentUserId;
  final String receiverImage;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.currentUserId,
    required this.receiverImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
                      child:
                      const Icon(Icons.arrow_back, color: Color(0xFF0D1C12))),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => Get.to(() => GroupDetailsScreen()),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(image.toString()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(widget.receiverName,
                      style: const TextStyle(
                          color: Color(0xFF413E3E),
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
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
          )
        ],
      ),
    );
  }

  /// Image bubble
  Widget _buildImageMessage(Map<String, dynamic> msg) {
    return Column(
      crossAxisAlignment:
      msg["isMe"] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            msg["media"] ?? "",
            height: 180,
            width: 240,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              "assets/images/receiver.jpg",
              height: 180,
              width: 240,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(msg["time"],
            style: const TextStyle(fontSize: 10, color: Color(0xFF676565))),
      ],
    );
  }

  /// Video bubble
  Widget _buildVideoMessage(Map<String, dynamic> msg) {
    return Column(
      crossAxisAlignment:
      msg["isMe"] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPreviewScreen(
                      videoUrl: msg["media"] ?? "",
                      countdownSeconds: 3,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/receiver.jpg",
                  height: 180,
                  width: 240,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF56BBFF),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icons/download.svg',
                color: const Color(0xFF56BBFF), height: 20, width: 20),
            const SizedBox(width: 8),
            const Text("Save to gallery",
                style: TextStyle(fontSize: 14, color: Color(0xFF56BBFF))),
            const Spacer(),
            Text(msg["time"],
                style: const TextStyle(fontSize: 12, color: Color(0xFF676565))),
          ],
        ),
      ],
    );
  }

  /// Input bar
  Widget _buildInputBar() {
    return Row(
      children: [
        SvgPicture.asset('assets/icons/add_more.svg',
            color: const Color(0xFF56BBFF)),
        const SizedBox(width: 8),
        Expanded(
          child: CustomTextField(
            controller: messageTextController,
            hintText: 'Type your message',
            suffixIcon: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SvgPicture.asset('assets/icons/camera.svg'),
            ),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _sendMessage,
          child: SvgPicture.asset('assets/icons/send.svg',
              color: const Color(0xFF56BBFF)),
        ),
      ],
    );
  }
}
