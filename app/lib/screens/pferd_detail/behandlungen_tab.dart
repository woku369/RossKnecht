import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/behandlung.dart';
import '../../models/dienstleister.dart';
import '../../models/pferd.dart';
import '../../providers/pferde_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

class BehandlungenTab extends StatefulWidget {
  final Pferd pferd;

  const BehandlungenTab({super.key, required this.pferd});

  @override
  State<BehandlungenTab> createState() => _BehandlungenTabState();
}

class _BehandlungenTabState extends State<BehandlungenTab> {
  late Future<List<Behandlung>> _future;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  void _laden() {
    _future = context.read<PferdeProvider>().behandlungenFor(widget.pferd.id);
  }

  void _neuLaden() => setState(_laden);

  Future<void> _formularOeffnen({Behandlung? bestehend}) async {
    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BehandlungFormSheet(pferd: widget.pferd, bestehend: bestehend),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _loeschen(Behandlung behandlung) async {
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
    if (bestaetigt == true) {
      await context.read<PferdeProvider>().deleteBehandlung(behandlung.id);
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
              label: const Text('Behandlung erfassen'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Behandlung>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final liste = snapshot.data!;
              if (liste.isEmpty) {
                return const EmptyState(
                  icon: Icons.medical_services_outlined,
                  text: 'Noch keine tierärztlichen Behandlungen erfasst\n(z. B. Kolik, Verletzung, akute Erkrankung).',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: liste.length,
                itemBuilder: (context, index) {
                  final b = liste[index];
                  final nachkontrolleUeberfaellig =
                      b.nachkontrolleAm != null && b.nachkontrolleAm!.isBefore(DateTime.now());
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.medical_services_outlined,
                        color: nachkontrolleUeberfaellig ? Colors.red : null,
                      ),
                      title: Text(b.grund),
                      subtitle: Text(
                        '${b.datum.deDate}'
                        '${b.behandlung != null && b.behandlung!.isNotEmpty ? ' · ${b.behandlung}' : ''}'
                        '${b.kostenEuro != null ? ' · ${b.kostenEuro!.toStringAsFixed(2)} €' : ''}'
                        '${b.nachkontrolleAm != null ? ' · Nachkontrolle: ${b.nachkontrolleAm!.deDate}' : ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'bearbeiten') _formularOeffnen(bestehend: b);
                          if (value == 'loeschen') _loeschen(b);
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

class _BehandlungFormSheet extends StatefulWidget {
  final Pferd pferd;
  final Behandlung? bestehend;

  const _BehandlungFormSheet({required this.pferd, this.bestehend});

  @override
  State<_BehandlungFormSheet> createState() => _BehandlungFormSheetState();
}

class _BehandlungFormSheetState extends State<_BehandlungFormSheet> {
  final _uuid = const Uuid();
  DateTime _datum = DateTime.now();
  late final TextEditingController _grundController;
  late final TextEditingController _behandlungController;
  late final TextEditingController _kostenController;
  late final TextEditingController _erinnerungController;
  late final TextEditingController _notizenController;
  String? _dienstleisterId;
  DateTime? _nachkontrolleAm;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _datum = b?.datum ?? DateTime.now();
    _grundController = TextEditingController(text: b?.grund ?? '');
    _behandlungController = TextEditingController(text: b?.behandlung ?? '');
    _kostenController = TextEditingController(text: b?.kostenEuro?.toString() ?? '');
    _erinnerungController = TextEditingController(text: (b?.erinnerungTageVorher ?? 2).toString());
    _notizenController = TextEditingController(text: b?.notizen ?? '');
    _dienstleisterId = b?.dienstleisterId;
    _nachkontrolleAm = b?.nachkontrolleAm;
  }

  @override
  void dispose() {
    _grundController.dispose();
    _behandlungController.dispose();
    _kostenController.dispose();
    _erinnerungController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen({required bool istBehandlungsdatum}) async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: (istBehandlungsdatum ? _datum : _nachkontrolleAm) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (gewaehlt == null) return;
    setState(() {
      if (istBehandlungsdatum) {
        _datum = gewaehlt;
      } else {
        _nachkontrolleAm = gewaehlt;
      }
    });
  }

  Future<void> _speichern() async {
    if (_grundController.text.trim().isEmpty) return;
    final provider = context.read<PferdeProvider>();
    final behandlung = Behandlung(
      id: widget.bestehend?.id ?? _uuid.v4(),
      pferdId: widget.pferd.id,
      datum: _datum,
      grund: _grundController.text.trim(),
      behandlung: _behandlungController.text.trim().isEmpty ? null : _behandlungController.text.trim(),
      dienstleisterId: _dienstleisterId,
      kostenEuro: double.tryParse(_kostenController.text.trim().replaceAll(',', '.')),
      nachkontrolleAm: _nachkontrolleAm,
      erinnerungTageVorher: int.tryParse(_erinnerungController.text.trim()) ?? 2,
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
    );
    await provider.saveBehandlung(behandlung, widget.pferd.anzeigename, isNew: _isNew);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final dienstleister = context
        .watch<PferdeProvider>()
        .dienstleister
        .where((d) => d.typ == DienstleisterTyp.tierarzt)
        .toList();
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
              _isNew ? 'Behandlung erfassen' : 'Behandlung bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _datumWaehlen(istBehandlungsdatum: true),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Datum'),
                child: Text(_datum.deDate),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _grundController,
              decoration: const InputDecoration(labelText: 'Grund / Diagnose *  (z. B. Kolik, Schnittwunde Bein)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _behandlungController,
              decoration: const InputDecoration(labelText: 'Behandlung / Medikation'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _dienstleisterId,
              decoration: const InputDecoration(labelText: 'Tierarzt'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Nicht angegeben')),
                ...dienstleister.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
              ],
              onChanged: (v) => setState(() => _dienstleisterId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kostenController,
              decoration: const InputDecoration(labelText: 'Kosten (€)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _datumWaehlen(istBehandlungsdatum: false),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Nachkontrolle am (optional)'),
                child: Text(_nachkontrolleAm != null ? _nachkontrolleAm!.deDate : 'Nicht gesetzt'),
              ),
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
