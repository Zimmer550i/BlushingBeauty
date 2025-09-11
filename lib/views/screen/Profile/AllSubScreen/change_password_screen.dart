import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {

  final passwordTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.arrow_back, color: Color(0xFF0D1C12)),
                  SizedBox(width: 15),
                  Text(
                    "Change Password",
                    style: TextStyle(
                      color: Color(0xFF0D1C12),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(controller: passwordTextController,
                    hintText: 'Enter your Password',
                    isPassword: true,
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
                            child: SvgPicture.asset('assets/icons/lock.svg'),
                          )
                      ),
                    ),),
                  SizedBox(height: 16,),
                  CustomTextField(controller: passwordTextController,
                    hintText: 'Enter new password',
                    isPassword: true,
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
                            child: SvgPicture.asset('assets/icons/lock.svg'),
                          )
                      ),
                    ),),
                  SizedBox(height: 16,),
                  CustomTextField(controller: passwordTextController,
                    hintText: 'Confirm  Password',
                    isPassword: true,
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
                            child: SvgPicture.asset('assets/icons/lock.svg'),
                          )
                      ),
                    ),),
                  SizedBox(height: 91,),
                  CustomButton(onTap: (){},
                      text: "Save")

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
