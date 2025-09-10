import 'package:flutter/material.dart';

import '../../base/bottom_menu..dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return   Scaffold(
      bottomNavigationBar: BottomMenu(3),
    );
  }
}
