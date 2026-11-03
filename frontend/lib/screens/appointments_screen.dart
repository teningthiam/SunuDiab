import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../providers/connectivity_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common.dart';
import 'book_appointment_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  Color _statusColor(String s) {
    switch (s) {
      case 'CONFIRME':
        return AppColors.green;
      case 'ANNULE':
        return AppColors.red;
      case 'TERMINE':
        return AppColors.muted;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final online = context.watch<ConnectivityProvider>().online;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('appointments'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!online) {
            toast(context, context.t('need_connection'));
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(context.t('book_appointment')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: data.rdvs.isEmpty
                  ? Center(
                      child: Text(
                        context.t('no_appointments'),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      children: data.rdvs.map((r) {
                        final c = _statusColor(r.statut);
                        return AppCard(
                          accent: c,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${fmtDay(r.dateHeure)} • ${fmtTime(r.dateHeure)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Chip2(
                                    label: context.t('rdv_${r.statut}'),
                                    color: c,
                                    soft: AppColors.bg,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Dr. ${r.medecinNom}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${context.t('mode_${r.mode}')}${r.lieu == null ? '' : ' • ${r.lieu}'}',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                              if (r.motif != null && r.motif!.isNotEmpty)
                                Text(
                                  r.motif!,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              if (r.annulable)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () async {
                                      try {
                                        await data.cancelRdv(r.id);
                                        if (context.mounted)
                                          toast(
                                            context,
                                            context.t('rdv_cancelled'),
                                          );
                                      } catch (e) {
                                        if (context.mounted)
                                          toast(context, errText(context, e));
                                      }
                                    },
                                    child: Text(
                                      context.t('cancel_appointment'),
                                      style: const TextStyle(
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
