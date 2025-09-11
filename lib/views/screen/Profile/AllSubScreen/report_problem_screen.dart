import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
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
                  InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Icon(Icons.arrow_back, color: Color(0xFF0D1C12))),
                  SizedBox(width: 15),
                  Text(
                    "Report a Problem",
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
                            child: SvgPicture.asset('assets/icons/lock.svg'),
                          )
                      ),
                    ),),
                  SizedBox(height: 16,),
                  CustomTextField(
                    controller: passwordTextController,
                    hintText: 'Enter your phone number',
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
                    hintText: 'Enter your email',
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
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFC4C3C3),
                      width: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Comment",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF676565)
                        ),),
                        SizedBox(height: 8,),
                        CustomTextField(controller: passwordTextController,
                        filColor: Color(0xFFE5F2E4),
                        maxLines: 3,
                        hintText: 'Write your comment ',)
                      ],
                    ),
                  ),
                  SizedBox(height: 91,),
                  CustomButton(onTap: (){},
                      text: "Submit Now")

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
