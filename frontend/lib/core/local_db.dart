import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Base locale (offline-first) : mesures, file d'attente des prises, cache clé/valeur.
/// Pour chiffrer la base (données de santé) : migrer vers sqflite_sqlcipher.
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
    final d = await db;
    final r = await d.query('kv', where: 'k = ?', whereArgs: [k], limit: 1);
    return r.isEmpty ? null : r.first['v'] as String;
  }

  static Future<void> kvSet(String k, String v) async {
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
    final d = await db;
    final r = await d.query(
      'mesures',
      where: 'supprime = 0',
      orderBy: 'mesure_le DESC',
    );
    return r.map(Mesure.fromDb).toList();
  }

  static Future<void> insertMesure(Mesure m) async {
    final d = await db;
    await d.insert(
      'mesures',
      m.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Mesure>> unsyncedMesures() async {
    final d = await db;
    final r = await d.query('mesures', where: 'synced = 0');
    return r.map(Mesure.fromDb).toList();
  }

  static Future<void> markSynced(String uuid, int? serverId) async {
    final d = await db;
    await d.update(
      'mesures',
      {'synced': 1, 'server_id': serverId},
      where: 'client_uuid = ?',
      whereArgs: [uuid],
    );
  }

  static Future<void> softDelete(String uuid) async {
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
    final d = await db;
    await d.insert('prises_pending', {
      'client_uuid': uuid,
      'traitement_id': traitementId,
      'pris_le': prisLe,
      'statut': statut,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, Object?>>> pendingPrises() async {
    final d = await db;
    return d.query('prises_pending');
  }

  static Future<void> deletePrise(String uuid) async {
    final d = await db;
    await d.delete(
      'prises_pending',
      where: 'client_uuid = ?',
      whereArgs: [uuid],
    );
  }

  static Future<int> pendingCount() async {
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
    final d = await db;
    await d.delete('mesures');
    await d.delete('prises_pending');
    await d.delete('kv');
  }
}
