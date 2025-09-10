import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  final nameTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: (){
                  Get.back();
                },
                    icon: Icon(Icons.arrow_back, color: AppColors.textColor,)),
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
                )

              ],
            ),

          SizedBox(height: 45,),
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child:   Column(
              children: [
                Center(
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: AssetImage('assets/images/circle.png'))
                    ),
                    child: Stack(
                      children: [
                        Container(
                          height: 155,
                          width: 155,
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(image: AssetImage('assets/images/dummy.jpg'),
                            fit: BoxFit.cover)
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40,),
                CustomTextField(controller: nameTextController,
                  hintText: 'Enter your name',
                  borderSide: BorderSide(color: Color(0xFFC4C3C3),
                      width: 1),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor
                        ),
                        child:Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SvgPicture.asset('assets/icons/name_fill.svg'),
                        )
                    ),
                  ),),
                SizedBox(height: 80,),
                CustomButton(onTap: (){},
                    text: "Save")
              ],
            ),
          )

          ],
        ),
      ),
    );
  }
}
