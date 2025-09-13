import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/statusbar_color.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Splash/Onboard/onboard_screen3.dart';

class OnboardScreen2 extends StatefulWidget {
  const OnboardScreen2({super.key});

  @override
  State<OnboardScreen2> createState() => _OnboardScreen2State();
}

class _OnboardScreen2State extends State<OnboardScreen2> {

  @override
  void initState() {
    systemStatusBar();
    super.initState();
  }

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
                  Text("2 of 3",
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
                child: Container(
                  height: 114,
                  width: 114,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFECECEC).withValues(alpha: 0.50),
                    image: DecorationImage(image: AssetImage('assets/images/comment2.png'))
                  ),
                ),
              ),

              SizedBox(height: 40,),
              Center(
                child: Text("See Real Reactions \nin Real Time",
                  style: TextStyle(
                    color: Color(0xFF413E3E),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,),
              ),
              SizedBox(height: 16,),

              RichText(
                textAlign: TextAlign.center,
                  text: TextSpan(
                children: [
                  TextSpan(
                    text: "When your media is revealed",
                    style: TextStyle(
                      color: Color(0xFF676565),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    )
                  ),
                  TextSpan(
                    text: " re:",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    )
                  ),
                  TextSpan(
                      text: " captures genuine reactions instantly",
                      style: TextStyle(
                        color: Color(0xFF676565),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      )
                  ),
                ]
              )),

              // Text("When your media is revealed, re: captures genuine reactions instantly",
              //   style: TextStyle(
              //     color: Color(0xFF676565),
              //     fontSize: 16,
              //     fontWeight: FontWeight.w400,
              //   ),
              //   textAlign: TextAlign.center,),
              SizedBox(height: 40,),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: CustomButton(onTap: (){
                  Get.to(()=> OnboardScreen3());
                }, text: "Next"),
              )


            ],
          ),
        ),
      ),
    );
  }
}
