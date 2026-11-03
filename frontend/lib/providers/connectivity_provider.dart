import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool online = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> init() async {
    final r = await Connectivity().checkConnectivity();
    online = _isOn(r);
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      final now = _isOn(r);
      if (now != online) {
        online = now;
        notifyListeners();
      }
    });
  }

  bool _isOn(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
