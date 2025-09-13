import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/story_details_screen.dart';

class SeeAllStoryScreen extends StatefulWidget {
  const SeeAllStoryScreen({super.key});

  @override
  State<SeeAllStoryScreen> createState() => _SeeAllStoryScreenState();
}

class _SeeAllStoryScreenState extends State<SeeAllStoryScreen> {

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
      "isVideo": true
    },
    {
      "name": "Mr. John",
      "image":
      "assets/images/dummy.jpg", // image story
      "isVideo": true
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
      "isVideo": true
    },
    {
      "name": "Mr. John",
      "image":
      "assets/images/dummy.jpg", // image story
      "isVideo": true
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              children: [
                InkWell(
                  onTap: (){
                    Get.back();
                  },
                    child: Icon(Icons.arrow_back, color: AppColors.textColor,)),
                SizedBox(width: 12),
                Text("All Stories",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),)
              ],
            ),
            SizedBox(height: 24),

            Expanded(

              child: GridView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                  gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9
                  ),
                  itemCount: stories.length,
                itemBuilder: (BuildContext context, int index) {
                    var story = stories[index];
                    return _buildStoryCard(
                      story["image"],
                      story["name"],
                      story["isVideo"],
                    );

                },
                  )),


          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(String imageUrl, String name, bool isVideo) {
    return InkWell(
      onTap: (){
        Get.to(()=> StoryDetailsScreen());
      },
      child: Container(
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
                    color: AppColors.primaryColor,
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
      ),
    );
  }
}
