import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/config.dart';
import 'core/token_store.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/data_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/shell_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  await ServerConfig.load();

  final tokens = TokenStore();
  final api = ApiClient(tokens);
  final settings = SettingsProvider();
  await settings.load();
  final connectivity = ConnectivityProvider();
  await connectivity.init();
  final auth = AuthProvider(api, tokens);
  api.onSessionExpired = auth.sessionExpired;
  final data = DataProvider(api, connectivity, auth);
  final chat = ChatProvider(api, connectivity);
  final messages = MessagesProvider(api, connectivity, auth);
  unawaited(auth.init());

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ConnectivityProvider>.value(value: connectivity),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<DataProvider>.value(value: data),
        ChangeNotifierProvider<ChatProvider>.value(value: chat),
        ChangeNotifierProvider<MessagesProvider>.value(value: messages),
        ChangeNotifierProvider<ShellNav>(create: (_) => ShellNav()),
      ],
      child: const SunuDiabApp(),
    ),
  );
}