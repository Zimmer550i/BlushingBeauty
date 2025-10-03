import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/services/shared_prefs_service.dart';
import 'package:ree_social_media_app/services/socket_manager.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/group_details_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String currentUserId;
  const ChatScreen({super.key, required this.chatId, required this.receiverName, required this.currentUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> messages = [];
  final messageTextController = TextEditingController();
  String? token;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  Future<void> _initUserData() async {
    token = await SharedPrefsService.get('token');
    if (token != null) {
      SocketService.connect(token!);

      SocketService.socket!.on("receive-message", (data) {
        setState(() {
          messages.add({
            "isMe": data["sender"] == widget.currentUserId,
            "type": data["contentType"],
            "message": data["message"],
            "time": DateTime.now().toString().substring(11, 16),
          });
        });
      });
    }
  }

  @override
  void dispose() {
    SocketService.disconnect();
    messageTextController.dispose();
    super.dispose();
  }
  /// ✅ Send message handler
  void _sendMessage() {
    final text = messageTextController.text.trim();

    if (text.isNotEmpty) {
      SocketService.sendText(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        message: text,
      );

      setState(() {
        messages.add({
          "isMe": true,
          "type": "text",
          "message": text,
          "time": DateTime.now().toString().substring(11, 16),
        });
      });

      messageTextController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              /// 🔹 Header
              Row(
                children: [
                  InkWell(onTap: () => Get.back(), child: const Icon(Icons.arrow_back, color: Color(0xFF0D1C12))),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => Get.to(() => GroupDetailsScreen()),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage("assets/images/dummy.jpg"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(widget.receiverName,
                      style: const TextStyle(color: Color(0xFF413E3E), fontSize: 24, fontWeight: FontWeight.w600)),
                ],
              ),

              /// 🔹 Messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Align(
                      alignment: msg["isMe"] ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _buildMessage(msg),
                      ),
                    );
                  },
                ),
              ),

              /// 🔹 Input
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Render message by type
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

  /// ✅ Text bubble
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
      child: Text(
        msg["message"] ?? "",
        style: TextStyle(
          color: msg["isMe"] ? Colors.white : const Color(0xFF676565),
          fontSize: 16,
        ),
      ),
    );
  }

  /// ✅ Image bubble
  Widget _buildImageMessage(Map<String, dynamic> msg) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        msg["media"] ?? "",
        height: 180,
        width: 240,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset("assets/images/receiver.jpg", height: 180, width: 240),
      ),
    );
  }

  /// ✅ Video bubble
  Widget _buildVideoMessage(Map<String, dynamic> msg) {
    return Column(
      crossAxisAlignment: msg["isMe"] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icons/download.svg', color: const Color(0xFF56BBFF), height: 20, width: 20),
            const SizedBox(width: 8),
            const Text("Save to gallery", style: TextStyle(fontSize: 14, color: Color(0xFF56BBFF))),
            const Spacer(),
            Text(msg["time"], style: const TextStyle(fontSize: 12, color: Color(0xFF676565))),
          ],
        ),
      ],
    );
  }

  /// ✅ Input bar
  Widget _buildInputBar() {
    return Row(
      children: [
        SvgPicture.asset('assets/icons/add_more.svg', color: const Color(0xFF56BBFF)),
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
          child: SvgPicture.asset('assets/icons/send.svg', color: const Color(0xFF56BBFF)),
        ),
      ],
    );
  }
}
