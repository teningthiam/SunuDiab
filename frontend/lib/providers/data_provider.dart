import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/api_client.dart';
import '../core/findrisc.dart';
import '../core/format.dart';
import '../core/glycemia.dart';
import '../core/local_db.dart';
import '../models/models.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

/// Données du patient : toujours lues depuis la base locale (offline-first), synchronisées en arrière-plan.
class DataProvider extends ChangeNotifier {
  DataProvider(this.api, this.conn, this.auth) {
    _sync = SyncService(api);
    auth.addListener(_onAuth);
    conn.addListener(() {
      if (conn.online && auth.status == AuthStatus.loggedIn) {
        unawaited(syncNow());
      }
    });
  }

  final ApiClient api;
  final ConnectivityProvider conn;
  final AuthProvider auth;
  late final SyncService _sync;

  Profil? profil;
  List<Mesure> mesures = []; // plus récentes d'abord
  List<Traitement> traitements = [];
  List<Ordonnance> ordonnances = [];
  List<Rdv> rdvs = [];
  List<Conseil> conseils = [];
  RisqueResult? lastRisk;
  Map<int, DateTime> lastPrise = {};
  bool syncing = false;
  DateTime? lastSync;
  int pendingCount = 0;
  bool _wasIn = false;

  void _onAuth() {
    final inNow = auth.status == AuthStatus.loggedIn;
    if (inNow && !_wasIn) {
      _wasIn = true;
      unawaited(() async {
        await loadLocal();
        await syncNow();
      }());
    } else if (!inNow && _wasIn) {
      _wasIn = false;
      unawaited(reset());
    }
  }

  Future<void> reset() async {
    await LocalDb.clearAll();
    profil = null;
    mesures = [];
    traitements = [];
    ordonnances = [];
    rdvs = [];
    conseils = [];
    lastRisk = null;
    lastPrise = {};
    lastSync = null;
    pendingCount = 0;
    notifyListeners();
  }

