import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ree_social_media_app/views/screen/Message/message_screen.dart';
import '../services/api_service.dart';
import '../models/multi_body.dart';

class GroupChatController extends GetxController {
  final ApiService _apiService = ApiService();

  var groupName = "".obs;
  var groupImage = "".obs;
  var members = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  /// Fetch groupChat details
  Future<void> fetchGroupDetails(String chatId) async {
    try {
      isLoading.value = true;
      final res = await _apiService.get("/chat/group-chat/$chatId", authReq: true);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)["data"];
        groupName.value = data["name"] ?? "";
        groupImage.value = ApiService.getImgUrl(data["image"]) ?? "";
        members.value = List<Map<String, dynamic>>.from(data["members"]);
      } else {
        Get.snackbar("Error", "Failed to fetch groupChat details");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Update groupChat name/image
  Future<String> updateGroup(
      String chatId, {
        String? name,
        File? image,
      }) async {
    isLoading.value = true;
    try {
      final body = {
        "name": name ?? groupName.value,
      };

      final multipartBody = <MultipartBody>[];
      if (image != null) {
        multipartBody.add(
          MultipartBody(
            key: "image",
            file: image,
          ),
        );
      }

      http.Response response;

      if (multipartBody.isNotEmpty) {
        // multipart update with file
        response = await _apiService.patchMultipartData(
          "/chat/update-groupChat/$chatId",
          body,
          multipartBody: multipartBody,
          authReq: true,
        );
      } else {
        // normal patch
        response = await _apiService.patch(
          "/chat/update-groupChat/$chatId",
          body,
          authReq: true,
        );
      }

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);

        // ✅ Update local state
        groupName.value = resBody['data']['name'];
        groupImage.value = resBody['data']['image'];

        await fetchGroupDetails(chatId);

        isLoading.value = false;
        return "success";
      } else {
        final resBody = jsonDecode(response.body);
        isLoading.value = false;
        return resBody['message'] ?? "Connection Error";
      }
    } catch (e) {
      isLoading.value = false;
      return "Unexpected error: ${e.toString()}";
    }
  }

  /// Add members to a group chat
  Future<String> addMembersToGroup({
    required String chatId,
    required List<String> newMembers,
  }) async {
    isLoading.value = true;
    try {
      final body = {
        "chatId": chatId,
        "newMembers": newMembers,
      };

      final response = await _apiService.post(
        "/chat/add-members",
        body,
        authReq: true,
      );

      final resBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "success";
      } else {
        return resBody['message'] ?? "Failed to add members ❌";
      }
    } catch (e) {
      return "Unexpected error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }


  /// Leave groupChat
  Future<void> leaveGroup(String chatId) async {
    try {
      isLoading.value = true;
      final res = await _apiService.post("/chat/leave-groupChat", {"chatId": chatId}, authReq: true);
      if (res.statusCode == 200) {
        Get.snackbar("Success", "You left the groupChat");
        Get.back(); // Go back after leaving
      } else {
        Get.snackbar("Error", "Failed to leave groupChat");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete groupChat
  Future<void> deleteGroup(String chatId) async {
    try {
      isLoading.value = true;
      final res = await _apiService.delete("/chat/groupChat-chat/$chatId", authReq: true);
      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.snackbar("Success", "Group deleted successfully");
        Get.offAll(()=>MessageScreen());
      } else {
        Get.snackbar("Error", "Failed to delete groupChat");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.post(
        "/chat/remove-member",
        {
          "memberId": memberId,
          "groupId": groupId,
        },
        authReq: true,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Refresh groupChat details after removal
        fetchGroupDetails(groupId);
        return "success";
      } else {
        final body = jsonDecode(response.body);
        Get.snackbar("Error", body['message'] ?? "Failed to remove member");
        return null;
      }
    } catch (e) {
      debugPrint(e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

}
