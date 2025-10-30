import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoUtils {
  static Future<String?> getCachedThumbnail(String videoUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = videoUrl.hashCode.toString(); // unique cache name
      final thumbPath = "${tempDir.path}/$fileName.jpg";

      final thumbFile = File(thumbPath);

      if (await thumbFile.exists()) {
        // ✅ Return cached thumbnail
        return thumbFile.path;
      }

      // ❌ If not cached → generate and save
      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 0,
      maxWidth: 0,
      quality: 100,
        thumbnailPath: thumbPath,
      );

      return generatedPath;
    } catch (e) {
      debugPrint("Thumbnail error: $e");
      return null;
    }
  }
}
