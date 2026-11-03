import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import 'connectivity_provider.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this.api, this.conn);

  final ApiClient api;
  final ConnectivityProvider conn;
  List<ChatMsg> messages = [];
  bool sending = false;
  bool loaded = false;

  Future<void> loadHistory() async {
    if (!conn.online || loaded) return;
    try {
      final j = await api.get('/api/patient/chat');
      messages = (j as List)
          .map((e) => ChatMsg.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      loaded = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || sending) return;
    messages = [...messages, ChatMsg(auteur: 'PATIENT', contenu: t)];
    sending = true;
    notifyListeners();
    try {
      final j = await api.post('/api/patient/chat', body: {'message': t});
      messages = [
        ...messages,
        ChatMsg(
          auteur: 'ASSISTANT',
          contenu: (j['reponse'] ?? '') as String,
          urgence: j['urgence'] == true,
        ),
      ];
    } on ApiException catch (e) {
      messages = [
        ...messages,
        ChatMsg(
          auteur: 'ASSISTANT',
          contenu: e.isNetwork ? 'OFFLINE' : e.message,
          erreur: true,
        ),
      ];
    }
    sending = false;
    notifyListeners();
  }

  void clear() {
    messages = [];
    loaded = false;
    notifyListeners();
  }
}
