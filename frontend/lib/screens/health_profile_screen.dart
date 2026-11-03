import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../l10n/strings.dart';
import '../providers/data_provider.dart';
import '../widgets/common.dart';

/// Profil de santé : taille, poids, tour de taille, tension, antécédents... (nécessite une connexion pour enregistrer).
class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final _taille = TextEditingController();
  final _poids = TextEditingController();
  final _tour = TextEditingController();
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _quartier = TextEditingController();
  final _ville = TextEditingController();
  final _ipm = TextEditingController();
  String _region = 'Dakar';
  bool _antecedents = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<DataProvider>().profil;
    if (p != null) {
      _taille.text = p.tailleCm?.toStringAsFixed(0) ?? '';
      _poids.text = p.poidsKg?.toStringAsFixed(0) ?? '';
      _tour.text = p.tourTailleCm?.toStringAsFixed(0) ?? '';
      _sys.text = p.tensionSystolique?.toString() ?? '';
      _dia.text = p.tensionDiastolique?.toString() ?? '';
      _quartier.text = p.quartier ?? '';
      _ville.text = p.ville ?? '';
      _ipm.text = p.couvertureIpm ?? '';
      _antecedents = p.antecedentsFamiliaux;
      if (p.region != null && kRegions.contains(p.region)) _region = p.region!;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _taille,
      _poids,
      _tour,
      _sys,
      _dia,
      _quartier,
      _ville,
      _ipm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final body = <String, dynamic>{
      'antecedentsFamiliaux': _antecedents,
      'region': _region,
      'quartier': _quartier.text.trim(),
      'ville': _ville.text.trim(),
      'couvertureIpm': _ipm.text.trim(),
    };
    final t = double.tryParse(_taille.text.replaceAll(',', '.'));
    final p = double.tryParse(_poids.text.replaceAll(',', '.'));
    final w = double.tryParse(_tour.text.replaceAll(',', '.'));
    final s = int.tryParse(_sys.text);
    final d = int.tryParse(_dia.text);
    if (t != null) body['tailleCm'] = t;
    if (p != null) body['poidsKg'] = p;
    if (w != null) body['tourTailleCm'] = w;
    if (s != null) body['tensionSystolique'] = s;
    if (d != null) body['tensionDiastolique'] = d;
    setState(() => _saving = true);
    try {
      await context.read<DataProvider>().updateProfil(body);
      if (!mounted) return;
      toast(context, context.t('saved'));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, errText(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _num(TextEditingController c, String label, {String? suffix}) =>
      TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: deco(label, suffix: suffix),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('health_profile'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const OfflineBanner(),
            Row(
              children: [
                Expanded(
                  child: _num(_taille, context.t('height'), suffix: 'cm'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _num(_poids, context.t('weight'), suffix: 'kg'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _num(_tour, context.t('waist'), suffix: 'cm'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _num(_sys, context.t('bp_sys'), suffix: 'mmHg'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _num(_dia, context.t('bp_dia'), suffix: 'mmHg'),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('family_history')),
              value: _antecedents,
              onChanged: (v) => setState(() => _antecedents = v),
            ),
            DropdownButtonFormField<String>(
              value: _region,
              decoration: deco(context.t('region')),
              items: kRegions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _region = v ?? 'Dakar'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _ville, decoration: deco(context.t('city'))),
            const SizedBox(height: 12),
            TextField(
              controller: _quartier,
              decoration: deco(context.t('district')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipm,
              decoration: deco(context.t('insurance'), hint: 'IPM Dakar'),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.t('save')),
            ),
          ],
        ),
      ),
    );
  }
}
