import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/common.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _input.clear();
    final chat = context.read<ChatProvider>();
    final f = chat.send(text);
    _toBottom();
    await f;
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final online = context.watch<ConnectivityProvider>().online;
    final List<String> suggestions = [
      context.t('chat_sug1'),
      context.t('chat_sug2'),
      context.t('chat_sug3'),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t('assistant_name'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                context.t('assistant_langs'),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.t('assistant_disclaimer'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const EmergencyCard(),
              if (chat.messages.isEmpty)
                _bubble(
                  context,
                  ChatMsg(
                    auteur: 'ASSISTANT',
                    contenu: context.t('chat_welcome'),
                  ),
                ),
              ...chat.messages.map((m) => _bubble(context, m)),
              if (chat.sending)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              if (!online) ...[
                SectionTitle(context.t('offline_tips')),
                _tip(context, 'tip_hypo_title', 'tip_hypo_body'),
                _tip(context, 'tip_alarm_title', 'tip_alarm_body'),
                _tip(context, 'tip_meal_title', 'tip_meal_body'),
              ],
            ],
          ),
        ),
        if (online)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: suggestions
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(s),
                        onPressed: chat.sending ? null : () => _send(s),
                      ),
                    ),
                  )
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
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: deco(
                    context.t(online ? 'chat_hint' : 'chat_offline_short'),
                  ).copyWith(counterText: ''),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: (online && !chat.sending)
                    ? () => _send(_input.text)
                    : null,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tip(BuildContext context, String title, String body) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t(title),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(context.t(body), style: const TextStyle(height: 1.4)),
      ],
    ),
  );

  Widget _bubble(BuildContext context, ChatMsg m) {
    final mine = m.fromPatient;
    String text = m.contenu;
    if (m.erreur && text == 'OFFLINE') text = context.t('chat_offline_short');
    final bg = mine
        ? AppColors.primary
        : (m.urgence
              ? AppColors.redSoft
              : (m.erreur ? AppColors.orangeSoft : Colors.white));
    final fg = mine ? Colors.white : AppColors.text;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: m.urgence ? AppColors.red : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.urgence)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  context.t('urgent'),
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Text(
              text,
              style: TextStyle(color: fg, height: 1.4, fontSize: 15.5),
            ),
            if (m.urgence)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: CallButton(number: '1515'),
              ),
            if (!mine && !m.erreur)
              Align(
                alignment: Alignment.centerRight,
                child: AudioButton(text: text),
              ),
          ],
        ),
      ),
    );
  }
}
