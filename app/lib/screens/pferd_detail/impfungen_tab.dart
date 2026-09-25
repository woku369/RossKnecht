import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/dienstleister.dart';
import '../../models/impfung.dart';
import '../../models/pferd.dart';
import '../../providers/pferde_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

class ImpfungenTab extends StatefulWidget {
  final Pferd pferd;

  const ImpfungenTab({super.key, required this.pferd});

  @override
  State<ImpfungenTab> createState() => _ImpfungenTabState();
}

class _ImpfungenTabState extends State<ImpfungenTab> {
  late Future<List<Impfung>> _future;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  void _laden() {
    _future = context.read<PferdeProvider>().impfungenFor(widget.pferd.id);
  }

  void _neuLaden() => setState(_laden);

  Future<void> _formularOeffnen({Impfung? bestehend}) async {
    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ImpfungFormSheet(pferd: widget.pferd, bestehend: bestehend),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _loeschen(Impfung impfung) async {
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
      await context.read<PferdeProvider>().deleteImpfung(impfung.id);
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
              label: const Text('Impfung erfassen'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Impfung>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final liste = snapshot.data!;
              if (liste.isEmpty) {
                return const EmptyState(icon: Icons.vaccines_outlined, text: 'Noch keine Impfungen erfasst.');
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: liste.length,
                itemBuilder: (context, index) {
                  final i = liste[index];
                  final ueberfaellig = i.faelligAm.isBefore(DateTime.now());
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.vaccines, color: ueberfaellig ? Colors.red : null),
                      title: Text(i.impfstoffTyp.label),
                      subtitle: Text(
                        'Geimpft: ${i.geimpftAm.deDate} · Fällig ab: ${i.faelligAm.deDate}'
                        '${i.chargennummer != null && i.chargennummer!.isNotEmpty ? ' · Charge ${i.chargennummer}' : ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'bearbeiten') _formularOeffnen(bestehend: i);
                          if (value == 'loeschen') _loeschen(i);
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

class _ImpfungFormSheet extends StatefulWidget {
  final Pferd pferd;
  final Impfung? bestehend;

  const _ImpfungFormSheet({required this.pferd, this.bestehend});

  @override
  State<_ImpfungFormSheet> createState() => _ImpfungFormSheetState();
}

class _ImpfungFormSheetState extends State<_ImpfungFormSheet> {
  final _uuid = const Uuid();
  ImpfstoffTyp _typ = ImpfstoffTyp.influenza;
  DateTime _geimpftAm = DateTime.now();
  DateTime _faelligAm = DateTime.now().add(const Duration(days: 180));
  late final TextEditingController _chargeController;
  late final TextEditingController _erinnerungController;
  late final TextEditingController _notizenController;
  String? _dienstleisterId;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _typ = b?.impfstoffTyp ?? ImpfstoffTyp.influenza;
    _geimpftAm = b?.geimpftAm ?? DateTime.now();
    _faelligAm = b?.faelligAm ?? DateTime.now().add(const Duration(days: 180));
    _chargeController = TextEditingController(text: b?.chargennummer ?? '');
    _erinnerungController = TextEditingController(text: (b?.erinnerungTageVorher ?? 30).toString());
    _notizenController = TextEditingController(text: b?.notizen ?? '');
    _dienstleisterId = b?.dienstleisterId;
  }

  @override
  void dispose() {
    _chargeController.dispose();
    _erinnerungController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen({required bool istGeimpftAm}) async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: istGeimpftAm ? _geimpftAm : _faelligAm,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (gewaehlt == null) return;
    setState(() {
      if (istGeimpftAm) {
        _geimpftAm = gewaehlt;
      } else {
        _faelligAm = gewaehlt;
      }
    });
  }

  Future<void> _speichern() async {
    final provider = context.read<PferdeProvider>();
    final impfung = Impfung(
      id: widget.bestehend?.id ?? _uuid.v4(),
      pferdId: widget.pferd.id,
      impfstoffTyp: _typ,
      geimpftAm: _geimpftAm,
      faelligAm: _faelligAm,
      chargennummer: _chargeController.text.trim().isEmpty ? null : _chargeController.text.trim(),
      dienstleisterId: _dienstleisterId,
      erinnerungTageVorher: int.tryParse(_erinnerungController.text.trim()) ?? 30,
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
    );
    await provider.saveImpfung(impfung, widget.pferd.anzeigename, isNew: _isNew);
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
              _isNew ? 'Impfung erfassen' : 'Impfung bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ImpfstoffTyp>(
              value: _typ,
              decoration: const InputDecoration(labelText: 'Impfstoff'),
              items: ImpfstoffTyp.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (v) => setState(() => _typ = v ?? ImpfstoffTyp.influenza),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _datumWaehlen(istGeimpftAm: true),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Geimpft am'),
                child: Text(_geimpftAm.deDate),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _datumWaehlen(istGeimpftAm: false),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Fällig ab'),
                child: Text(_faelligAm.deDate),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _chargeController,
              decoration: const InputDecoration(labelText: 'Chargennummer'),
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
