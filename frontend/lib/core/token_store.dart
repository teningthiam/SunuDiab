// import 'dart:convert';
//
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// import '../models/models.dart';
//
// class TokenStore {
//   static const FlutterSecureStorage _s = FlutterSecureStorage();
//
//   Future<String?> get access => _s.read(key: 'access');
//   Future<String?> get refresh => _s.read(key: 'refresh');
//
//   Future<void> saveTokens(String access, String refresh) async {
//     await _s.write(key: 'access', value: access);
//     await _s.write(key: 'refresh', value: refresh);
//   }
//
//   Future<void> saveUser(UserInfo u) =>
//       _s.write(key: 'user', value: jsonEncode(u.toJson()));
//
//   Future<UserInfo?> loadUser() async {
//     final s = await _s.read(key: 'user');
//     if (s == null) return null;
//     try {
//       return UserInfo.fromJson(jsonDecode(s) as Map<String, dynamic>);
//     } catch (_) {
//       return null;
//     }
//   }
//
//   Future<void> clear() => _s.deleteAll();
// }


import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class TokenStore {
  static const FlutterSecureStorage _s = FlutterSecureStorage();

  Future<String?> get access async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      return p.getString('access');
    }
    return _s.read(key: 'access');
  }

  Future<String?> get refresh async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      return p.getString('refresh');
    }
    return _s.read(key: 'refresh');
  }

  Future<void> saveTokens(String access, String refresh) async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.setString('access', access);
      await p.setString('refresh', refresh);
    } else {
      await _s.write(key: 'access', value: access);
      await _s.write(key: 'refresh', value: refresh);
    }
  }

  Future<void> saveUser(UserInfo u) async {
    final value = jsonEncode(u.toJson());

    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.setString('user', value);
    } else {
      await _s.write(key: 'user', value: value);
    }
  }

  Future<UserInfo?> loadUser() async {
    String? value;

    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      value = p.getString('user');
    } else {
      value = await _s.read(key: 'user');
    }

    if (value == null) return null;

    try {
      return UserInfo.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.remove('access');
      await p.remove('refresh');
      await p.remove('user');
    } else {
      await _s.deleteAll();
    }
  }
}
