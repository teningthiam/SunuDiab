import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _tel = TextEditingController();
  final _pwd = TextEditingController();
  DateTime? _dob;
  String _sexe = 'F';
  String _region = 'Dakar';
  bool _consent = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _tel.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 40, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (d != null) setState(() => _dob = d);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_dob == null) {
      setState(() => _error = context.t('dob_required'));
      return;
    }
    if (!_consent) {
      setState(() => _error = context.t('consent_required'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final lang = context.read<SettingsProvider>().lang.toUpperCase();
    try {
      await context.read<AuthProvider>().register(
        nom: _nom.text,
        prenom: _prenom.text,
        telephone: _tel.text,
        password: _pwd.text,
        dateNaissance: DateFormat('yyyy-MM-dd').format(_dob!),
        sexe: _sexe,
        region: _region,
        langue: lang,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = errText(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? context.t('required') : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('create_account'))),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _prenom,
                textCapitalization: TextCapitalization.words,
                decoration: deco(context.t('first_name')),
                validator: _req,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nom,
                textCapitalization: TextCapitalization.words,
                decoration: deco(context.t('last_name')),
                validator: _req,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tel,
                keyboardType: TextInputType.phone,
                decoration: deco(
                  context.t('phone'),
                  hint: '77 000 00 00',
                  icon: Icons.phone_outlined,
                ).copyWith(prefixText: '+221  '),
                validator: (v) {
                  final s = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  return s.length < 9 ? context.t('phone_invalid') : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pwd,
                obscureText: _obscure,
                decoration:
                    deco(
                      context.t('password'),
                      hint: context.t('password_hint'),
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                validator: (v) => (v == null || v.length < 8)
                    ? context.t('password_hint')
                    : null,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: deco(
                    context.t('birth_date'),
                    icon: Icons.cake_outlined,
                  ),
                  child: Text(
                    _dob == null
                        ? context.t('choose')
                        : DateFormat('d MMMM yyyy', 'fr').format(_dob!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'F', label: Text(context.t('sexe_f'))),
                  ButtonSegment(value: 'M', label: Text(context.t('sexe_m'))),
                ],
                selected: {_sexe},
                onSelectionChanged: (s) => setState(() => _sexe = s.first),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _region,
                decoration: deco(
                  context.t('region'),
                  icon: Icons.place_outlined,
                ),
                items: kRegions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _region = v ?? 'Dakar'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _consent,
                onChanged: (v) => setState(() => _consent = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.t('consent_text'),
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(context.t('create_account')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
