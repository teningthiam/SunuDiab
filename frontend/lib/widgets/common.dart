import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/glycemia.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../providers/connectivity_provider.dart';
import '../providers/settings_provider.dart';
import '../services/tts_service.dart';

/// Carte blanche arrondie, avec barre de couleur optionnelle à gauche.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.accent,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? accent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final inner = accent == null
        ? Padding(padding: padding, child: child)
        : IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 5, color: accent),
          Expanded(
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B2433),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(15), child: inner),
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final GStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip2(
      label: context.t(statusKey(status)),
      color: statusColor(status),
      soft: statusSoft(status),
    );
  }
}

class Chip2 extends StatelessWidget {
  const Chip2({
    super.key,
    required this.label,
    required this.color,
    required this.soft,
    this.icon,
  });
  final String label;
  final Color color;
  final Color soft;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityProvider>().online;
    if (online) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: AppColors.orangeSoft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 20, color: AppColors.deepOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t('offline_banner'),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SyncIcon extends StatelessWidget {
  const SyncIcon({super.key, required this.synced});
  final bool synced;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.t(synced ? 'synced' : 'pending_sync'),
      child: Icon(
        synced ? Icons.cloud_done_outlined : Icons.schedule,
        size: 18,
        color: synced ? AppColors.green : AppColors.orange,
      ),
    );
  }
}

/// Bouton « Écouter » : lecture vocale en français. Le wolof audio nécessite des enregistrements validés.
class AudioButton extends StatelessWidget {
  const AudioButton({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: context.t('listen'),
      icon: const Icon(Icons.volume_up),
      onPressed: () {
        if (context.read<SettingsProvider>().lang == 'wo') {
          toast(context, context.t('audio_wo_soon'));
        } else {
          TtsService.speak(text);
        }
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.redSoft,
      child: Row(
        children: [
          const Icon(Icons.emergency, color: AppColors.red, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('emergency_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.t('emergency_sub'),
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const CallButton(number: kSamuNumber),
        ],
      ),
    );
  }
}

class CallButton extends StatelessWidget {
  const CallButton({super.key, required this.number, this.label});
  final String number;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => callNumber(context, number),
      icon: const Icon(Icons.call, size: 18),
      label: Text(label ?? number),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    );
  }
}

Future<void> callNumber(BuildContext context, String number) async {
  final ok = await launchUrl(Uri.parse('tel:$number'));
  if (!ok && context.mounted)
    toast(context, context.t('call_failed', {'n': number}));
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

String errText(BuildContext context, Object e) {
  if (e is ApiException) {
    if (e.isNetwork) return context.t('err_network');
    if (e.status == 401) return context.t('err_session');
    return e.message;
  }
  // ignore: avoid_print
  print('ERREUR APP: ${e.runtimeType}: $e');
  return '${context.t('err_generic')} (${e.runtimeType})';
}

InputDecoration deco(
    String label, {
      String? hint,
      IconData? icon,
      String? suffix,
    }) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixText: suffix,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );
}

/// Carte de choix (réponses du test de risque, modes de rendez-vous...).
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.label,
    this.sub,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sub!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
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