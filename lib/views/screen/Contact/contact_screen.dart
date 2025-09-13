import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/bottom_menu..dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/Contact/create_group_screen.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {

  final searchTextController = TextEditingController();
  final List<Map<String, dynamic>> searchList = [
    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg", // image story
      "invite": "assets/icons/message.svg",
      "isInvite": false
    },
    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg",
      "invite": "assets/icons/message.svg",

      "isInvite": true
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24,),
            Text("Contact List",
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),),
            SizedBox(height: 24,),
            CustomTextField(controller: searchTextController,
              borderColor: Colors.transparent,
              suffixIcon: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SvgPicture.asset('assets/icons/search.svg'),
              ),
              hintText: 'Search here',),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final item = searchList[index];
                  return Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(item['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${item['name']}",
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      item['isInvite'] == true
                          ? SvgPicture.asset(item['invite'],
                        color: AppColors.primaryColor,)
                          : Container(
                        height: 38,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFC4C3C3),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF002329).withValues(alpha: 0.5),
                              spreadRadius: -1.25,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Invite",
                            style: TextStyle(
                              color: Color(0xFF676565),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemCount: searchList.length,
              ),
            ),
            CustomButton(
                onTap: (){
                  Get.to(()=> CreateGroupScreen());
                },
                text: "Create Group")

          ]
        ),
      ),
      bottomNavigationBar: BottomMenu(2),
    );
  }
}
