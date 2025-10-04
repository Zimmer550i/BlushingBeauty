import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:ree_social_media_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactController extends GetxController {
  var matchedContacts = <Map<String, dynamic>>[].obs;
  var unmatchedContacts = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  final api = ApiService();

  /// Fetch contacts from device & send to API
  Future<void> fetchContacts() async {
    try {
      isLoading.value = true;

      if (await FlutterContacts.requestPermission()) {
        final rawContacts = await FlutterContacts.getContacts(withProperties: true);

        List<Map<String, dynamic>> contactList = [];

        for (var c in rawContacts) {
          if (c.phones.isNotEmpty) {
            for (var phone in c.phones) {
              final cleanedNumber = _normalizePhoneNumber(phone.number);

              contactList.add({
                "name": c.displayName,
                "phone": cleanedNumber,
              });
            }
          }
        }

        // Save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("saved_contacts", jsonEncode(contactList));

        // ✅ Send contacts to API
        await sendContactsToApi(contactList);
      }
    } catch (e) {
      debugPrint("🚨 Error fetching contacts: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Normalize phone number
  String _normalizePhoneNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith("+")) {
      cleaned = "+1$cleaned"; // default country code
    }
    return cleaned;
  }

  /// Send invite via SMS
  Future<void> sendInviteSms(String number, String name) async {
    final message =
        "$name wants to connect with you on re: The app that makes sharing photos and videos more fun! Download here: https://yourappdownloadlink.com";

    final smsUri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      debugPrint("❌ Could not launch SMS app. URI: $smsUri");
    }
  }

  /// Send contacts to backend
  Future<void> sendContactsToApi(List<Map<String, dynamic>> contactList) async {
    try {
      final response = await api.postRaw(
        "/user/contact",
        contactList,
        authReq: true,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        matchedContacts.assignAll(List<Map<String, dynamic>>.from(decoded["data"]["match"]));
        unmatchedContacts.assignAll(List<Map<String, dynamic>>.from(decoded["data"]["unmatch"]));

        debugPrint("✅ Matched Contacts: ${matchedContacts.length}");
        debugPrint("✅ Unmatched Contacts: ${unmatchedContacts.length}");
      } else {
        debugPrint("❌ Failed to upload contacts: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🚨 Error sending contacts: $e");
    }
  }
}
