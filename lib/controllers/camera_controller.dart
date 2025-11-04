import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:ree_social_media_app/helpers/route.dart';
import '../models/multi_body.dart';
import '../services/api_service.dart';

class CreateStoryController extends GetxController {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  var isLoading = false.obs;

  /// Add story with optional image/video paths
  Future<void> addStory({String? imagePath, String? videoPath}) async {
    isLoading.value = true;
    try {
      String? mediaType;
      File? mediaFile;

      // 🟢 Step 1: Determine media type and file source
      if (imagePath != null) {
        mediaType = 'image';
        mediaFile = File(imagePath);
      } else if (videoPath != null) {
        mediaType = 'video';
        mediaFile = File(videoPath);
      } else {
        // If no path provided → show picker
        mediaType = await _showMediaPickerSheet();
        if (mediaType == null) return;

        XFile? pickedFile;
        if (mediaType == 'image') {
          pickedFile = await _picker.pickImage(source: ImageSource.gallery);
        } else {
          pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
        }

        if (pickedFile == null) return;
        mediaFile = File(pickedFile.path);
      }

      if (!(await mediaFile.exists())) {
        isLoading.value = false;
        Get.snackbar("Error", "No valid media file selected.");
        return;
      }

      // 🟣 Step 2: Ensure .mp4 for videos
      if (mediaType == 'video') {
        mediaFile = await _ensureMp4Format(mediaFile);
      }

      // 🟢 Step 3: Upload story to API
      await _uploadStoryMedia(mediaFile, mediaType);
      
      Get.offAndToNamed(AppRoutes.messageScreen);

    } catch (e) {
      debugPrint("❌ Error creating story: $e");
      Get.snackbar(
        "Error",
        "Something went wrong while uploading story.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: .2),
      );
    }finally{
      isLoading.value = false;
    }
  }

  /// 🧱 Media picker bottom sheet
  Future<String?> _showMediaPickerSheet() async {
    return await Get.bottomSheet<String>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Add Image Story'),
              onTap: () => Get.back(result: 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.deepPurple),
              title: const Text('Add Video Story'),
              onTap: () => Get.back(result: 'video'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.redAccent),
              title: const Text('Cancel'),
              onTap: () => Get.back(result: null),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧩 Ensure video file uses .mp4 extension
  Future<File> _ensureMp4Format(File file) async {
    final currentExt = p.extension(file.path).toLowerCase();
    if (currentExt == '.mp4') return file;

    final newPath = p.setExtension(file.path, '.mp4');
    final newFile = await file.copy(newPath);

    debugPrint('🎥 Renamed video to .mp4 → $newPath');
    return newFile;
  }

  /// 📤 Upload story (image or video)
  Future<void> _uploadStoryMedia(File file, String type) async {
    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      debugPrint('📡 Uploading $type with MIME type: $mimeType');

      // Build multipart body for ApiService
      final multipartBody = [
        MultipartBody(key: type, file: file),
      ];

      final response = await _api.postMultipartData(
        "/story/create-story",
        {}, // You can add text fields like {"caption": "Nice view!"}
        multipartBody: multipartBody,
        authReq: true,
      );

      debugPrint("📥 Server Response: ${response.statusCode}");
      debugPrint("📦 Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // final resData = jsonDecode(response.body);
        // Get.snackbar(
        //   "✅ Success",
        //   resData['message'] ?? "Story uploaded successfully!",
        //   snackPosition: SnackPosition.BOTTOM,
        // );

      } else {
        // Handle backend validation error (Zod or server message)
        try {
          final resData = jsonDecode(response.body);
          Get.snackbar(
            "Upload Failed",
            resData['message'] ?? "Server rejected upload.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withValues(alpha: .2),
          );
        } catch (_) {
          Get.snackbar(
            "Upload Failed",
            "Server error: ${response.statusCode}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withValues(alpha: .2),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Exception during upload: $e");
      Get.snackbar(
        "Error",
        "Could not upload story. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: .2),
      );
    }
  }



}
