import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  Locale locale = const Locale('fr');

  String get lang => locale.languageCode;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final l = p.getString('lang');
    if (l == 'wo' || l == 'fr') locale = Locale(l!);
  }

  Future<void> setLang(String code) async {
    locale = Locale(code);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', code);
  }
}
