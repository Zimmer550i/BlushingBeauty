import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

Future<void> saveVideoToGallery(BuildContext context, String filePath) async {
  final bool? result = await GallerySaver.saveVideo(filePath);

  if (result == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Video saved to gallery ✅")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to save video ❌")),
    );
  }
}
