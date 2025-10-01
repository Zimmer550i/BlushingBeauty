import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserController extends GetxController {
  final userInfo = Rxn<User>();
  final api = ApiService();
  final RxnString privacyPolicy = RxnString();
  final RxInt unreadNotifications = RxInt(0);
  final notificationRefreshTime = Duration(minutes: 10);

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
      debugPrint("User Info:====> ${json}");
    }
  }

  Future<String> updateInfo({
    required String name,
    File? image,
  }) async {
    isLoading.value = true;
    try {
      // Build payload correctly
      final payload = {
        "data": jsonEncode({
          "name": name,
        }),
        if (image != null) "image": image,
      };

      final response = await api.patch(
        "/user/update-profile",
        payload,
        authReq: true,
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

  String? getImageUrl() {
    if (userInfo.value == null || userInfo.value!.image == null) {
      return null;
    }

    String baseUrl = api.devUrl;

    return baseUrl + userInfo.value!.image!;
  }


}