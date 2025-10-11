import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:ree_social_media_app/controllers/localization_controller.dart';
import 'package:ree_social_media_app/controllers/theme_controller.dart';
import 'package:ree_social_media_app/services/camera_manager.dart';
import 'package:ree_social_media_app/themes/light_theme.dart';
import 'package:ree_social_media_app/utils/app_constants.dart';
import 'package:ree_social_media_app/utils/message.dart';

import 'controllers/user_controller.dart';
import 'helpers/di.dart' as di;
import 'helpers/route.dart';
List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dispose any previously active camera (important for hot restart)
  await GlobalCameraManager.dispose();

  // Give CameraX time to fully release before re-querying
  await Future.delayed(const Duration(milliseconds: 200));

  // Initialize DI
  Map<String, Map<String, String>> _languages = await di.init();
  Get.put(UserController(), permanent: true);

  try {
    // Load available cameras safely
    cameras = await availableCameras();
    AppRoutes.cameras = cameras;
  } catch (e) {
    debugPrint("❌ Camera init error: $e");
  }

  runApp(MyApp(languages: _languages));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.languages});
  final Map<String, Map<String, String>> languages;
  @override
  Widget build(BuildContext context) {
    return  GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return ScreenUtilInit(
            designSize: const Size(393, 852),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_ , child) {
              return GetMaterialApp(
                title: AppConstants.APP_NAME,
                debugShowCheckedModeBanner: false,
                navigatorKey: Get.key,
                // theme: themeController.darkTheme ? dark(): light(),
                theme: light(),
                defaultTransition: Transition.topLevel,
                locale: localizeController.locale,
                translations: Messages(languages: languages),
                fallbackLocale: Locale(AppConstants.languages[0].languageCode, AppConstants.languages[0].countryCode),
                transitionDuration: const Duration(milliseconds: 500),
                getPages: AppRoutes.page,
                initialRoute: AppRoutes.splashScreen,
              );
            }
        );
      }
      );

    }
    );

  }

}