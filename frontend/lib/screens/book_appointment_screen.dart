import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../widgets/common.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  List<Medecin>? _medecins;
  String? _loadError;
  int? _medecinId;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  String _mode = 'PRESENTIEL';
  final _motif = TextEditingController();
  bool _setReferent = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = context.read<DataProvider>();
    try {
      final l = await data.medecins();
      if (!mounted) return;
      setState(() {
        _medecins = l;
        _medecinId =
            data.profil?.medecinReferentId ?? (l.isEmpty ? null : l.first.id);
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = errText(context, e));
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _confirm() async {
    final id = _medecinId;
    if (id == null) return;
    final when = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    setState(() => _saving = true);
    final data = context.read<DataProvider>();
    try {
      if (data.profil?.medecinReferentId == null && _setReferent) {
        await data.choisirMedecin(id);
      }
      await data.bookRdv(
        medecinId: id,
        dateHeure: when,
        mode: _mode,
        motif: _motif.text.trim().isEmpty ? null : _motif.text.trim(),
      );
      if (!mounted) return;
      toast(context, context.t('rdv_booked'));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, errText(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(context.t('book_appointment'))),
      body: SafeArea(
        child: _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_loadError!, textAlign: TextAlign.center),
                ),
              )
            : _medecins == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionTitle(context.t('choose_doctor')),
                  if (_medecins!.isEmpty) Text(context.t('no_doctors')),
                  ..._medecins!.map(
                    (m) => OptionCard(
                      label: 'Dr. ${m.nomComplet}',
                      sub: [
                        m.specialite,
                        m.structure,
                      ].where((e) => e != null && e.isNotEmpty).join(' • '),
                      selected: _medecinId == m.id,
                      onTap: () => setState(() => _medecinId = m.id),
                    ),
                  ),
                  if (data.profil?.medecinReferentId == null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.t('set_referent'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: _setReferent,
                      onChanged: (v) => setState(() => _setReferent = v),
                    ),
                  SectionTitle(context.t('date_time')),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.event),
                          label: Text(fmtDay(_date)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(_time.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'PRESENTIEL',
                        label: Text(context.t('mode_PRESENTIEL')),
                        icon: const Icon(Icons.local_hospital_outlined),
                      ),
                      ButtonSegment(
                        value: 'TELECONSULTATION',
                        label: Text(context.t('mode_TELECONSULTATION')),
                        icon: const Icon(Icons.videocam_outlined),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _motif,
                    decoration: deco(context.t('reason')),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (_saving || _medecinId == null)
                        ? null
                        : _confirm,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(context.t('confirm')),
                  ),
                ],
              ),
      ),
    );
  }
}
