import 'package:flutter/material.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return  SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: AppColors.primaryColor),
    );
  }
}
