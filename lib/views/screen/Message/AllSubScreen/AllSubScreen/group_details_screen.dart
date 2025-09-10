import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_dropdown.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with TickerProviderStateMixin{
  bool showMembers = false;

  final List<Map<String, dynamic>> searchFriendList = [
    {"name": "Mr. John", "image": "assets/images/dummy.jpg"},
    {"name": "Ms. Alice", "image": "assets/images/dummy.jpg"},
    {"name": "Mr. Smith", "image": "assets/images/dummy.jpg"},
  ];
  final sendTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 30,),

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
                InkWell(
                  onTap: (){

                  },
                  child: Container(
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
            SizedBox(height: 24,),

            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage("assets/images/group_image.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF9CC198),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset('assets/icons/camera.svg',
                        color: Colors.white,),
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 50,),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF9CC198),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Change Group Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),),
                      Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.keyboard_arrow_up,
                        color: AppColors.primaryColor,),
                      )
                    ],
                  ),
                  SizedBox(height: 12,),
                  CustomTextField(controller: sendTextController,
                  hintText: 'Write here',),

                ],
              ),
            ),
            SizedBox(height: 24,),
            CustomDropdown(items: searchFriendList),
            SizedBox(height: 12,),
            InkWell(
              onTap: (){
                showDialog(
                    context: context,
                    builder: (context){
                      return AlertDialog(
                        backgroundColor: AppColors.primaryColor,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Are you sure you want to delete this chat?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,),
                            SizedBox(height: 30,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: (){
                                      Get.back();
                                    },
                                    child: Container(
                                      height: 52,
                                      width: 82,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Color(0xFFFFFFFF), width: 1)
                                      ),
                                      child: Center(
                                        child: Text("Yes",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),),
                                      ),
                                ))),
                                SizedBox(width: 24,),
                                Expanded(
                                    child: InkWell(
                                        onTap: (){
                                          Get.back();
                                        },
                                        child: Container(
                                          height: 52,
                                          width: 187,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                            color: Colors.white
                                          ),
                                          child: Center(
                                            child: Text("No",
                                              style: TextStyle(
                                                color: Color(0xFF676565),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),),
                                          ),
                                        ))),

                              ],
                            )
                          ],
                        ),
                      );
                    });
              },
              child: Text("Delete chat",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),),
            ),
            SizedBox(height: 12,),
            InkWell(
              onTap: (){
                showDialog(
                    context: context,
                    builder: (context){
                      return AlertDialog(
                        backgroundColor: AppColors.primaryColor,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Are you sure you want to leave this group?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,),
                            SizedBox(height: 30,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: InkWell(
                                        onTap: (){
                                          Get.back();
                                        },
                                        child: Container(
                                          height: 52,
                                          width: 82,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Color(0xFFFFFFFF), width: 1)
                                          ),
                                          child: Center(
                                            child: Text("Yes",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),),
                                          ),
                                        ))),
                                SizedBox(width: 24,),
                                Expanded(
                                    child: InkWell(
                                        onTap: (){
                                          Get.back();
                                        },
                                        child: Container(
                                          height: 52,
                                          width: 187,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              color: Colors.white
                                          ),
                                          child: Center(
                                            child: Text("No",
                                              style: TextStyle(
                                                color: Color(0xFF676565),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),),
                                          ),
                                        ))),

                              ],
                            )
                          ],
                        ),
                      );
                    });
              },
              child: Text("Leave chat",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),),
            )

          ],
        ),
      ),
    );
  }
}


