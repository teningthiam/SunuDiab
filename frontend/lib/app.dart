import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'l10n/wo_delegates.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';

class SunuDiabApp extends StatelessWidget {
  const SunuDiabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'SunuDiab',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: settings.locale,
      supportedLocales: const [Locale('fr'), Locale('wo')],
      localizationsDelegates: const [
        WoMaterialDelegate(),
        WoWidgetsDelegate(),
        WoCupertinoDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.loggedIn:
        return const HomeShell();
      case AuthStatus.loggedOut:
        return const WelcomeScreen();
    }
  }
}
