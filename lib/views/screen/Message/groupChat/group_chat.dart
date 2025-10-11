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
import '../../../../services/socket_manager.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/media_store.dart';
import '../../../base/custom_text_field.dart';
import 'group_details_screen.dart';
import '../AllSubScreen/AllSubScreen/video_preview_screen.dart';

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

  @override
  void initState() {
    super.initState();
    setData();
  }

  @override
  void dispose() {
    messageTextController.dispose();
    chatController.disconnect();
    super.dispose();
  }

  Future<void> setData() async {
    image = userController.addBaseUrl(widget.groupImage);
    currentUserId = userController.userInfo.value!.id;
    token = await SharedPrefsService.get('token');

    /// Initialize chat AFTER token + user fetched
    await chatController.initChat(
      chatId: widget.chatId,
      currentUserId: currentUserId!,
      token: token!,
    );
  }

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// Header
            _buildHeader(),

            /// Messages list
            Expanded(
              child: Obx(() {
                if (chatController.isLoading.value) {
                  return Center(child: SpinKitWave(color: AppColors.primaryColor, size: 30.0));
                }

                final msgs = chatController.messages;

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

            /// Input bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildInputBar(),
            ),
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
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.black100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: SvgPicture.asset('assets/icons/more.svg'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Message type dispatcher
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
          constraints: const BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: msg["isMe"] ? const Color(0xFF56BBFF) : const Color(0xFFECECEC),
            borderRadius: msg["isMe"]
                ? const BorderRadius.only(
              topLeft: Radius.circular(100),
              topRight: Radius.circular(100),
              bottomLeft: Radius.circular(100),
            )
                : const BorderRadius.only(
              topLeft: Radius.circular(100),
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
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          msg["time"] ?? "",
          style: TextStyle(
            color: msg["isMe"] ? const Color(0xFF676565) : const Color(0xFF676565),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage(Map<String, dynamic> msg) {
    final imageUrl = userController.addBaseUrl(msg["media"] ?? "");
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

  Widget _buildVideoMessage(Map<String, dynamic> msg) {
    final videoUrl = userController.addBaseUrl(msg["media"] ?? "");
    return FutureBuilder<File>(
      future: _downloadVideoToLocal(videoUrl.toString()),
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
          return const SizedBox.shrink();
        }

        final localVideo = snapshot.data!;
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPreviewScreen(
                videoUrl: localVideo.path,
                countdownSeconds: 3,
                userProfile: image ?? "",
                userName: widget.groupName,
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
                  builder: (context, thumbSnap) {
                    if (!thumbSnap.hasData) {
                      return Container(
                        height: 180,
                        width: 240,
                        color: Colors.black12,
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
                  shape: BoxShape.circle,
                  color: Color(0xFF56BBFF),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File> _downloadVideoToLocal(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file =
    File("${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4");
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Widget _buildInputBar() {
    return Row(
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
          child: CustomTextField(
            controller: messageTextController,
            hintText: 'Type your message',
            borderSide: const BorderSide(color: Colors.transparent),
          ),
        ),
        InkWell(
          onTap: () => chatController.pickAndSendImage(),
          child: SvgPicture.asset(
            'assets/icons/camera.svg',
            height: 20,
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
