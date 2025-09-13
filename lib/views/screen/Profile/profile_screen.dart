import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_switch.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/about_us_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/change_password_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/edit_profile_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/privacy_policy_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/report_problem_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/AllSubScreen/terms_of_service_screen.dart';

import '../../base/bottom_menu..dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  bool isSwitch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF56BBFF),
                      Color(0xFFFFFFFF),

                    ]
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(image: AssetImage('assets/images/dummy.jpg'),
                                  fit: BoxFit.cover)
                          ),
                        ),
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
                    SizedBox(height: 4,),
                    Text("Sophia Carter",
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,

                    ),),
                    SizedBox(height: 4,),
                    Text("01772968989",
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),),
                    SizedBox(height: 4,),
                    Text("SophiaCarter123@gmail.com",
                    style: TextStyle(
                      color: Color(0xFF0957AA),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,

                    ),)
                  ],
                ),
              ),
              SizedBox(height: 41,),

              Row(
                children: [
                  SvgPicture.asset('assets/icons/notification_fill.svg'),
                  SizedBox(width: 13,),
                  Text("Push Notifications",
                  style: TextStyle(
                    color: Color(0xFF676565),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),),
                  Spacer(),
                CustomSwitch(
                    value: isSwitch,
                    onChanged: (val){
                      setState(() {
                        isSwitch = val;
                      });
                    })

                ],
              ),
              SizedBox(height: 18,),
              _customRow(
                onTap: (){
                  Get.to(()=> EditProfileScreen());
                },
                imagePath: 'assets/icons/personal.svg',
                title: 'Change Personal Information'
              ),
              SizedBox(height: 17,),
              _customRow(
                  onTap: (){
                    Get.to(()=> ChangePasswordScreen());
                  },
                  title: 'Change Password',
                  imagePath: 'assets/icons/change_password.svg'),
              SizedBox(height: 17,),
              _customRow(
                  onTap: (){
                    showDialog(
                        context: context,
                        builder: (context){
                          return AlertDialog(
                            backgroundColor: Color(0xFFC4C3C3),
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Are you sure you want to delete your account?",
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
                  title: 'Delete my account',
                  imagePath: 'assets/icons/delete.svg'),
              SizedBox(height: 17,),
              _customRow(
                  onTap: (){
                    Get.to(()=> ReportProblemScreen());
                  },
                  title: 'Report a Problem',
                  imagePath: 'assets/icons/report.svg'),
              SizedBox(height: 17,),
              _customRow(
                  onTap: (){
                    Get.to(()=> TermsOfServiceScreen());
                  },
                  title: 'Terms of service',
                  imagePath: 'assets/icons/terms.svg'),
              SizedBox(height: 17,),
              _customRow(
                  onTap: (){
                    Get.to(()=> PrivacyPolicyScreen());
                  },
                  title: 'Privacy Policy',
                  imagePath: 'assets/icons/privacy.svg'),
              SizedBox(height: 17,),
              _customRow(
                  onTap: (){
                    Get.to(()=> AboutUsScreen());
                  },
                  title: 'About',
                  imagePath: 'assets/icons/about.svg'),
              SizedBox(height: 17,),

              InkWell(
                onTap: (){

                  showDialog(
                      context: context,
                      builder: (context){
                        return AlertDialog(
                          backgroundColor: Color(0xFFC4C3C3),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Are you sure you want to log out?",
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
                child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/logout.svg'),
                    SizedBox(width: 13,),
                    Text("Logout",
                    style: TextStyle(
                      color: Color(0xFFF04B4C),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),),


                  ],
                ),
              )


            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomMenu(3),
    );
  }

   Widget _customRow({
    required String title,
     required String imagePath,
     required Function()? onTap
}) {
    return InkWell(
      onTap: onTap,
      child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(imagePath),
                  SizedBox(width: 13,),
                  Text(title,
                    style: TextStyle(
                      color: Color(0xFF676565),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF799777),)

                ],
              ),
    );
  }
}
