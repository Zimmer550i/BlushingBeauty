import '../models/language_model.dart';

class AppConstants {
  static String appName = "Ree";

  // share preference Key
  static String theme = "theme";

  static const String languageCode = 'languageCode';
  static const String countryCode = 'countryCode';

  static RegExp emailValidator = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  static RegExp passwordValidator = RegExp(
    r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$",
  );
  static List<LanguageModel> languages = [
    LanguageModel(
      languageName: 'English',
      countryCode: 'US',
      languageCode: 'en',
    ),
    LanguageModel(languageName: 'عربى', countryCode: 'SA', languageCode: 'ar'),
    LanguageModel(
      languageName: 'Spanish',
      countryCode: 'ES',
      languageCode: 'es',
    ),
  ];
}
