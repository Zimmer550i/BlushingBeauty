import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/services/one_signal_manager.dart';
import '../models/all_user_model.dart';
import '../models/multi_body.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserController extends GetxController {
  final userInfo = Rxn<User>();
  final api = ApiService();
  final RxnString privacyPolicy = RxnString();
  final RxInt unreadNotifications = RxInt(0);
  final notificationRefreshTime = Duration(minutes: 10);
  var allUsers = <AllUserModel>[].obs;

  RxBool isLoading = RxBool(false);
  final RxBool isSubscribed = false.obs;

  Future<String> getInfo() async {
    isLoading.value = true;
    try {
      final response = await api.get("/user/profile", authReq: true);
      var body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setInfo(body['data']);
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        return body['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  void setInfo(Map<String, dynamic>? json) {
    if (json != null) {
      userInfo.value = User.fromJson(json);
      debugPrint("User Info:====> $json");
    }
  }

  Future<String> updateInfo({
    required String name,
    DateTime? dob,
    bool? hasDate,
    File? image,
  }) async {
    isLoading.value = true;
    try {
      final body = {"name": name, if (hasDate == true) "dob": dob};

      // Files go here
      final multipartBody = <MultipartBody>[];
      if (image != null) {
        multipartBody.add(MultipartBody(key: "image", file: image));
      }

      final response = await api.patchMultipartData(
        "/user/update-profile",
        body,
        authReq: true,
        multipartBody: multipartBody,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setInfo(body['data']);
        isLoading.value = false;
        return "success";
      } else {
        final body = jsonDecode(response.body);
        isLoading.value = false;
        return body['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  void setPlayerId() async {
    try {
      final playerId = OneSignalHelper.getPlayerId();

      final response = await api.post(
        "/user/player-id/$playerId",
        {},
        authReq: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("=========>Player ID set successfully");
      } else {
        debugPrint("=========>Failed to set player ID");
      }
    } catch (e) {
      debugPrint("=========>Error setting player ID: $e");
    }
  }

  String? getImageUrl() {
    if (userInfo.value == null || userInfo.value!.image == null) {
      return null;
    }

    return userInfo.value!.image!;
  }

  String? addBaseUrl(String image) {
    if (image.isEmpty) {
      return null;
    }
    return image;
  }

  Future<String> fetchAllUsers({int page = 1, int limit = 10}) async {
    isLoading.value = true;
    try {
      final response = await api.get(
        "/user/all-user?page=$page&limit=$limit",
        authReq: true,
      );
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = body['data'];
        allUsers.value = data.map((e) => AllUserModel.fromJson(e)).toList();
        isLoading.value = false;
        return "success";
      } else {
        isLoading.value = false;
        return body['message'] ?? "Failed to fetch users";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      isLoading.value = true;
      final response = await api.delete(
        '/story/delete/$storyId',
        authReq: true,
      );

      if (response.statusCode == 200) {
        debugPrint('🗑️ Story deleted successfully');
      } else {
        debugPrint('⚠️ Failed to delete story: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('❗ deleteStory Error: $e');
      throw Exception('Failed to delete the story. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
