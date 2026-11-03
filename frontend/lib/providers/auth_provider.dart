import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/token_store.dart';
import '../models/models.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.api, this.tokens);

  final ApiClient api;
  final TokenStore tokens;
  AuthStatus status = AuthStatus.unknown;
  UserInfo? user;

  /// Démarrage : si des jetons existent, on entre directement (fonctionne hors ligne).
  Future<void> init() async {
    final u = await tokens.loadUser();
    final rt = await tokens.refresh;
    if (u != null && rt != null) {
      user = u;
      status = AuthStatus.loggedIn;
    } else {
      status = AuthStatus.loggedOut;
    }
    notifyListeners();
  }

  Future<void> login(String identifiant, String password) async {
    final j = await api.post(
      '/api/auth/login',
      body: {'identifiant': identifiant.trim(), 'password': password},
      auth: false,
    );
    await _accept(j);
  }

  Future<void> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String password,
    required String dateNaissance,
    required String sexe,
    required String region,
    required String langue,
  }) async {
    final j = await api.post(
      '/api/auth/register',
      body: {
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'telephone': telephone.trim(),
        'password': password,
        'dateNaissance': dateNaissance,
        'sexe': sexe,
        'region': region,
        'langue': langue,
        'consentement': true,
      },
      auth: false,
    );
    await _accept(j);
  }

  Future<void> _accept(dynamic j) async {
    final u = UserInfo.fromJson(
      Map<String, dynamic>.from(j['utilisateur'] as Map),
    );
    if (u.role != 'PATIENT') {
      throw const ApiException(
        403,
        'Cette application est réservée aux patients. Les médecins utilisent le portail web.',
      );
    }
    await tokens.saveTokens(
      j['accessToken'] as String,
      j['refreshToken'] as String,
    );
    await tokens.saveUser(u);
    user = u;
    status = AuthStatus.loggedIn;
    notifyListeners();
  }

  Future<void> logout() async {
    await tokens.clear();
    user = null;
    status = AuthStatus.loggedOut;
    notifyListeners();
  }

  void sessionExpired() {
    if (status == AuthStatus.loggedIn) logout();
  }
}
