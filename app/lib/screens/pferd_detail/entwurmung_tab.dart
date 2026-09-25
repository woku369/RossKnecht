import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/entwurmung.dart';
import '../../models/pferd.dart';
import '../../providers/pferde_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

class EntwurmungTab extends StatefulWidget {
  final Pferd pferd;

  const EntwurmungTab({super.key, required this.pferd});

  @override
  State<EntwurmungTab> createState() => _EntwurmungTabState();
}

class _EntwurmungTabState extends State<EntwurmungTab> {
  late Future<List<Entwurmung>> _future;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  void _laden() {
    _future = context.read<PferdeProvider>().entwurmungenFor(widget.pferd.id);
  }

  void _neuLaden() => setState(_laden);

  Future<void> _formularOeffnen({Entwurmung? bestehend}) async {
    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EntwurmungFormSheet(pferd: widget.pferd, bestehend: bestehend),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _loeschen(Entwurmung entwurmung) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (!mounted) return;
    if (bestaetigt == true) {
      await context.read<PferdeProvider>().deleteEntwurmung(entwurmung.id);
      _neuLaden();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _formularOeffnen(),
              icon: const Icon(Icons.add),
              label: const Text('Entwurmung erfassen'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Entwurmung>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final liste = snapshot.data!;
              if (liste.isEmpty) {
                return const EmptyState(
                  icon: Icons.bug_report_outlined,
                  text: 'Noch keine Entwurmung/Kotprobe erfasst.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: liste.length,
                itemBuilder: (context, index) {
                  final e = liste[index];
                  final ueberfaellig = e.faelligAm.isBefore(DateTime.now());
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.bug_report_outlined, color: ueberfaellig ? Colors.red : null),
                      title: Text(e.methode.label),
                      subtitle: Text(
                        'Durchgeführt: ${e.durchgefuehrtAm.deDate} · Nächste Fälligkeit: ${e.faelligAm.deDate}'
                        '${e.praeparatOderWirkstoff != null && e.praeparatOderWirkstoff!.isNotEmpty ? ' · ${e.praeparatOderWirkstoff}' : ''}'
                        '${e.ergebnis != null && e.ergebnis!.isNotEmpty ? ' · Ergebnis: ${e.ergebnis}' : ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'bearbeiten') _formularOeffnen(bestehend: e);
                          if (value == 'loeschen') _loeschen(e);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'bearbeiten', child: Text('Bearbeiten')),
                          PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EntwurmungFormSheet extends StatefulWidget {
  final Pferd pferd;
  final Entwurmung? bestehend;

  const _EntwurmungFormSheet({required this.pferd, this.bestehend});

  @override
  State<_EntwurmungFormSheet> createState() => _EntwurmungFormSheetState();
}

class _EntwurmungFormSheetState extends State<_EntwurmungFormSheet> {
  final _uuid = const Uuid();
  EntwurmungsMethode _methode = EntwurmungsMethode.wurmkur;
  DateTime _durchgefuehrtAm = DateTime.now();
  DateTime _faelligAm = DateTime.now().add(const Duration(days: 90));
  late final TextEditingController _praeparatController;
  late final TextEditingController _ergebnisController;
  late final TextEditingController _erinnerungController;
  late final TextEditingController _notizenController;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _methode = b?.methode ?? EntwurmungsMethode.wurmkur;
    _durchgefuehrtAm = b?.durchgefuehrtAm ?? DateTime.now();
    _faelligAm = b?.faelligAm ?? DateTime.now().add(const Duration(days: 90));
    _praeparatController = TextEditingController(text: b?.praeparatOderWirkstoff ?? '');
    _ergebnisController = TextEditingController(text: b?.ergebnis ?? '');
    _erinnerungController = TextEditingController(text: (b?.erinnerungTageVorher ?? 14).toString());
    _notizenController = TextEditingController(text: b?.notizen ?? '');
  }

  @override
  void dispose() {
    _praeparatController.dispose();
    _ergebnisController.dispose();
    _erinnerungController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen({required bool istDurchgefuehrtAm}) async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: istDurchgefuehrtAm ? _durchgefuehrtAm : _faelligAm,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (gewaehlt == null) return;
    setState(() {
      if (istDurchgefuehrtAm) {
        _durchgefuehrtAm = gewaehlt;
      } else {
        _faelligAm = gewaehlt;
      }
    });
  }

  Future<void> _speichern() async {
    final provider = context.read<PferdeProvider>();
    final entwurmung = Entwurmung(
      id: widget.bestehend?.id ?? _uuid.v4(),
      pferdId: widget.pferd.id,
      methode: _methode,
      praeparatOderWirkstoff: _praeparatController.text.trim().isEmpty ? null : _praeparatController.text.trim(),
      durchgefuehrtAm: _durchgefuehrtAm,
      faelligAm: _faelligAm,
      ergebnis: _ergebnisController.text.trim().isEmpty ? null : _ergebnisController.text.trim(),
      erinnerungTageVorher: int.tryParse(_erinnerungController.text.trim()) ?? 14,
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
    );
    await provider.saveEntwurmung(entwurmung, widget.pferd.anzeigename, isNew: _isNew);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isNew ? 'Entwurmung erfassen' : 'Entwurmung bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EntwurmungsMethode>(
              initialValue: _methode,
              decoration: const InputDecoration(labelText: 'Methode'),
              items: EntwurmungsMethode.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (v) => setState(() => _methode = v ?? EntwurmungsMethode.wurmkur),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _datumWaehlen(istDurchgefuehrtAm: true),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Durchgeführt am'),
                child: Text(_durchgefuehrtAm.deDate),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _datumWaehlen(istDurchgefuehrtAm: false),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Nächste Fälligkeit'),
                child: Text(_faelligAm.deDate),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _praeparatController,
              decoration: const InputDecoration(labelText: 'Präparat / Wirkstoff'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ergebnisController,
              decoration: const InputDecoration(labelText: 'Ergebnis (bei Kotprobe, z. B. Eier pro Gramm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _erinnerungController,
              decoration: const InputDecoration(labelText: 'Erinnerung (Tage vorher)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notizenController,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _speichern, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }
}
