import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Message/message_screen.dart';

class GetStartScreen extends StatefulWidget {
  const GetStartScreen({super.key});

  @override
  State<GetStartScreen> createState() => _GetStartScreenState();
}

class _GetStartScreenState extends State<GetStartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
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
              SizedBox(height: 45,),
              Text("You’re All Set!",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),),
              SizedBox(height: 12,),
              Text("Start sending moments and see real reactions",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),),
              SizedBox(height: 42,),
              Center(
                child: SvgPicture.asset('assets/icons/smail.svg'),
              ),
              SizedBox(height: 80,),
              CustomButton(onTap: (){
                Get.to(()=> MessageScreen());
              },
                  text: "Get Started")
            ],
          ),
        ),
      ),
    );
  }
}
