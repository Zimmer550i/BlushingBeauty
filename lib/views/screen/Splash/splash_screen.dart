import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/controllers/auth_controller.dart';
import 'package:ree_social_media_app/views/screen/Splash/Onboard/onboard_screen1.dart';
import '../Message/message_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController authController = Get.put(AuthController());
  // String _deviceId = "Loading...";

  @override
  void initState() {
    Future.delayed(Duration(seconds: 3), () async {
      final isLoggedIn = await authController.previouslyLoggedIn();
      if (isLoggedIn) {
        Get.offAll(()=> MessageScreen());
      } else {
        Get.to(()=> OnboardScreen1());
      }
    });
    super.initState();
    // _getDeviceInfo();
    // initPlatformState();
  }

//   // Initialize OneSignal
// Future<void> initPlatformState() async {
//     if (!mounted) return;

//     // Initialize OneSignal
//     OneSignal.initialize(
//       AppConstants.onesignalAppId,
//     );


//   }



  // Future<void> _getDeviceInfo() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

  //   setState(() {
  //     _deviceId = androidInfo.id;
  //   });

  //   debugPrint("======>Device ID: $_deviceId");
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF56BBFF),
              Color(0xFFE6E6E6)
            ]
          )
        ),
        child: Center(
          child: Text("re:",
          style: TextStyle(
            fontSize: 100,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),),
        ),
    ));
  }
}
