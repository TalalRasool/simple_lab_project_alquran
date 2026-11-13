import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device preferences. They are not tied to a Firebase account.
class AppPreferences {
  static const themeKey = 'app_theme_mode';
  static const translationKey = 'quran_translation';
  static const hadithLanguageKey = 'hadith_language';

  Future<ThemeMode> readTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(themeKey) == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
    } catch (_) {
      return ThemeMode.light;
    }
  }

  Future<void> saveTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        themeKey,
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {}
  }

  Future<String> readTranslation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(translationKey);
      if (code == 'ur' || code == 'en') return code!;
      return 'en';
    } catch (_) {
      return 'en';
    }
  }

  Future<void> saveTranslation(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(translationKey, code);
    } catch (_) {}
  }

  Future<String> readHadithLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(hadithLanguageKey);
      if (code == 'ur' || code == 'en' || code == 'both') return code!;
      return 'both';
    } catch (_) {
      return 'both';
    }
  }

  Future<void> saveHadithLanguage(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(hadithLanguageKey, code);
    } catch (_) {}
  }
}
