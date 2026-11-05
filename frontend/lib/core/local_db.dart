import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Stockage local (offline-first).
/// - Téléphone (Android / iOS) : base SQLite.
/// - Navigateur (Safari, Chrome) : SQLite n'existe pas, on utilise le stockage du navigateur.
/// Pour chiffrer la base sur téléphone (données de santé) : migrer vers sqflite_sqlcipher.
class LocalDb {
  static Database? _db;

  static Future<Database> get db async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'sunudiab.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
        CREATE TABLE mesures (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          client_uuid TEXT UNIQUE NOT NULL,
          server_id INTEGER,
          valeur REAL NOT NULL,
          moment TEXT NOT NULL,
          methode TEXT,
          contexte TEXT,
          note TEXT,
          mesure_le TEXT NOT NULL,
          statut TEXT,
          supprime INTEGER NOT NULL DEFAULT 0,
          synced INTEGER NOT NULL DEFAULT 0
        )''');
        await d.execute('''
        CREATE TABLE prises_pending (
          client_uuid TEXT PRIMARY KEY,
          traitement_id INTEGER NOT NULL,
          pris_le TEXT NOT NULL,
          statut TEXT NOT NULL
        )''');
        await d.execute(
          'CREATE TABLE kv (k TEXT PRIMARY KEY, v TEXT NOT NULL)',
        );
      },
    );
  }

  // ---------- clé / valeur ----------
  static Future<String?> kvGet(String k) async {
    if (kIsWeb) return _Web.kvGet(k);
    final d = await db;
    final r = await d.query('kv', where: 'k = ?', whereArgs: [k], limit: 1);
    return r.isEmpty ? null : r.first['v'] as String;
  }

  static Future<void> kvSet(String k, String v) async {
    if (kIsWeb) return _Web.kvSet(k, v);
    final d = await db;
    await d.insert('kv', {
      'k': k,
      'v': v,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> kvList(String k) async {
    final s = await kvGet(k);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fusionne des éléments (par id) dans une liste mise en cache.
  static Future<void> mergeList(String k, List<dynamic> incoming) async {
    final byId = <int, Map<String, dynamic>>{};
    for (final m in await kvList(k)) {
      byId[(m['id'] as num).toInt()] = m;
    }
    for (final e in incoming) {
      final m = Map<String, dynamic>.from(e as Map);
      byId[(m['id'] as num).toInt()] = m;
    }
    await kvSet(k, jsonEncode(byId.values.toList()));
  }

  // ---------- mesures ----------
  static Future<List<Mesure>> listMesures() async {
    if (kIsWeb) return _Web.listMesures();
    final d = await db;
    final r = await d.query(
      'mesures',
      where: 'supprime = 0',
      orderBy: 'mesure_le DESC',
    );
    return r.map(Mesure.fromDb).toList();
  }

  static Future<void> insertMesure(Mesure m) async {
    if (kIsWeb) return _Web.insertMesure(m);
    final d = await db;
    await d.insert(
      'mesures',
      m.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Mesure>> unsyncedMesures() async {
    if (kIsWeb) return _Web.unsyncedMesures();
    final d = await db;
    final r = await d.query('mesures', where: 'synced = 0');
    return r.map(Mesure.fromDb).toList();
  }

  static Future<void> markSynced(String uuid, int? serverId) async {
    if (kIsWeb) return _Web.markSynced(uuid, serverId);
    final d = await db;
    await d.update(
      'mesures',
      {'synced': 1, 'server_id': serverId},
      where: 'client_uuid = ?',
      whereArgs: [uuid],
    );
  }

  static Future<void> softDelete(String uuid) async {
    if (kIsWeb) return _Web.softDelete(uuid);
    final d = await db;
    await d.update(
      'mesures',
      {'supprime': 1, 'synced': 0},
      where: 'client_uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Mesure reçue du serveur : n'écrase jamais une modification locale non synchronisée.
  static Future<void> upsertServerMesure(Mesure m) async {
    if (kIsWeb) return _Web.upsertServerMesure(m);
    final d = await db;
    final r = await d.query(
      'mesures',
      where: 'client_uuid = ?',
      whereArgs: [m.clientUuid],
      limit: 1,
    );
    if (r.isEmpty) {
      await d.insert('mesures', m.toDb());
    } else if ((r.first['synced'] as int) == 1) {
      final map = m.toDb()..remove('id');
      await d.update(
        'mesures',
        map,
        where: 'client_uuid = ?',
        whereArgs: [m.clientUuid],
      );
    }
  }

  // ---------- prises (file d'attente) ----------
  static Future<void> addPrise(
      String uuid,
      int traitementId,
      String prisLe,
      String statut,
      ) async {
    if (kIsWeb) return _Web.addPrise(uuid, traitementId, prisLe, statut);
    final d = await db;
    await d.insert('prises_pending', {
      'client_uuid': uuid,
      'traitement_id': traitementId,
      'pris_le': prisLe,
      'statut': statut,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, Object?>>> pendingPrises() async {
    if (kIsWeb) return _Web.pendingPrises();
    final d = await db;
    return d.query('prises_pending');
  }

  static Future<void> deletePrise(String uuid) async {
    if (kIsWeb) return _Web.deletePrise(uuid);
    final d = await db;
    await d.delete(
      'prises_pending',
      where: 'client_uuid = ?',
      whereArgs: [uuid],
    );
  }

  static Future<int> pendingCount() async {
    if (kIsWeb) return _Web.pendingCount();
    final d = await db;
    final a =
        Sqflite.firstIntValue(
          await d.rawQuery('SELECT COUNT(*) FROM mesures WHERE synced = 0'),
        ) ??
            0;
    final b =
        Sqflite.firstIntValue(
          await d.rawQuery('SELECT COUNT(*) FROM prises_pending'),
        ) ??
            0;
    return a + b;
  }

  static Future<void> clearAll() async {
    if (kIsWeb) return _Web.clearAll();
    final d = await db;
    await d.delete('mesures');
    await d.delete('prises_pending');
    await d.delete('kv');
  }
}

/// Version navigateur : tout est gardé en JSON dans le stockage du navigateur (SharedPreferences).
class _Web {
  static const String _kMesures = 'sd_mesures';
  static const String _kPrises = 'sd_prises';
  static const String _kvPrefix = 'sd_kv_';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<List<Map<String, Object?>>> _read(String key) async {
    final s = (await _prefs).getString(key);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List)
          .map((e) => Map<String, Object?>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(
      String key,
      List<Map<String, Object?>> rows,
      ) async {
    await (await _prefs).setString(key, jsonEncode(rows));
  }

  // ----- clé / valeur -----
  static Future<String?> kvGet(String k) async =>
      (await _prefs).getString('$_kvPrefix$k');

  static Future<void> kvSet(String k, String v) async {
    await (await _prefs).setString('$_kvPrefix$k', v);
  }

  // ----- mesures (mêmes noms de champs que la table SQLite) -----
  static Future<List<Mesure>> listMesures() async {
    final rows = await _read(_kMesures);
    final list = rows
        .where((r) => r['supprime'] == 0)
        .map(Mesure.fromDb)
        .toList();
    list.sort((a, b) => b.mesureLe.compareTo(a.mesureLe));
    return list;
  }

  static Future<void> insertMesure(Mesure m) async {
    final rows = await _read(_kMesures);
    rows.removeWhere((r) => r['client_uuid'] == m.clientUuid);
    rows.add(m.toDb());
    await _write(_kMesures, rows);
  }

  static Future<List<Mesure>> unsyncedMesures() async {
    final rows = await _read(_kMesures);
    return rows.where((r) => r['synced'] == 0).map(Mesure.fromDb).toList();
  }

  static Future<void> markSynced(String uuid, int? serverId) async {
    final rows = await _read(_kMesures);
    for (final r in rows) {
      if (r['client_uuid'] == uuid) {
        r['synced'] = 1;
        r['server_id'] = serverId;
      }
    }
    await _write(_kMesures, rows);
  }

  static Future<void> softDelete(String uuid) async {
    final rows = await _read(_kMesures);
    for (final r in rows) {
      if (r['client_uuid'] == uuid) {
        r['supprime'] = 1;
        r['synced'] = 0;
      }
    }
    await _write(_kMesures, rows);
  }

  static Future<void> upsertServerMesure(Mesure m) async {
    final rows = await _read(_kMesures);
    final i = rows.indexWhere((r) => r['client_uuid'] == m.clientUuid);
    if (i < 0) {
      rows.add(m.toDb());
    } else if (rows[i]['synced'] == 1) {
      rows[i] = m.toDb();
    }
    await _write(_kMesures, rows);
  }

  // ----- prises -----
  static Future<void> addPrise(
      String uuid,
      int traitementId,
      String prisLe,
      String statut,
      ) async {
    final rows = await _read(_kPrises);
    rows.removeWhere((r) => r['client_uuid'] == uuid);
    rows.add({
      'client_uuid': uuid,
      'traitement_id': traitementId,
      'pris_le': prisLe,
      'statut': statut,
    });
    await _write(_kPrises, rows);
  }

  static Future<List<Map<String, Object?>>> pendingPrises() => _read(_kPrises);

  static Future<void> deletePrise(String uuid) async {
    final rows = await _read(_kPrises);
    rows.removeWhere((r) => r['client_uuid'] == uuid);
    await _write(_kPrises, rows);
  }

  static Future<int> pendingCount() async {
    final a = (await _read(_kMesures)).where((r) => r['synced'] == 0).length;
    final b = (await _read(_kPrises)).length;
    return a + b;
  }

  static Future<void> clearAll() async {
    final p = await _prefs;
    await p.remove(_kMesures);
    await p.remove(_kPrises);
    for (final k in p.getKeys().toList()) {
      if (k.startsWith(_kvPrefix)) await p.remove(k);
    }
  }
}