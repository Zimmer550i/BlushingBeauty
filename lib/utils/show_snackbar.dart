import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_colors.dart';

void showSnackBar(String message, bool isError) {
  Get.snackbar(
    isError ? 'Error' : 'Success',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: isError ? Colors.red.shade600 : AppColors.primaryColor,
    colorText: Colors.black,
    borderRadius: 12,
    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    animationDuration: Duration(milliseconds: 300),
    duration: Duration(seconds: 3),
    icon: Icon(
      isError ? Icons.error_outline : Icons.check_circle_outline,
      color: Colors.black,
    ),
    forwardAnimationCurve: Curves.easeOut,
    reverseAnimationCurve: Curves.easeIn,
  );
}