  // ---------- lecture locale ----------
  Future<void> loadLocal() async {
    mesures = await LocalDb.listMesures();
    final p = await LocalDb.kvGet('profil');
    profil = p == null
        ? null
        : Profil(Map<String, dynamic>.from(jsonDecode(p) as Map));
    traitements = (await LocalDb.kvList('traitements'))
        .map((m) => Traitement(m))
        .toList();
    ordonnances = (await LocalDb.kvList('ordonnances'))
        .map((m) => Ordonnance(m))
        .toList();
    rdvs = (await LocalDb.kvList('rdv')).map((m) => Rdv(m)).toList()
      ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));
    conseils = (await LocalDb.kvList('conseils'))
        .map((m) => Conseil(m))
        .toList();
    final r = await LocalDb.kvGet('risque_last');
    lastRisk = r == null
        ? null
        : RisqueResult.fromJson(
            Map<String, dynamic>.from(jsonDecode(r) as Map),
          );
    final ls = await LocalDb.kvGet('last_sync');
    lastSync = ls == null ? null : DateTime.tryParse(ls)?.toLocal();
    pendingCount = await LocalDb.pendingCount();
    final lp = <int, DateTime>{};
    for (final t in traitements) {
      final s = await LocalDb.kvGet('last_prise_${t.id}');
      if (s != null) {
        final d = DateTime.tryParse(s);
        if (d != null) lp[t.id] = d.toLocal();
      }
    }
    lastPrise = lp;
    notifyListeners();
  }

  /// Renvoie un message d'erreur (null si OK ou simplement hors ligne).
  Future<String?> syncNow() async {
    if (syncing || !conn.online || auth.status != AuthStatus.loggedIn)
      return null;
    syncing = true;
    notifyListeners();
    String? err;
    try {
      await _sync.sync();
      await LocalDb.kvSet(
        'last_sync',
        DateTime.now().toUtc().toIso8601String(),
      );
    } on ApiException catch (e) {
      err = e.isNetwork ? null : e.message;
    } catch (e) {
      err = e.toString();
    }
    syncing = false;
    await loadLocal();
    return err;
  }

  // ---------- glycémies ----------
  double get cibleMin => profil?.cibleMin ?? 0.70;
  double get cibleMax => profil?.cibleMax ?? 1.30;

  /// Mesures des [days] derniers jours, ordre chronologique.
  List<Mesure> mesuresSince(int days) {
    final limit = DateTime.now().toUtc().subtract(Duration(days: days));
    final l = mesures.where((m) => m.mesureLe.isAfter(limit)).toList();
    l.sort((a, b) => a.mesureLe.compareTo(b.mesureLe));
    return l;
  }

  Future<Mesure> addMesure({
    required double valeur,
    required String moment,
    String methode = 'CLAVIER',
    String? contexte,
    String? note,
  }) async {
    final m = Mesure.create(
      valeur: valeur,
      moment: moment,
      methode: methode,
      contexte: contexte,
      note: note,
      statut: statusFromValue(valeur, cibleMin, cibleMax),
    );
    await LocalDb.insertMesure(m);
    await loadLocal();
    if (conn.online) unawaited(syncNow());
    return m;
  }

  Future<void> deleteMesure(Mesure m) async {
    await LocalDb.softDelete(m.clientUuid);
    await loadLocal();
    if (conn.online) unawaited(syncNow());
  }

  // ---------- traitements ----------
  Future<void> markPrise(Traitement t) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await LocalDb.addPrise(const Uuid().v4(), t.id, now, 'PRIS');
    await LocalDb.kvSet('last_prise_${t.id}', now);
    await loadLocal();
    if (conn.online) unawaited(syncNow());
  }

  // ---------- profil (nécessite une connexion) ----------
  Future<void> _saveProfil(dynamic j) async {
    await LocalDb.kvSet('profil', jsonEncode(j));
    profil = Profil(Map<String, dynamic>.from(j as Map));
    notifyListeners();
  }

  Future<void> updateProfil(Map<String, dynamic> body) async {
    final j = await api.put('/api/patient/profil', body: body);
    await _saveProfil(j);
  }

  Future<void> choisirMedecin(int medecinId) async {
    final j = await api.put(
      '/api/patient/medecin-referent',
      body: {'medecinId': medecinId},
    );
    await _saveProfil(j);
  }

  Future<void> refreshProfil() async {
    final j = await api.get('/api/patient/profil');
    await _saveProfil(j);
  }

  Future<void> ajouterContact(
    String nom,
    String telephone,
    String? lien,
  ) async {
    await api.post(
      '/api/patient/contacts',
      body: {'nom': nom, 'telephone': telephone, 'lien': lien},
    );
    await refreshProfil();
  }

  Future<void> supprimerContact(int id) async {
    await api.delete('/api/patient/contacts/$id');
    await refreshProfil();
  }

  // ---------- risque ----------
  Future<RisqueResult> evaluateRisk(RisqueInput input) async {
    final r = computeRisk(input);
    await LocalDb.kvSet('risque_last', jsonEncode(r.toJson()));
    lastRisk = r;
    notifyListeners();
    if (conn.online) {
      try {
        await api.post('/api/patient/risque', body: input.toJson());
      } catch (_) {
        // enregistrement serveur différé : le résultat local reste valable
      }
    }
    return r;
  }

  // ---------- rendez-vous (en ligne) ----------
  Future<List<Medecin>> medecins() async {
    final j = await api.get('/api/medecins');
    return (j as List)
        .map((e) => Medecin.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> bookRdv({
    required int medecinId,
    required DateTime dateHeure,
    required String mode,
    String? motif,
  }) async {
    final j = await api.post(
      '/api/patient/rendez-vous',
      body: {
        'medecinId': medecinId,
        'dateHeure': toLocalIso(dateHeure),
        'mode': mode,
        'motif': motif,
      },
    );
    await LocalDb.mergeList('rdv', [j]);
    await loadLocal();
  }

  Future<void> cancelRdv(int id) async {
    final j = await api.put('/api/patient/rendez-vous/$id/annuler');
    await LocalDb.mergeList('rdv', [j]);
    await loadLocal();
  }
}
