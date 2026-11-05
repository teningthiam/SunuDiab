import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

/// Nombre de messages non lus (vérifié toutes les 30 secondes quand le patient est connecté).
class MessagesProvider extends ChangeNotifier {
  MessagesProvider(this.api, this.conn, this.auth) {
    auth.addListener(_onAuth);
  }

  final ApiClient api;
  final ConnectivityProvider conn;
  final AuthProvider auth;
  int unread = 0;
  Timer? _timer;
  bool _on = false;

  void _onAuth() {
    final inNow = auth.status == AuthStatus.loggedIn;
    if (inNow && !_on) {
      _on = true;
      unawaited(refreshUnread());
      _timer = Timer.periodic(
        const Duration(seconds: 30),
            (_) => refreshUnread(),
      );
    } else if (!inNow && _on) {
      _on = false;
      _timer?.cancel();
      _timer = null;
      unread = 0;
      notifyListeners();
    }
  }

  Future<void> refreshUnread() async {
    if (!conn.online || auth.status != AuthStatus.loggedIn) return;
    try {
      final j = await api.get('/api/messages/non-lus');
      final n = ((j as Map)['nonLus'] as num?)?.toInt() ?? 0;
      if (n != unread) {
        unread = n;
        notifyListeners();
      }
    } catch (_) {
      // hors ligne ou erreur passagère : on réessaiera
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}