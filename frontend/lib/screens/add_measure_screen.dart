import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/glycemia.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../providers/connectivity_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common.dart';

class AddMeasureScreen extends StatefulWidget {
  const AddMeasureScreen({super.key});

  @override
  State<AddMeasureScreen> createState() => _AddMeasureScreenState();
}

class _AddMeasureScreenState extends State<AddMeasureScreen> {
  static const _contextKeys = [
    'ctx_ceebu',
    'ctx_fonio',
    'ctx_metformin',
    'ctx_dizzy',
    'ctx_walk',
  ];

  String _buf = '';
  String _moment = 'A_JEUN';
  final Set<String> _ctx = {};
  String? _error;
  bool _saving = false;

  double? get _value => double.tryParse(_buf);

  void _press(String k) {
    setState(() {
      _error = null;
      if (k == '<') {
        if (_buf.isNotEmpty) _buf = _buf.substring(0, _buf.length - 1);
      } else if (k == '.') {
        if (!_buf.contains('.')) _buf = _buf.isEmpty ? '0.' : '$_buf.';
      } else if (_buf.length < 5) {
        _buf += k;
      }
    });
  }

  Future<void> _save() async {
    final v = _value;
    if (v == null || v < 0.2 || v > 6.0) {
      setState(() => _error = context.t('measure_invalid'));
      return;
    }
    setState(() => _saving = true);
    final data = context.read<DataProvider>();
    final contexte = _ctx.map((k) => context.t(k)).join(', ');
    final m = await data.addMesure(
      valeur: v,
      moment: _moment,
      contexte: contexte.isEmpty ? null : contexte,
    );
    if (!mounted) return;
    final urgent = isUrgent(m.statut);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text('${fmtValue(m.valeur)} g/L')),
            StatusChip(m.statut),
          ],
        ),
        content: Text(ctx.t(interpKey(m.statut))),
        actions: [
          if (urgent)
            CallButton(number: kSamuNumber, label: ctx.t('call_samu')),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.t('ok')),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityProvider>().online;
    final data = context.watch<DataProvider>();
    final v = _value;
    final preview = (v != null && v >= 0.2 && v <= 6.0)
        ? statusFromValue(v, data.cibleMin, data.cibleMax)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('new_measure'))),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    context.t('measure_moment'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: kMoments
                        .map(
                          (m) => ChoiceChip(
                            label: Text(context.t(momentKey(m))),
                            selected: _moment == m,
                            onSelected: (_) => setState(() => _moment = m),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    accent: preview == null
                        ? AppColors.border
                        : statusColor(preview),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop_outlined,
                              color: AppColors.muted,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.t('measured_value'),
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            const Spacer(),
                            if (preview != null) StatusChip(preview),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _buf.isEmpty ? '0.00' : _buf,
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                color: _buf.isEmpty
                                    ? AppColors.border
                                    : AppColors.text,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'g/L',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          context.t('target_range', {
                            'a': fmtValue(data.cibleMin),
                            'b': fmtValue(data.cibleMax),
                          }),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _Keypad(onKey: _press),
                  const SizedBox(height: 8),
                  Text(
                    context.t('context_optional'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _contextKeys
                        .map(
                          (k) => FilterChip(
                            label: Text(context.t(k)),
                            selected: _ctx.contains(k),
                            onSelected: (s) => setState(
                              () => s ? _ctx.add(k) : _ctx.remove(k),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(context.t('save_measure')),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        online ? Icons.cloud_done_outlined : Icons.cloud_off,
                        size: 16,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          context.t(
                            online ? 'will_sync_now' : 'saved_offline_hint',
                          ),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final void Function(String) onKey;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '<'],
    ];
    return Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: r
                    .map(
                      (k) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarySoft,
                                foregroundColor: AppColors.text,
                                elevation: 0,
                                minimumSize: const Size(0, 58),
                                textStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () => onKey(k),
                              child: k == '<'
                                  ? const Icon(Icons.backspace_outlined)
                                  : Text(k),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}
