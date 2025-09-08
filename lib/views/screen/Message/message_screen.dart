import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/bottom_menu..dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/search_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/see_all_story_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/chat_screen.dart';
import 'package:ree_social_media_app/views/screen/Notification/notification_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {

  final List<Map<String, dynamic>> stories = [
    {
      "name": "Mr. John",
      "image":
      "assets/images/dummy.jpg", // image story
      "isVideo": false
    },
    {
      "name": "Mr. John",
      "image":
      "assets/images/dummy.jpg", // video story
      "isVideo": true
    },
    {
      "name": "Mr. John",
      "image":
      "assets/images/dummy.jpg", // image story
      "isVideo": false
    },
  ];

  final List<Map<String, dynamic>> chats = [
    {
      "name": "Mr. John",
      "image":
      "assets/images/dummy.jpg", // image story
      "message": "Hello, how are you?",
      "time": "10:30 AM",
      "active": false

    },

    {
      "name": "Mr. John",
      "image":
      "assets/images/dummy.jpg", // image story
      "message": "Hello, how are you?",
      "time": "10:30 AM",
      "active": true

    },
    {
      "name": "Mr. John",
      "image":
      "assets/images/dummy.jpg", // image story
      "message": "Hello, how are you?",
      "time": "10:30 AM",
      "active": false

    },
    {
      "name": "Mr. John",
      "image":
      "assets/images/dummy.jpg",
      "message": "Hello, how are you?",
      "time": "10:30 AM",
      "active": false

    },

  ];


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            /// ✅ Top Bar (Fixed)
            Row(
              children: [
                Container(
                  height: 36,
                  width: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "re:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFC4C3C3), width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: SvgPicture.asset('assets/icons/add.svg'),
                  ),
                ),
                SizedBox(width: 12),
                InkWell(
                  onTap: (){
                    Get.to(()=> SearchScreen());
                  },
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFC4C3C3), width: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: SvgPicture.asset('assets/icons/search.svg'),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Stack(
                  children: [
                    InkWell(
                      onTap: (){
                        Get.to(()=> NotificationScreen());
                      },
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFC4C3C3), width: 0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: SvgPicture.asset('assets/icons/notification.svg'),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF799777),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "1",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),

            /// ✅ Scrollable Part (Stories + Chats)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: (){
                        Get.to(()=> SeeAllStoryScreen());
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "See All",
                          style: TextStyle(
                            color: Color(0xFF413E3E),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    /// Stories
                    SizedBox(
                      height: 132,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: stories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildAddStoryCard();
                          } else {
                            var story = stories[index - 1];
                            return _buildStoryCard(
                              story["image"],
                              story["name"],
                              story["isVideo"],
                            );
                          }
                        },
                      ),
                    ),

                    SizedBox(height: 24),

                    Text(
                      "Chats",
                      style: TextStyle(
                        color: Color(0xFF413E3E),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    /// Chats
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: (){
                        Get.to(()=> ChatScreen());
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Profile
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(chats[index]["image"]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),

                          /// Name + Message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      chats[index]["name"],
                                      style: TextStyle(
                                        color: Color(0xFF676565),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    if (chats[index]["active"])
                                      Container(
                                        height: 10,
                                        width: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  chats[index]["message"],
                                  style: TextStyle(
                                    color: chats[index]["isVideo"] == true
                                        ? AppColors.primaryColor //
                                        : Color(0xFF676565),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// Time
                          Text(
                            chats[index]["time"],
                            style: TextStyle(
                              color: Color(0xFF807E7E),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                ],
                ),
              ),
            ),
          ],


        ),
      ),
      bottomNavigationBar: BottomMenu(0,messageCount: 1,),
    );
  }

  /// ✅ Add Story Card (নিজের story)
   Widget _buildAddStoryCard() {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 8),
      width: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFA5D6A7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5),
              decoration:  BoxDecoration(
                color: Color(0xFF9CC198).withValues(alpha: .90),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:  [
                  Text(
                    "Add Story",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 12,),
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SvgPicture.asset('assets/icons/camera.svg'),
                    ),
                  )



                ],
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              child: Image.asset(
                "assets/images/dummy.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),


        ],
      ),
    );
  }

  /// ✅ Story Card (image/video)
  Widget _buildStoryCard(String imageUrl, String name, bool isVideo) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8)
        ),
        image: DecorationImage(
          image: AssetImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [

          if (isVideo)
            Center(
              child: Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9CC198),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),



          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF000000).withValues(alpha: 0.42), // semi-transparent background

              ),
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
