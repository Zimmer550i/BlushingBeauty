import 'dart:convert';
import 'package:get/get.dart';
import '../services/api_service.dart';

class ProfileController extends GetxController {
  final api = ApiService();
  final RxBool isLoading = false.obs;
  final RxnString termsOfService = RxnString();

  Future<String> getTermsOfService(String endPoint) async {
    isLoading.value = true;
    try {
      final response = await api.get(endPoint, authReq: true);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = body['data'];
        if (data is List && data.isNotEmpty) {
          termsOfService.value = data[0]['description']?.toString();
        } else {
          termsOfService.value = "No content available.";
        }
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
}
