import '../core/api_client.dart';
import '../core/local_db.dart';
import '../models/models.dart';

import 'dart:convert';

/// Synchronisation : 1) envoi des saisies hors ligne (idempotent via clientUuid), 2) récupération des changements.
class SyncService {
  SyncService(this.api);
  final ApiClient api;

  Future<void> sync() async {
    final mesures = await LocalDb.unsyncedMesures();
    final prises = await LocalDb.pendingPrises();

    if (mesures.isNotEmpty || prises.isNotEmpty) {
      final res = await api.post(
        '/api/sync',
        body: {
          'mesures': mesures.map((m) => m.toSyncJson()).toList(),
          'prises': prises
              .map(
                (p) => {
                  'clientUuid': p['client_uuid'],
                  'traitementId': p['traitement_id'],
                  'prisLe': p['pris_le'],
                  'statut': p['statut'],
                },
              )
              .toList(),
        },
      );
      for (final r in (res['resultats'] as List)) {
        if (r['statut'] == 'OK') {
          final uuid = r['clientUuid'] as String;
          await LocalDb.markSynced(uuid, (r['serverId'] as num?)?.toInt());
          await LocalDb.deletePrise(uuid);
        }
      }
    }

    final since = await LocalDb.kvGet('server_time');
    final data = await api.get(
      '/api/sync',
      query: since == null ? null : {'since': since},
    );

    if (data['profil'] != null)
      await LocalDb.kvSet('profil', jsonEncode(data['profil']));
    for (final m in (data['mesures'] as List)) {
      await LocalDb.upsertServerMesure(
        Mesure.fromServer(Map<String, dynamic>.from(m as Map)),
      );
    }
    await LocalDb.mergeList('traitements', data['traitements'] as List);
    await LocalDb.mergeList('rdv', data['rendezVous'] as List);
    await LocalDb.mergeList('ordonnances', data['ordonnances'] as List);
    await LocalDb.mergeList('conseils', data['conseils'] as List);

    // marge de 5 s pour ne rien manquer en cas de décalage d'horloge
    final st = DateTime.parse(data['serverTime'] as String)
        .subtract(const Duration(seconds: 5));
    await LocalDb.kvSet('server_time', st.toUtc().toIso8601String());
  }
}
