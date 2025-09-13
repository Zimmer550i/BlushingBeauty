import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Splash/Onboard/onboard_screen2.dart';

class OnboardScreen1 extends StatefulWidget {
  const OnboardScreen1({super.key});

  @override
  State<OnboardScreen1> createState() => _OnboardScreen1State();
}

class _OnboardScreen1State extends State<OnboardScreen1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// logo and text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 36,
                    width: 45,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text("re:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),),
                    ),
                  ),
                  Text("1 of 3",
                  style: TextStyle(
                    color: Color(0xFF413E3E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryColor
                  ),)
                ],
              ),
              SizedBox(height: 90,),
              Center(
                child: Image.asset('assets/images/camera2.png'),
              ),
              SizedBox(height: 40,),
              Center(
                child: Text("Capture &\n Share Moments",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,),
              ),
              SizedBox(height: 16,),
              Text("Send photo and video that stays blurred until the countdown reveal",
              style: TextStyle(
                color: Color(0xFF676565),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,),
              SizedBox(height: 40,),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: CustomButton(onTap: (){
                  Get.to(()=> OnboardScreen2());
                }, text: "Next"),
              )


            ],
          ),
        ),
      ),
    );
  }
}
