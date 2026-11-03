import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/glycemia.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common.dart';
import '../widgets/glycemia_chart.dart';
import 'add_measure_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  int _days = 7;
  String? _moment;

  Future<void> _confirmDelete(Mesure m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('delete_measure')),
        content: Text(ctx.t('delete_measure_q')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.t('delete'),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted)
      await context.read<DataProvider>().deleteMesure(m);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final pts = data.mesuresSince(_days);
    final inTarget = pts.where((m) => m.statut == GStatus.normal).length;
    final pct = pts.isEmpty ? 0 : (inTarget * 100 / pts.length).round();
    final avg = pts.isEmpty
        ? null
        : pts.map((m) => m.valeur).reduce((a, b) => a + b) / pts.length;
    final list = data.mesures
        .where((m) => _moment == null || m.moment == _moment)
        .take(60)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.t('my_tracking'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 7,
              label: Text(context.t('days_n', {'n': '7'})),
            ),
            ButtonSegment(
              value: 30,
              label: Text(context.t('days_n', {'n': '30'})),
            ),
            ButtonSegment(
              value: 90,
              label: Text(context.t('days_n', {'n': '90'})),
            ),
          ],
          selected: {_days},
          onSelectionChanged: (s) => setState(() => _days = s.first),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t('glycemia_evolution'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Chip2(
                    label: context.t('target_range', {
                      'a': fmtValue(data.cibleMin),
                      'b': fmtValue(data.cibleMax),
                    }),
                    color: AppColors.green,
                    soft: AppColors.greenSoft,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlycemiaChart(
                data: pts,
                cmin: data.cibleMin,
                cmax: data.cibleMax,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: context.t('average'),
                value: avg == null ? '—' : fmtValue(avg),
                unit: 'g/L',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: context.t('in_target'),
                value: '$pct%',
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: context.t('measures'),
                value: '${pts.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pts.length >= 3 && pct >= 70)
          AppCard(
            color: AppColors.greenSoft,
            child: Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t('well_done'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        SectionTitle(context.t('history')),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(context.t('all')),
                  selected: _moment == null,
                  onSelected: (_) => setState(() => _moment = null),
                ),
              ),
              ...kMoments.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(context.t(momentKey(m))),
                    selected: _moment == m,
                    onSelected: (_) => setState(() => _moment = m),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                context.t('no_measure_yet'),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        ...list.map(
          (m) => AppCard(
            accent: statusColor(m.statut),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      fmtValue(m.valeur),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('g/L', style: TextStyle(color: AppColors.muted)),
                    const Spacer(),
                    StatusChip(m.statut),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.muted,
                      ),
                      onPressed: () => _confirmDelete(m),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${context.t(momentKey(m.moment))} • ${fmtDateTime(m.mesureLe)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SyncIcon(synced: m.synced),
                  ],
                ),
                if (m.contexte != null && m.contexte!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      m.contexte!,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddMeasureScreen())),
          icon: const Icon(Icons.add_circle_outline),
          label: Text(context.t('add_measure')),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.unit,
    this.color = AppColors.primary,
  });
  final String label;
  final String value;
  final String? unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (unit != null)
            Text(
              unit!,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
