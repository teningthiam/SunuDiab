import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common.dart';

class TreatmentsScreen extends StatelessWidget {
  const TreatmentsScreen({super.key});

  void _showQr(BuildContext context, Ordonnance o) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('pharmacist_qr')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: o.numero,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(o.numero, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.t('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final actifs = data.traitements.where((t) => t.actif).toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.t('treatments'))),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionTitle(context.t('active_treatments')),
                  if (actifs.isEmpty)
                    Text(
                      context.t('no_treatments'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ...actifs.map((t) => _TreatmentCard(t: t, data: data)),
                  SectionTitle(context.t('prescriptions')),
                  if (data.ordonnances.isEmpty)
                    Text(
                      context.t('no_prescriptions'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ...data.ordonnances.map(
                    (o) => AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  o.numero,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (o.dateExpiration != null)
                                Chip2(
                                  label: context.t('expires', {
                                    'd': fmtDate(o.dateExpiration!),
                                  }),
                                  color: AppColors.deepOrange,
                                  soft: AppColors.orangeSoft,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(o.lignes, style: const TextStyle(height: 1.4)),
                          if (o.pharmacie != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                o.pharmacie!,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                            onPressed: () => _showQr(context, o),
                            icon: const Icon(Icons.qr_code_2),
                            label: Text(context.t('pharmacist_qr')),
                          ),
                        ],
                      ),
                    ),
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

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({required this.t, required this.data});
  final Traitement t;
  final DataProvider data;

  @override
  Widget build(BuildContext context) {
    final low = t.stockRestant != null && t.stockRestant! <= 10;
    final last = data.lastPrise[t.id];
    return AppCard(
      accent: low ? AppColors.orange : AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t.medicament}${t.dosage == null ? '' : ' ${t.dosage}'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (t.horaires != null && t.horaires!.isNotEmpty)
                Chip2(
                  label: t.horaires!.replaceAll(',', ' · '),
                  color: AppColors.primary,
                  soft: AppColors.primarySoft,
                  icon: Icons.access_time,
                ),
            ],
          ),
          if (t.posologie != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.posologie!,
                style: const TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ),
          if (t.stockRestant != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip2(
                label: context.t(low ? 'stock_low' : 'stock_n', {
                  'n': '${t.stockRestant}',
                }),
                color: low ? AppColors.deepOrange : AppColors.green,
                soft: low ? AppColors.orangeSoft : AppColors.greenSoft,
                icon: Icons.inventory_2_outlined,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                  ),
                  onPressed: () async {
                    await data.markPrise(t);
                    if (context.mounted)
                      toast(context, context.t('prise_saved'));
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(context.t('i_took_it')),
                ),
              ),
            ],
          ),
          if (last != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.t('last_taken', {'t': fmtDateTime(last)}),
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ),
        ],
      ),
    );
  }
}
