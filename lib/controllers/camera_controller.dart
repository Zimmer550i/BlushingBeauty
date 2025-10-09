import 'dart:convert';
import 'package:get/get.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/multi_body.dart';
import '../services/api_service.dart';

class CreateStoryController extends GetxController{
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  Future<void> addStory({String? imagePath, String? videoPath}) async {
    try {
      String? mediaType;
      File? mediaFile;

      // 🟢 Step 1: Decide media type
      if (imagePath != null) {
        mediaType = 'image';
        mediaFile = File(imagePath);
      } else if (videoPath != null) {
        mediaType = 'video';
        mediaFile = File(videoPath);
      } else {
        // 🟡 If no path is provided, show bottom sheet for user to pick
        mediaType = await Get.bottomSheet<String>(
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

        if (mediaType == null) return;

        // 🟢 Step 2: Pick from gallery if not provided
        XFile? pickedFile;
        if (mediaType == 'image') {
          pickedFile = await _picker.pickImage(source: ImageSource.gallery);
        } else {
          pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
        }

        if (pickedFile == null) return;
        mediaFile = File(pickedFile.path);
      }

      // 🟢 Step 3: Upload story
      await _uploadStoryMedia(mediaFile, mediaType);

    } catch (e) {
      debugPrint("❌ Error creating story: $e");
      Get.snackbar(
        "Error",
        "Something went wrong while uploading story.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.2),
      );
    }
  }

  /// Upload media file (image/video)
  Future<void> _uploadStoryMedia(File file, String type) async {
    try {
      final multipartBody = [MultipartBody(key: type, file: file)];
      final response = await _api.postMultipartData(
        "/story/create-story",
        {},
        multipartBody: multipartBody,
        authReq: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        Get.snackbar(
          "Success",
          "Your ${resData['message']}",
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        debugPrint("❗ Upload failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Exception during upload: $e");
    }
  }

}