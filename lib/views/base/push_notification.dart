import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ree_social_media_app/views/base/custom_switch.dart';

import '../../services/shared_prefs_service.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  _NotificationSettingsState createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool isSwitch = false; // Default value for the switch

  @override
  void initState() {
    super.initState();
    _loadSwitchStatus(); // Load the saved status when the widget is loaded
  }

  // Function to load the switch status from SharedPreferences
  Future<void> _loadSwitchStatus() async {
    final status = await SharedPrefsService.get('push_notifications_status');
    setState(() {
      isSwitch = status == 'true';
    });
  }

  // Function to handle switch changes
  void _handleSwitchChange(bool value) async {
    setState(() {
      isSwitch = value;
    });

    // Save the switch status in SharedPreferences
    await SharedPrefsService.set(
      'push_notifications_status',
      isSwitch ? 'true' : 'false',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset('assets/icons/notification_fill.svg'),
        const SizedBox(width: 13),
        const Text(
          "Push Notifications",
          style: TextStyle(
            color: Color(0xFF676565),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        CustomSwitch(value: isSwitch, onChanged: _handleSwitchChange),
      ],
    );
  }
}
