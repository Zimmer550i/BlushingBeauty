import 'dart:convert';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  final api = ApiService();

  final RxBool isLoading = false.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  final RxInt currentPage = 1.obs;
  final RxInt totalPage = 1.obs;

  /// 🆕 Add a total notification count variable
  final RxInt totalNotificationCount = 0.obs;

  /// Fetch notifications with pagination
  Future<String> fetchNotifications({int page = 1, int limit = 10}) async {
    isLoading.value = true;
    try {
      final response = await api.get(
        "/notification/my-notifications",
        queryParams: {"page": page.toString(), "limit": limit.toString()},
        authReq: true,
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = body['data'] ?? [];
        final meta = body['meta'] ?? {};

        notifications.value =
            data.map((json) => NotificationModel.fromJson(json)).toList();

        currentPage.value = meta['page'] ?? 1;
        totalPage.value = meta['totalPage'] ?? 1;

        /// 🧮 Count and store total notifications
        totalNotificationCount.value = meta['totalItems'] ??
            notifications.length; // fallback if API doesn't return totalItems

        return "success";
      } else {
        return body['message'] ?? "Connection Error";
      }
    } catch (e) {
      return "Unexpected error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a notification and update count
  Future<String> deleteNotification(String id) async {
    try {
      final response = await api.delete("/notification/$id", authReq: true);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // remove from local list
        notifications.removeWhere((notif) => notif.id == id);

        /// 🧮 Update total count after deletion
        totalNotificationCount.value = notifications.length;

        return "success";
      } else {
        return body['message'] ?? "Failed to delete notification";
      }
    } catch (e) {
      return "Unexpected error: ${e.toString()}";
    }
  }
}
