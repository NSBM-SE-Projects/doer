import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app locale (language) and persists it to SharedPreferences.
/// Uses a ValueNotifier so MaterialApp rebuilds when the locale changes.
class LocaleService {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  static const String _prefKey = 'c_language';

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  /// Call this in main() before runApp to load saved language preference.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'en';
    locale.value = Locale(code);
  }

  /// Change the app language and persist the choice.
  Future<void> setLocale(Locale newLocale) async {
    if (locale.value == newLocale) return;
    locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
  }

  /// Convenience: set language by language code string ('en', 'si', 'ta').
  Future<void> setLanguageCode(String code) => setLocale(Locale(code));

  /// Current language code.
  String get languageCode => locale.value.languageCode;

  /// Human-readable label for the current language.
  String get currentLanguageLabel {
    switch (languageCode) {
      case 'si': return 'සිංහල';
      default: return 'English';
    }
  }

  static const List<_LangOption> languages = [
    _LangOption(code: 'en', label: 'English', nativeLabel: 'English'),
    _LangOption(code: 'si', label: 'Sinhala', nativeLabel: 'සිංහල'),
  ];
}

class _LangOption {
  final String code;
  final String label;
  final String nativeLabel;
  const _LangOption({required this.code, required this.label, required this.nativeLabel});
}
