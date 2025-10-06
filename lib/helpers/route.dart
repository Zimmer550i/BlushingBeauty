import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/views/screen/Auth/login_screen.dart';
import 'package:ree_social_media_app/views/screen/Contact/contact_screen.dart';
import 'package:ree_social_media_app/views/screen/Message/message_screen.dart';
import 'package:ree_social_media_app/views/screen/Profile/profile_screen.dart';
import 'package:ree_social_media_app/views/screen/Camera/camera_screen.dart';


import '../views/screen/Splash/splash_screen.dart';

class AppRoutes{

  static String splashScreen="/splash_screen";
  static String messageScreen="/message_screen";
  static String profileScreen="/profile_screen";
  static String cameraScreen="/camera_screen";
  static String loginScreen="/login_screen";
  static String contactScreen = "/contact_screen";

  static List<CameraDescription>? cameras;


 static List<GetPage> page=[
    GetPage(name:splashScreen, page: ()=>const SplashScreen()),
    GetPage(name:messageScreen, page: ()=> MessageScreen()),
    GetPage(name:cameraScreen, page: ()=> CameraScreen(
      cameras: cameras ?? [],
    )),
    GetPage(name:profileScreen, page: ()=>const ProfileScreen()),
    GetPage(name:loginScreen, page: ()=>const LoginScreen()),
   GetPage(name: contactScreen, page: ()=>const ContactScreen())
  ];



}