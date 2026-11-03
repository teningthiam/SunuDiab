import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/glycemia.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shell_nav.dart';
import '../widgets/common.dart';
import '../widgets/glycemia_chart.dart';
import 'add_measure_screen.dart';
import 'advice_screen.dart';
import 'appointments_screen.dart';
import 'health_profile_screen.dart';
import 'treatments_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final lang = context.watch<SettingsProvider>().lang;
    final nav = context.read<ShellNav>();
    final last = data.mesures.isEmpty ? null : data.mesures.first;
    final name = auth.user?.prenom ?? '';
    final greeting = context.t('greeting', {'name': name});

    final actifs = data.traitements.where((t) => t.actif).toList();
    final next = actifs.isEmpty ? null : actifs.first;
    final conseil = data.conseils.isEmpty
        ? null
        : data.conseils[DateTime.now().day % data.conseils.length];

    return RefreshIndicator(
      onRefresh: () async {
        await data.syncNow();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.greenSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face,
                    color: AppColors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.lastSync == null
                            ? context.t('never_synced')
                            : context.t('synced_ago', {
                                't': timeAgo(context, data.lastSync!),
                              }),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                AudioButton(text: greeting),
              ],
            ),
          ),
          if (data.pendingCount > 0)
            AppCard(
              color: AppColors.orangeSoft,
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.deepOrange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.t('pending_n', {'n': '${data.pendingCount}'}),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          if (data.profil != null && !data.profil!.aProfilSante)
            AppCard(
              color: AppColors.primarySoft,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HealthProfileScreen()),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_ind_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.t('complete_profile'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          _LastGlycemiaCard(last: last, data: data),
          SectionTitle(context.t('quick_actions')),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _Action(
                icon: Icons.water_drop,
                title: context.t('add_glycemia'),
                filled: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddMeasureScreen()),
                ),
              ),
              _Action(
                icon: Icons.fact_check_outlined,
                title: context.t('risk_test'),
                sub: context.t('three_min'),
                onTap: () => nav.go(2),
              ),
              _Action(
                icon: Icons.smart_toy_outlined,
                title: context.t('nav_assistant'),
                sub: context.t('assistant_sub'),
                onTap: () => nav.go(3),
              ),
              _Action(
                icon: Icons.calendar_month_outlined,
                title: context.t('appointments'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (next != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.t('next_medication'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (next.horaires != null && next.horaires!.isNotEmpty)
                        Chip2(
                          label: next.horaires!.replaceAll(',', ' · '),
                          color: AppColors.deepOrange,
                          soft: AppColors.orangeSoft,
                          icon: Icons.access_time,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${next.medicament}${next.dosage == null ? '' : ' ${next.dosage}'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (next.posologie != null)
                    Text(
                      next.posologie!,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                          ),
                          onPressed: () async {
                            await data.markPrise(next);
                            if (context.mounted)
                              toast(context, context.t('prise_saved'));
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(context.t('i_took_it')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TreatmentsScreen(),
                          ),
                        ),
                        child: Text(context.t('see_all')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (conseil != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco_outlined, color: AppColors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.t('tip_of_day'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      AudioButton(
                        text: '${conseil.title(lang)}. ${conseil.body(lang)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conseil.title(lang),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conseil.body(lang),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdviceScreen()),
                    ),
                    child: Text(context.t('more_tips')),
                  ),
                ],
              ),
            ),
          const EmergencyCard(),
        ],
      ),
    );
  }
}

class _LastGlycemiaCard extends StatelessWidget {
  const _LastGlycemiaCard({required this.last, required this.data});
  final Mesure? last;
  final DataProvider data;

  @override
  Widget build(BuildContext context) {
    final m = last;
    if (m == null) {
      return AppCard(
        child: Column(
          children: [
            const Icon(
              Icons.water_drop_outlined,
              size: 40,
              color: AppColors.muted,
            ),
            const SizedBox(height: 8),
            Text(
              context.t('no_measure_yet'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddMeasureScreen()),
              ),
              child: Text(context.t('add_glycemia')),
            ),
          ],
        ),
      );
    }
    final GStatus st = m.statut;
    final week = data.mesuresSince(7);
    final inTarget = week.isEmpty
        ? 0
        : (week.where((x) => x.statut == GStatus.normal).length *
                  100 /
                  week.length)
              .round();
    return AppCard(
      accent: statusColor(st),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${context.t('last_glycemia')} • ${context.t(momentKey(m.moment))}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusChip(st),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            fmtDateTime(m.mesureLe),
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtValue(m.valeur),
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'g/L',
                  style: TextStyle(fontSize: 18, color: AppColors.muted),
                ),
              ),
              const Spacer(),
              AudioButton(
                text: context.t('speak_glycemia', {
                  'v': fmtValue(m.valeur),
                  's': context.t(statusKey(st)),
                }),
              ),
            ],
          ),
          Text(
            context.t('target_range', {
              'a': fmtValue(data.cibleMin),
              'b': fmtValue(data.cibleMax),
            }),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t('evolution_7d'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (week.isNotEmpty)
                Text(
                  context.t('in_target_pct', {'n': '$inTarget'}),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          GlycemiaChart(
            data: week,
            cmin: data.cibleMin,
            cmax: data.cibleMax,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    this.sub,
    this.filled = false,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? sub;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : AppColors.primary,
              size: 28,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: TextStyle(
                      color: filled ? Colors.white70 : AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
