import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/findrisc.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../providers/data_provider.dart';
import '../providers/shell_nav.dart';
import '../widgets/common.dart';
import 'book_appointment_screen.dart';

enum _Phase { intro, running, result }

class RiskTestScreen extends StatefulWidget {
  const RiskTestScreen({super.key});

  @override
  State<RiskTestScreen> createState() => _RiskTestScreenState();
}

class _RiskTestScreenState extends State<RiskTestScreen> {
  static const int _steps = 8;
  _Phase _phase = _Phase.intro;
  int _step = 0;
  String? _error;
  RisqueResult? _res;

  final _age = TextEditingController();
  final _taille = TextEditingController();
  final _poids = TextEditingController();
  final _tour = TextEditingController();
  String _sexe = 'F';
  String? _activite;
  bool? _fruits;
  bool? _hta;
  bool? _glyc;
  String? _antec;

  @override
  void dispose() {
    _age.dispose();
    _taille.dispose();
    _poids.dispose();
    _tour.dispose();
    super.dispose();
  }

  void _start() {
    final p = context.read<DataProvider>().profil;
    if (p != null) {
      if (p.age != null) _age.text = '${p.age}';
      if (p.sexe == 'M' || p.sexe == 'F') _sexe = p.sexe!;
      if (p.tailleCm != null) _taille.text = p.tailleCm!.toStringAsFixed(0);
      if (p.poidsKg != null) _poids.text = p.poidsKg!.toStringAsFixed(0);
      if (p.tourTailleCm != null)
        _tour.text = p.tourTailleCm!.toStringAsFixed(0);
    }
    setState(() {
      _phase = _Phase.running;
      _step = 0;
      _error = null;
    });
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  String? _validate() {
    switch (_step) {
      case 0:
        final a = int.tryParse(_age.text);
        return (a == null || a < 18 || a > 120) ? context.t('err_age') : null;
      case 1:
        final t = _num(_taille);
        final p = _num(_poids);
        if (t == null || t < 100 || t > 250) return context.t('err_height');
        if (p == null || p < 25 || p > 300) return context.t('err_weight');
        return null;
      case 2:
        final w = _num(_tour);
        return (w == null || w < 40 || w > 250) ? context.t('err_waist') : null;
      case 3:
        return _activite == null ? context.t('choose_answer') : null;
      case 4:
        return _fruits == null ? context.t('choose_answer') : null;
      case 5:
        return _hta == null ? context.t('choose_answer') : null;
      case 6:
        return _glyc == null ? context.t('choose_answer') : null;
      default:
        return _antec == null ? context.t('choose_answer') : null;
    }
  }

  Future<void> _next() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (_step < _steps - 1) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }
    final input = RisqueInput()
      ..age = int.parse(_age.text)
      ..sexe = _sexe
      ..tailleCm = _num(_taille)!
      ..poidsKg = _num(_poids)!
      ..tourTailleCm = _num(_tour)!
      ..activite = _activite!
      ..fruitsLegumes = _fruits!
      ..hypertension = _hta!
      ..glycemieElevee = _glyc!
      ..antecedents = _antec!;
    final r = await context.read<DataProvider>().evaluateRisk(input);
    if (!mounted) return;
    setState(() {
      _res = r;
      _phase = _Phase.result;
    });
  }

  void _back() {
    if (_step == 0) {
      setState(() => _phase = _Phase.intro);
    } else {
      setState(() {
        _step--;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.intro:
        return _intro(context);
      case _Phase.running:
        return _question(context);
      case _Phase.result:
        return _result(context, _res!);
    }
  }

  // ---------- introduction ----------
  Widget _intro(BuildContext context) {
    final last = context.watch<DataProvider>().lastRisk;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.t('risk_test'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          context.t('risk_intro'),
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (last != null)
          AppCard(
            accent: _levelColor(last.niveau),
            onTap: () => setState(() {
              _res = last;
              _phase = _Phase.result;
            }),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('last_result'),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.t('risk_level_${last.niveau}'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _levelColor(last.niveau),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${last.score}/${RisqueResult.scoreMax}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        AppCard(
          color: AppColors.primarySoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t('risk_disclaimer'),
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _start,
          child: Text(context.t(last == null ? 'start_test' : 'redo_test')),
        ),
      ],
    );
  }

  // ---------- question ----------
  Widget _question(BuildContext context) {
    final title = context.t('q${_step + 1}_title');
    final hint = context.t('q${_step + 1}_hint');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.t('risk_test'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Chip2(
              label: context.t('step_of', {
                'a': '${_step + 1}',
                'b': '$_steps',
              }),
              color: AppColors.primary,
              soft: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_step + 1) / _steps,
            minHeight: 8,
            backgroundColor: AppColors.border,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
            AudioButton(text: '$title $hint'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: const TextStyle(color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 16),
        _answers(context),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
                label: Text(context.t('previous')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _next,
                child: Text(
                  context.t(_step == _steps - 1 ? 'see_result' : 'next'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numField(TextEditingController c, String label, String suffix) =>
      TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: deco(label, suffix: suffix),
      );

  Widget _yesNo(bool? value, void Function(bool) set) => Column(
    children: [
      OptionCard(
        label: context.t('yes'),
        selected: value == true,
        onTap: () => setState(() {
          set(true);
          _error = null;
        }),
      ),
      OptionCard(
        label: context.t('no'),
        selected: value == false,
        onTap: () => setState(() {
          set(false);
          _error = null;
        }),
      ),
    ],
  );

  Widget _answers(BuildContext context) {
    switch (_step) {
      case 0:
        return Column(
          children: [
            _numField(_age, context.t('age'), context.t('years')),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'F', label: Text(context.t('sexe_f'))),
                ButtonSegment(value: 'M', label: Text(context.t('sexe_m'))),
              ],
              selected: {_sexe},
              onSelectionChanged: (s) => setState(() => _sexe = s.first),
            ),
          ],
        );
      case 1:
        return Row(
          children: [
            Expanded(child: _numField(_taille, context.t('height'), 'cm')),
            const SizedBox(width: 12),
            Expanded(child: _numField(_poids, context.t('weight'), 'kg')),
          ],
        );
      case 2:
        return _numField(_tour, context.t('waist'), 'cm');
      case 3:
        return Column(
          children: [
            for (final a in const ['QUOTIDIEN', 'PARFOIS', 'RAREMENT'])
              OptionCard(
                label: context.t('act_$a'),
                sub: context.t('act_${a}_sub'),
                selected: _activite == a,
                onTap: () => setState(() {
                  _activite = a;
                  _error = null;
                }),
              ),
          ],
        );
      case 4:
        return _yesNo(_fruits, (v) => _fruits = v);
      case 5:
        return _yesNo(_hta, (v) => _hta = v);
      case 6:
        return _yesNo(_glyc, (v) => _glyc = v);
      default:
        return Column(
          children: [
            for (final a in const ['AUCUN', 'SECOND_DEGRE', 'PREMIER_DEGRE'])
              OptionCard(
                label: context.t('fam_$a'),
                sub: context.t('fam_${a}_sub'),
                selected: _antec == a,
                onTap: () => setState(() {
                  _antec = a;
                  _error = null;
                }),
              ),
          ],
        );
    }
  }

  // ---------- résultat ----------
  Color _levelColor(String n) {
    switch (n) {
      case 'FAIBLE':
        return AppColors.green;
      case 'LEGER':
      case 'MODERE':
        return AppColors.orange;
      default:
        return AppColors.red;
    }
  }

  Widget _result(BuildContext context, RisqueResult r) {
    final c = _levelColor(r.niveau);
    final nav = context.read<ShellNav>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.t('your_result'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: r.score / RisqueResult.scoreMax,
                      strokeWidth: 11,
                      backgroundColor: AppColors.border,
                      color: c,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${r.score}',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '/ ${RisqueResult.scoreMax}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.t('risk_level_${r.niveau}'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t('risk_prob_${r.niveau}'),
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 8),
              AudioButton(
                text:
                    '${context.t('risk_level_${r.niveau}')}. ${context.t('risk_prob_${r.niveau}')}',
              ),
            ],
          ),
        ),
        AppCard(
          color: AppColors.orangeSoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.deepOrange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t('risk_warning'),
                  style: const TextStyle(
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionTitle(context.t('recommendations')),
        ...r.codes.map(
          (code) => AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t('reco_$code'),
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
          ),
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(context.t('book_with_doctor')),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => nav.go(3),
          icon: const Icon(Icons.smart_toy_outlined),
          label: Text(context.t('ask_assistant')),
        ),
        TextButton(
          onPressed: () => setState(() => _phase = _Phase.intro),
          child: Text(context.t('back')),
        ),
      ],
    );
  }
}
