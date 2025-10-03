import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactController extends GetxController {
  var contacts = <Map<String, dynamic>>[].obs; // name + number

  /// Fetch all contacts with name + phone number
  Future<void> fetchContacts() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final rawContacts = await FlutterContacts.getContacts(withProperties: true);

        List<Map<String, dynamic>> contactList = [];

        for (var c in rawContacts) {
          if (c.phones.isNotEmpty) {
            for (var phone in c.phones) {
              final cleanedNumber = _normalizePhoneNumber(phone.number);

              contactList.add({
                "name": c.displayName,
                "number": cleanedNumber,
              });
            }
          }
        }

        contacts.assignAll(contactList);

        // Save in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("saved_contacts", jsonEncode(contactList));
      }
    } catch (e) {
      print("Error fetching contacts: $e");
    }
  }

  /// Normalize phone number to include country code (+407, +1, etc.)
  String _normalizePhoneNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');

    // Example: Add default country code if missing
    if (!cleaned.startsWith("+")) {
      cleaned = "+407$cleaned"; // Change +407 to your default country code
    }
    return cleaned;
  }

  /// Load contacts from SharedPreferences
  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("saved_contacts");
    if (saved != null) {
      final List decoded = jsonDecode(saved);
      contacts.assignAll(List<Map<String, dynamic>>.from(decoded));
    }
  }

  Future<void> sendInviteSms(String number, String name) async {
    final message =
        "$name wants to send you a message on re: The app that makes sharing photos and videos more fun by capturing real reactions. "
        "Be a part of the moment and download here: https://yourappdownloadlink.com";

    final smsUri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: {
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        print("❌ Could not launch SMS app. URI: $smsUri");
      }
    } catch (e, stack) {
      print("🚨 Error launching SMS: $e");
      print(stack);
    }
  }
}
