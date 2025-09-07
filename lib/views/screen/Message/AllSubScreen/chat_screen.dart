import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/video_preview_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final List<Map<String, dynamic>> messages = [
    {
      "isMe": false,
      "type": "text",
      "message": "Hey, how are you doing today?",
      "time": "2.00 PM",
    },
    {
      "isMe": true,
      "type": "text",
      "message": "I'm good! Just got home from work. You?",
      "time": "2.00 PM",
    },
    {
      "isMe": false,
      "type": "video",
      "thumbnail": "assets/images/receiver.jpg",
      "time": "2.00 PM",
    },
    {
      "isMe": true,
      "type": "video",
      "thumbnail": "assets/images/sender.png",
      "overlayThumb": "assets/images/receiver.jpg",
      "time": "2.00 PM",
    },
    {
      "isMe": false,
      "type": "text",
      "message": "Niceee. Love the speed",
      "time": "2.00 PM",
    },
  ];

  final messageTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: (){
                      Get.back();
                    },
                    child: Icon(Icons.arrow_back,
                    color: Color(0xFF0D1C12),),
                  ),
                  SizedBox(width: 12,),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage("assets/images/dummy.jpg"),
                        fit: BoxFit.cover,
                      ),

                    ),
                  ),
                  SizedBox(width: 12,),
                  Text("Mr.John",
                  style: TextStyle(
                    color: Color(0xFF413E3E),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),)
                ],
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Align(
                      alignment:
                      msg["isMe"] ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: msg["type"] == "text"
                            ? _buildTextMessage(msg)
                            : _buildVideoMessage(msg),
                      ),
                    );
                  },
                ),
              ),

              /// ✅ Message Input
              _buildInputBar(),

            ],
          ),
        ),
      ),
    );
  }


  /// ✅ Text Message Bubble
  Widget _buildTextMessage(Map<String, dynamic> msg) {
    return Container(
      padding: EdgeInsets.all(12),
      constraints: BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: msg["isMe"] ? Color(0xFF9CC198) : Color(0xFFECECEC), // solid
        borderRadius: msg["isMe"]
            ? BorderRadius.only(
          topLeft: Radius.circular(100),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(100),
        )
            : BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(100),
          bottomRight: Radius.circular(100),
        ),
      ),
      child: Text(
        msg["message"],
        style: TextStyle(
          color: msg["isMe"] ? Colors.white : Color(0xFF676565),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }



  /// ✅ Video Message Bubble
  Widget _buildVideoMessage(Map<String, dynamic> msg) {
    return Column(
      crossAxisAlignment:
      msg["isMe"] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        /// Thumbnail with play button
        Stack(
          children: [
            InkWell(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VideoPreviewScreen(
                      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
                      countdownSeconds: 3,

                    ),
                  ),
                ).then((savedPath) {
                  if (savedPath is String && savedPath.isNotEmpty) {
                    debugPrint('Recorded front-cam file: $savedPath');
                  }
                });


              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: msg["isMe"]
                    ? Image.asset(
                  msg["thumbnail"],
                  height: 180,
                  width: 240,
                  fit: BoxFit.cover,
                )
                    : ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Image.asset(
                    msg["thumbnail"],
                    height: 180,
                    width: 240,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            /// Play button
            Positioned.fill(
              child: Center(
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF9CC198),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
                ),
              ),
            ),

            /// Sender overlay thumbnail
            if (msg["isMe"] && msg["overlayThumb"] != null)
              Positioned(
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    msg["overlayThumb"],
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),

        /// Bottom row
        SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 20,
              width: 20,
              child: SvgPicture.asset('assets/icons/download.svg'),
            ),
            SizedBox(width: 8),
            Text(
              "Save to gallery",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF799777),
              ),
            ),
            SizedBox(width: 77),
            Text(
              msg["time"],
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF676565),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }



  /// ✅ Bottom Input Bar
  Widget _buildInputBar() {
    return Row(

      children: [
      SvgPicture.asset('assets/icons/add_more.svg') ,
        SizedBox(width: 8,),
        Expanded(child: CustomTextField(
          controller: messageTextController,
          hintText: 'Type your message',
     suffixIcon: Padding(
       padding: const EdgeInsets.all(10.0),
       child: SvgPicture.asset('assets/icons/camera.svg'),
     ),
     borderSide: BorderSide(color: Colors.transparent),
        filColor: Color(0xFFE5F2E4),)),
        SizedBox(width: 8,),
        SvgPicture.asset('assets/icons/send.svg')

      ],
    );
  }

}
