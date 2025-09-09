import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_checkbox_screen.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

class SendMessageWithFriendScreen extends StatefulWidget {
  const SendMessageWithFriendScreen({super.key});

  @override
  State<SendMessageWithFriendScreen> createState() => _SendMessageWithFriendScreenState();
}

class _SendMessageWithFriendScreenState extends State<SendMessageWithFriendScreen> {
  final searchTextController = TextEditingController();

  bool isCheckbox = false;

  final List<Map<String, dynamic>> searchFriendList = [
    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg",
      "isInvite": false
    },
    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg",
      "isInvite": true
    },
    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg",
      "isInvite": false
    },
    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg",
      "isInvite": true
    },
    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg",
      "isInvite": false
    },
    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg",
      "isInvite": true
    },


    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg", //
      "isInvite": false// image story

    },
    {
      "name": "Mr. John",
      "image":"assets/images/dummy.jpg",
      "isInvite": true// image story

    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20,),
            Row(
              children: [
                InkWell(
                  onTap: (){
                    Get.back();
                  },
                    child: Icon(Icons.arrow_back, color: AppColors.textColor,)),
                SizedBox(width: 12,),
                Text("Send To",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),)
              ],
            ),
            SizedBox(height: 35,),
            CustomTextField(controller: searchTextController,
              borderColor: Colors.transparent,
              suffixIcon: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SvgPicture.asset('assets/icons/search.svg'),
              ),
              hintText: 'Search here',),
            SizedBox(height: 20,),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Select All",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),),

                  CustomCheckboxScreen(
                      value: isCheckbox,
                      onChanged: (val){
                        setState(() {
                          isCheckbox = val!;
                        });
                      })
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final item = searchFriendList[index];
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
                      SizedBox(width: 12,),
                      Text(item['name'],
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w400,
                      ),),
                      Spacer(),
                      CustomCheckboxScreen(
                          value: item['isInvite'],
                          onChanged: (val){
                            setState(() {
                              item['isInvite'] = val!;
                            });
                          })
                    ],
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemCount: searchFriendList.length,
              )
            ),

            CustomButton(onTap: (){},
                text: "Send Now")

          ],
        ),
      ),
    );
  }
}
