import 'package:flutter/material.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/statusbar_color.dart';

class OnboardScreen3 extends StatefulWidget {
  const OnboardScreen3({super.key});

  @override
  State<OnboardScreen3> createState() => _OnboardScreen3State();
}

class _OnboardScreen3State extends State<OnboardScreen3> {

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
                  Text("3 of 3",
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
                      image: DecorationImage(image: AssetImage('assets/images/share2.png'))
                  ),
                ),
              ),

              SizedBox(height: 40,),
              Center(
                child: Text("Control What You Share",
                  style: TextStyle(
                    color: Color(0xFF413E3E),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,),
              ),
              SizedBox(height: 16,),
              Text("Reactions stay private in 1-to-1 or groupChat chats, unless you decide to share",
                style: TextStyle(
                  color: Color(0xFF676565),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,),
              SizedBox(height: 40,),


              Center(
                child: InkWell(
                  onTap: (){
                    
                  },
                  child: Container(
                    width: 200,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF56BBFF),
                          Color(0xFFFFFFFF)
                        ]
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 1,
                          spreadRadius: 0,
                          color: Color(0xFF002329).withValues(alpha: 0.7),
                          offset: Offset(0, 0),

                        )
                      ]
                    ),
                    child: Center(
                      child: Text("Get Started",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),),
                    ),
                  ),
                ),
              ),





            ],
          ),
        ),
      ),
    );
  }
}
