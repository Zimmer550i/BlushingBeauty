import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ree_social_media_app/models/language_model.dart';
import 'package:ree_social_media_app/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';



class LocalizationController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;


  LocalizationController({required this.sharedPreferences, }) {
    loadCurrentLanguage();
  }

  Locale _locale = Locale(AppConstants.languages[0].languageCode, AppConstants.languages[0].countryCode);
  bool _isLtr = true;
  List<LanguageModel> _languages = [];

  Locale get locale => _locale;
  bool get isLtr => _isLtr;
  List<LanguageModel> get languages => _languages;

  void setLanguage(Locale locale) {
    Get.updateLocale(locale);
    _locale = locale;
    if(_locale.languageCode == 'ar') {
      _isLtr = false;
    }else {
      _isLtr = true;
    }
    saveLanguage(_locale);
    update();
  }

  void loadCurrentLanguage() async {
    _locale = Locale(sharedPreferences.getString(AppConstants.languageCode) ?? AppConstants.languages[0].languageCode,
        sharedPreferences.getString(AppConstants.countryCode) ?? AppConstants.languages[0].countryCode);
    _isLtr = _locale.languageCode != 'ar';
    for(int index = 0; index<AppConstants.languages.length; index++) {
      if(AppConstants.languages[index].languageCode == _locale.languageCode) {
        _selectedIndex = index;
        break;
      }
    }
    _languages = [];
    _languages.addAll(AppConstants.languages);
    update();
  }

  void saveLanguage(Locale locale) async {
    sharedPreferences.setString(AppConstants.languageCode, locale.languageCode);
    sharedPreferences.setString(AppConstants.countryCode, locale.countryCode??"");
  }

  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectIndex(int index) {
    _selectedIndex = index;
    update();
  }

  void searchLanguage(String query) {
    if (query.isEmpty) {
      _languages  = [];
      _languages = AppConstants.languages;
    } else {
      _selectedIndex = -1;
      _languages = [];
      // ignore: avoid_function_literals_in_foreach_calls
      AppConstants.languages.forEach((language) async {
        if (language.languageName.toLowerCase().contains(query.toLowerCase())) {
          _languages.add(language);
        }
      });
    }
    update();
  }
}