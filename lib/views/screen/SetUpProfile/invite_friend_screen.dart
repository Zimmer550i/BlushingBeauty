import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/base/custom_text_field.dart';
import 'package:ree_social_media_app/views/screen/SetUpProfile/enable_notification_screen.dart';

class InviteFriendScreen extends StatefulWidget {
  const InviteFriendScreen({super.key});

  @override
  State<InviteFriendScreen> createState() => _InviteFriendScreenState();
}

class _InviteFriendScreenState extends State<InviteFriendScreen> {
  final searchTextController = TextEditingController();
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    searchTextController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  /// Load contacts from SharedPreferences
  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedContacts = prefs.getString("saved_contacts");

    if (savedContacts != null) {
      List<dynamic> decoded = jsonDecode(savedContacts);
      setState(() {
        contacts = decoded.cast<Map<String, dynamic>>();
        filteredContacts = contacts;
      });
    }
  }

  /// Search filter
  void _onSearchChanged() {
    final query = searchTextController.text.toLowerCase();
    setState(() {
      filteredContacts = contacts.where((c) {
        final name = (c["name"] ?? "").toLowerCase();
        final number = (c["number"] ?? "").toLowerCase();
        return name.contains(query) || number.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// Top bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 36,
                    width: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "re:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "2 of 4",
                    style: TextStyle(
                      color: const Color(0xFF413E3E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            /// Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      "Connect With Friends",
                      style: TextStyle(
                        color: Color(0xFF413E3E),
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "To start your first messages on re: invite 5 friends who matter most",
                      style: TextStyle(
                        color: Color(0xFF413E3E),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),

                    /// Search bar
                    CustomTextField(
                      controller: searchTextController,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SvgPicture.asset('assets/icons/search.svg'),
                      ),
                      hintText: 'Search Contacts',
                    ),
                    const SizedBox(height: 24),

                    /// Contacts List
                    filteredContacts.isEmpty
                        ? const Center(
                      child: Text(
                        "No contacts found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        return Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/dummy.jpg'), // Fallback
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${contact["name"] ?? "Unknown"}\n${contact["number"] ?? ""}",
                                style: const TextStyle(
                                  color: Color(0xFF676565),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Container(
                              height: 38,
                              width: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF002329)
                                        .withValues(alpha: 0.07),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "Add",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 16),
                      itemCount: filteredContacts.length,
                    ),

                    const SizedBox(height: 20),

                    /// Next button
                    CustomButton(
                      onTap: () {
                        Get.to(() => const EnableNotificationScreen());
                      },
                      text: "Next",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
