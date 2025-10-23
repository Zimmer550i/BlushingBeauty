// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:ree_social_media_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactController extends GetxController {
  var matchedContacts = <Map<String, dynamic>>[].obs;
  var unmatchedContacts = <Map<String, dynamic>>[].obs;
  var filteredMatchedContacts = <Map<String, dynamic>>[].obs;
  var filteredUnmatchedContacts = <Map<String, dynamic>>[].obs;

  var isLoading = false.obs;
  final api = ApiService();

  /// Fetch contacts from device & send to API
  Future<void> fetchContacts() async {
  try {
    isLoading.value = true;

    if (await FlutterContacts.requestPermission()) {
      final rawContacts = await FlutterContacts.getContacts(withProperties: true);

      List<Map<String, dynamic>> contactList = [];
      int count = 0;
      const int maxContacts = 20;

      for (var c in rawContacts) {
        if (c.phones.isNotEmpty) {
          for (var phone in c.phones) {
            if (count >= maxContacts) break; // stop after 20
            final cleanedNumber = _normalizePhoneNumber(phone.number);
            contactList.add({
              "name": c.displayName,
              "phone": cleanedNumber,
            });
            count++;
          }
        }
        if (count >= maxContacts) break;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("saved_contacts", jsonEncode(contactList));

      await sendContactsToApi(contactList);
    }
  } catch (e) {
    debugPrint("🚨 Error fetching contacts: $e");
  } finally {
    isLoading.value = false;
  }
}


  String _normalizePhoneNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith("+")) {
      cleaned = "+1$cleaned"; // default country code
    }
    return cleaned;
  }

Future<void> sendInviteSms(BuildContext context, String number, String name) async {
  // 1️⃣ Create the message
  final message =
      "Join $name on re: The app that makes sharing photos and videos more fun by capturing real reactions. Download here - https://yourappdownloadlink.com";

  // 2️⃣ Encode the message for URI
  final encodedMessage = Uri.encodeComponent(message);

  // 3️⃣ Build the SMS URI
  final smsUri = Uri.parse('sms:$number?body=$encodedMessage');

  try {
    // 4️⃣ Launch the SMS app explicitly
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication, // Forces external SMS app
      );
    } else {
      // 5️⃣ Handle case when no SMS app is available
      debugPrint("❌ Could not launch SMS app. URI: $smsUri");
      _showErrorDialog(context, "No SMS app found on this device.");
    }
  } catch (e) {
    debugPrint("❌ Error launching SMS: $e");
    _showErrorDialog(context, "Failed to open SMS app.");
  }
}

// Helper function to show an error dialog
void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Error"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
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

        // Initially all contacts are shown
        filteredMatchedContacts.assignAll(matchedContacts);
        filteredUnmatchedContacts.assignAll(unmatchedContacts);

        debugPrint("✅ Matched Contacts: ${matchedContacts.length}");
        debugPrint("✅ Unmatched Contacts: ${unmatchedContacts.length}");
      } else {
        debugPrint("❌ Failed to upload contacts: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🚨 Error sending contacts: $e");
    }
  }

  /// 🔍 Search Function
  void filterContacts(String query) {
    if (query.isEmpty) {
      filteredMatchedContacts.assignAll(matchedContacts);
      filteredUnmatchedContacts.assignAll(unmatchedContacts);
    } else {
      final lower = query.toLowerCase();
      filteredMatchedContacts.assignAll(
        matchedContacts.where((c) =>
        (c["name"] ?? "").toLowerCase().contains(lower) ||
            (c["phone"] ?? "").toLowerCase().contains(lower)),
      );
      filteredUnmatchedContacts.assignAll(
        unmatchedContacts.where((c) =>
        (c["name"] ?? "").toLowerCase().contains(lower) ||
            (c["phone"] ?? "").toLowerCase().contains(lower)),
      );
    }
  }

Future<void> createPrivateChat(String memberId) async {
    isLoading.value = true;
    try {
      final response = await api.post(
        "/chat/create-private",
        {"member": memberId},
        authReq: true,
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatId = body['data']['_id'];
        debugPrint("✅ Private chat created with ID: $chatId");
      } else {
        debugPrint("⚠️ Failed: ${body['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error creating private chat: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
