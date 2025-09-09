import 'package:flutter/material.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class CustomCheckboxScreen extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const CustomCheckboxScreen({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: (val) {
        onChanged(val ?? false);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
      activeColor: AppColors.primaryColor,
      checkColor: Colors.white,
    );
  }
}
