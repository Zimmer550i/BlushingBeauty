import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {

  final nameTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(
                    "4 of 4",
                    style: TextStyle(
                      color: Color(0xFF413E3E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 45,),
              Text("Set Up Your \nProfile",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),),
              SizedBox(height: 12,),
              Text("Add your details so friends can recognize you",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),),
              SizedBox(height: 30,),
              Center(
                child: Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: AssetImage('assets/images/demo.png'),
                    fit: BoxFit.cover)
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
              SizedBox(height: 20,),
              CustomTextField(controller: nameTextController,
                hintText: 'Enter your birthday',
                borderSide: BorderSide(color: Color(0xFFC4C3C3),
                    width: 1),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SvgPicture.asset('assets/icons/calender.svg'),
                ),
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
                        child: SvgPicture.asset('assets/icons/birth.svg'),
                      )
                  ),
                ),),
              SizedBox(height: 80,),
              CustomButton(onTap: (){},
                  text: "Save")
            ],
          ),
        ),
      ),
    );
  }
}
