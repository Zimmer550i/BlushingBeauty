import 'package:flutter/material.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class ReBack extends StatelessWidget {
  final VoidCallback onTap;
  const ReBack({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}
