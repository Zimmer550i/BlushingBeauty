// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

Future<void> saveVideoToGallery(
  BuildContext context,
  String filePath,
  bool isImaege,
) async {
  final bool? result;
  if (isImaege) {
    result = await GallerySaver.saveImage(filePath);
  } else {
    result = await GallerySaver.saveVideo(filePath);
  }

  if (result == true && !isImaege) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Video saved to gallery ✅")));
  } else if (result == true && isImaege) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Image saved to gallery ✅")));
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Failed to save ❌")));
  }
}
