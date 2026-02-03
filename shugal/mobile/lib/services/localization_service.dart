import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String languageKey = 'app_language';

  static const Locale english = Locale('en', '');
  static const Locale arabic = Locale('ar', '');

  static const List<Locale> supportedLocales = [
    english,
    arabic,
  ];

  static Locale defaultLocale = english;

  // Callback for locale changes - set by the app
  static void Function(Locale)? _onLocaleChanged;

  /// Set the callback to be notified when locale changes
  static void setLocaleChangeCallback(void Function(Locale) callback) {
    _onLocaleChanged = callback;
  }

  /// Remove the locale change callback
  static void removeLocaleChangeCallback() {
    _onLocaleChanged = null;
  }

  /// Get saved locale from preferences
  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(languageKey);

    if (languageCode != null) {
      return Locale(languageCode);
    }

    return null;
  }

  /// Save locale to preferences and notify listeners
  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, locale.languageCode);

    // Notify the app about the locale change
    _onLocaleChanged?.call(locale);
  }

  /// Check if locale is RTL
  static bool isRTL(Locale locale) {
    return locale.languageCode == 'ar';
  }
}
