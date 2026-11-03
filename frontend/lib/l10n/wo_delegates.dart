import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter ne fournit pas le wolof (« wo ») pour ses widgets internes (calendrier, boutons système...).
/// Ces délégués les chargent en français quand l'application est en wolof ; nos propres textes
/// viennent de strings.dart.
class WoMaterialDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const WoMaterialDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'wo';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) => false;
}

class WoWidgetsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const WoWidgetsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'wo';
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('fr'));
  @override
  bool shouldReload(
    covariant LocalizationsDelegate<WidgetsLocalizations> old,
  ) => false;
}

class WoCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const WoCupertinoDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'wo';
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('fr'));
  @override
  bool shouldReload(
    covariant LocalizationsDelegate<CupertinoLocalizations> old,
  ) => false;
}
