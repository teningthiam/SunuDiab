import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common.dart';
import 'advice_screen.dart';
import 'appointments_screen.dart';
import 'health_profile_screen.dart';
import 'treatments_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showPass(BuildContext context, Profil p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('health_pass')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: p.numeroDossier,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              p.numeroDossier,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(p.nomComplet, style: const TextStyle(color: AppColors.muted)),
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

  Future<void> _chooseDoctor(BuildContext context) async {
    final data = context.read<DataProvider>();
    try {
      final list = await data.medecins();
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle(ctx.t('choose_doctor')),
              ...list.map(
                (m) => ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: Text('Dr. ${m.nomComplet}'),
                  subtitle: Text(
                    [
                      m.specialite,
                      m.structure,
                    ].where((e) => e != null && e.isNotEmpty).join(' • '),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await data.choisirMedecin(m.id);
                    } catch (e) {
                      if (context.mounted) toast(context, errText(context, e));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) toast(context, errText(context, e));
    }
  }

  Future<void> _addContact(BuildContext context) async {
    final nom = TextEditingController();
    final tel = TextEditingController();
    final lien = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('add_contact')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nom, decoration: deco(ctx.t('name'))),
              const SizedBox(height: 10),
              TextField(
                controller: tel,
                keyboardType: TextInputType.phone,
                decoration: deco(ctx.t('phone')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lien,
                decoration: deco(
                  ctx.t('relation'),
                  hint: ctx.t('relation_hint'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.t('save')),
          ),
        ],
      ),
    );
    if (ok == true &&
        nom.text.trim().isNotEmpty &&
        tel.text.trim().isNotEmpty &&
        context.mounted) {
      try {
        await context.read<DataProvider>().ajouterContact(
          nom.text.trim(),
          tel.text.trim(),
          lien.text.trim().isEmpty ? null : lien.text.trim(),
        );
      } catch (e) {
        if (context.mounted) toast(context, errText(context, e));
      }
    }
    nom.dispose();
    tel.dispose();
    lien.dispose();
  }

  Future<void> _togglePref(BuildContext context, String key, bool value) async {
    try {
      await context.read<DataProvider>().updateProfil({key: value});
    } catch (e) {
      if (context.mounted) toast(context, errText(context, e));
    }
  }

  Future<void> _logout(BuildContext context) async {
    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final unsynced = data.pendingCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('logout')),
        content: Text(
          unsynced > 0
              ? ctx.t('logout_pending', {'n': '$unsynced'})
              : ctx.t('logout_q'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.t('logout'),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await data.syncNow(); // dernière tentative d'envoi des saisies hors ligne
    chat.clear();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final online = context.watch<ConnectivityProvider>().online;
    final p = data.profil;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      (auth.user?.prenom.isNotEmpty ?? false)
                          ? auth.user!.prenom[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.nomComplet ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (p != null)
                          Text(
                            '${context.t('file_no')} ${p.numeroDossier}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        if (p != null && p.typeDiabete != 'AUCUN')
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Chip2(
                              label: context.t('diabetes_${p.typeDiabete}'),
                              color: AppColors.primary,
                              soft: AppColors.primarySoft,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (p != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: () => _showPass(context, p),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(context.t('health_pass')),
                ),
              ],
            ],
          ),
        ),
        SectionTitle(context.t('my_care_team')),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.medical_services_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  p?.medecinReferentNom == null
                      ? context.t('no_doctor')
                      : 'Dr. ${p!.medecinReferentNom}',
                ),
                subtitle: Text(context.t('referent_doctor')),
                trailing: TextButton(
                  onPressed: online ? () => _chooseDoctor(context) : null,
                  child: Text(
                    context.t(
                      p?.medecinReferentNom == null ? 'choose' : 'change',
                    ),
                  ),
                ),
              ),
              if (p?.infirmierRelaisNom != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.health_and_safety_outlined,
                    color: AppColors.green,
                  ),
                  title: Text(p!.infirmierRelaisNom!),
                  subtitle: Text(context.t('relay_nurse')),
                  trailing: p.infirmierRelaisTelephone == null
                      ? null
                      : IconButton.filledTonal(
                          onPressed: () =>
                              callNumber(context, p.infirmierRelaisTelephone!),
                          icon: const Icon(Icons.call),
                        ),
                ),
            ],
          ),
        ),
        SectionTitle(
          context.t('emergency_contacts'),
          trailing: TextButton.icon(
            onPressed: online
                ? () => _addContact(context)
                : () => toast(context, context.t('need_connection')),
            icon: const Icon(Icons.add),
            label: Text(context.t('add')),
          ),
        ),
        if (p == null || p.contacts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              context.t('no_contacts'),
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ...(p?.contacts ?? <Contact>[]).map(
          (c) => AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nom,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${c.lien ?? ''} ${c.telephone}'.trim(),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => callNumber(context, c.telephone),
                  icon: const Icon(Icons.call, color: AppColors.green),
                ),
                IconButton(
                  onPressed: online
                      ? () async {
                          try {
                            await data.supprimerContact(c.id);
                          } catch (e) {
                            if (context.mounted)
                              toast(context, errText(context, e));
                          }
                        }
                      : null,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionTitle(context.t('my_health')),
        _NavTile(
          icon: Icons.assignment_ind_outlined,
          title: context.t('health_profile'),
          page: const HealthProfileScreen(),
        ),
        _NavTile(
          icon: Icons.medication_outlined,
          title: context.t('treatments'),
          page: const TreatmentsScreen(),
        ),
        _NavTile(
          icon: Icons.calendar_month_outlined,
          title: context.t('appointments'),
          page: const AppointmentsScreen(),
        ),
        _NavTile(
          icon: Icons.eco_outlined,
          title: context.t('advice'),
          page: const AdviceScreen(),
        ),
        SectionTitle(context.t('settings')),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('language'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'fr', label: Text('Français')),
                  ButtonSegment(value: 'wo', label: Text('Wolof')),
                ],
                selected: {settings.lang},
                onSelectionChanged: (s) => settings.setLang(s.first),
              ),
              if (settings.lang == 'wo')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.t('wo_partial'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.t('share_record')),
                subtitle: Text(
                  context.t('share_record_sub'),
                  style: const TextStyle(fontSize: 12.5),
                ),
                value: p?.partageDossier ?? true,
                onChanged: p == null
                    ? null
                    : (v) => _togglePref(context, 'partageDossier', v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.t('sms_reminders')),
                value: p?.rappelSms ?? true,
                onChanged: p == null
                    ? null
                    : (v) => _togglePref(context, 'rappelSms', v),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t('synchronisation'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (data.pendingCount > 0)
                    Chip2(
                      label: context.t('pending_n_short', {
                        'n': '${data.pendingCount}',
                      }),
                      color: AppColors.deepOrange,
                      soft: AppColors.orangeSoft,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                data.lastSync == null
                    ? context.t('never_synced')
                    : context.t('last_sync', {
                        't':
                            '${data.lastSync!.day}/${data.lastSync!.month} ${data.lastSync!.hour.toString().padLeft(2, '0')}:${data.lastSync!.minute.toString().padLeft(2, '0')}',
                      }),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: data.syncing
                    ? null
                    : () async {
                        if (!online) {
                          toast(context, context.t('offline_banner'));
                          return;
                        }
                        final err = await data.syncNow();
                        if (context.mounted)
                          toast(context, err ?? context.t('sync_done'));
                      },
                icon: const Icon(Icons.sync),
                label: Text(context.t('sync_now')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red,
            side: const BorderSide(color: AppColors.red),
          ),
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: Text(context.t('logout')),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.title, required this.page});
  final IconData icon;
  final String title;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
