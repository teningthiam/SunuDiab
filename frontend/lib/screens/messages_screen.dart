import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/data_provider.dart';
import '../providers/messages_provider.dart';
import '../widgets/common.dart';

class _Who {
  final int id;
  final String name;
  final String role;
  const _Who(this.id, this.name, this.role);
}

class _Msg {
  final int fromId;
  final String text;
  final DateTime at;
  const _Msg(this.fromId, this.text, this.at);
}

/// Messagerie avec le médecin référent et l'infirmier relais.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<_Who> _contacts = [];
  int? _selected;
  List<_Msg> _msgs = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final p = context.read<DataProvider>().profil;
    final c = <_Who>[];
    if (p != null) {
      final m = p.raw['medecinReferentId'];
      if (m is num)
        c.add(_Who(m.toInt(), 'Dr. ${p.medecinReferentNom ?? ''}', 'doctor'));
      final r = p.raw['infirmierRelaisId'];
      if (r is num) c.add(_Who(r.toInt(), p.infirmierRelaisNom ?? '', 'relay'));
    }
    _contacts = c;
    if (c.isNotEmpty) {
      _selected = c.first.id;
      unawaited(_load());
      _timer = Timer.periodic(
        const Duration(seconds: 10),
            (_) => _load(silent: true),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final id = _selected;
    if (id == null || !context.read<ConnectivityProvider>().online) return;
    final api = context.read<ApiClient>();
    final messages = context.read<MessagesProvider>();
    if (!silent) setState(() => _loading = true);
    try {
      final j = await api.get('/api/messages/$id');
      final list = (j as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return _Msg(
          (m['expediteurId'] as num).toInt(),
          (m['contenu'] ?? '') as String,
          DateTime.parse(m['createdAt'] as String),
        );
      }).toList();
      if (!mounted) return;
      final grew = list.length != _msgs.length;
      setState(() {
        _msgs = list;
        _error = null;
      });
      if (grew) _toBottom();
      unawaited(messages.refreshUnread());
    } catch (e) {
      if (mounted && !silent) setState(() => _error = errText(context, e));
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final id = _selected;
    if (text.isEmpty || id == null || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<ApiClient>().post(
        '/api/messages',
        body: {'destinataireId': id, 'contenu': text},
      );
      _input.clear();
      await _load(silent: true);
    } catch (e) {
      if (mounted) toast(context, errText(context, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityProvider>().online;
    final myId = context.watch<AuthProvider>().user?.id ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('messages'))),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            if (_contacts.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.t('messages_no_contact'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              if (_contacts.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    children: _contacts
                        .map(
                          (c) => ChoiceChip(
                        label: Text(c.name),
                        selected: _selected == c.id,
                        onSelected: (_) {
                          setState(() {
                            _selected = c.id;
                            _msgs = [];
                          });
                          unawaited(_load());
                        },
                      ),
                    )
                        .toList(),
                  ),
                ),
              Expanded(
                child: _loading && _msgs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _msgs.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error ??
                          context.t(
                            online
                                ? 'messages_empty'
                                : 'messages_offline',
                          ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
                    : ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  children: _msgs
                      .map((m) => _bubble(m, m.fromId == myId))
                      .toList(),
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: online,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: deco(
                          context.t(
                            online ? 'message_hint' : 'messages_offline',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: (online && !_sending) ? _send : null,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bubble(_Msg m, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(
                color: mine ? Colors.white : AppColors.text,
                height: 1.35,
                fontSize: 15.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fmtDateTime(m.at),
              style: TextStyle(
                color: mine ? Colors.white70 : AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}