import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'token_store.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  const ApiException(this.status, this.message);

  /// status 0 = pas de réseau / serveur injoignable.
  bool get isNetwork => status == 0;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.tokens);

  final TokenStore tokens;
  void Function()? onSessionExpired;
  Future<bool>? _refreshing;
  static const Duration _timeout = Duration(seconds: 20);

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) => _send('GET', path, query: query, auth: auth);
  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);
  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
    bool retry = true,
  }) async {
    final uri = Uri.parse('${ServerConfig.baseUrl}$path')
        .replace(queryParameters: query);
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (auth) {
      final t = await tokens.access;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    final payload = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      switch (method) {
        case 'POST':
          res = await http
              .post(uri, headers: headers, body: payload)
              .timeout(_timeout);
          break;
        case 'PUT':
          res = await http
              .put(uri, headers: headers, body: payload)
              .timeout(_timeout);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          res = await http.get(uri, headers: headers).timeout(_timeout);
      }
    } catch (e) {
      // ignore: avoid_print
      print('API ERREUR $method $uri -> $e');
      throw const ApiException(0, 'network');
    }

    if (res.statusCode == 401 && auth && retry) {
      bool ok;
      try {
        ok = await _refresh();
      } on ApiException catch (e) {
        if (e.isNetwork) rethrow;
        ok = false;
      }
      if (ok)
        return _send(
          method,
          path,
          body: body,
          query: query,
          auth: auth,
          retry: false,
        );
      onSessionExpired?.call();
      throw const ApiException(401, 'session');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }

    String msg = 'Erreur ${res.statusCode}';
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      if (j is Map) {
        if (j['message'] != null) msg = j['message'].toString();
        final d = j['details'];
        if (d is Map && d.isNotEmpty) msg = d.values.first.toString();
      }
    } catch (_) {}
    throw ApiException(res.statusCode, msg);
  }

  Future<bool> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final rt = await tokens.refresh;
    if (rt == null) return false;
    try {
      final j = await _send(
        'POST',
        '/api/auth/refresh',
        body: {'refreshToken': rt},
        auth: false,
      );
      await tokens.saveTokens(
        j['accessToken'] as String,
        j['refreshToken'] as String,
      );
      return true;
    } on ApiException catch (e) {
      if (e.isNetwork) rethrow;
      return false;
    }
  }
}
