import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/dienstleister.dart';
import '../../models/gesundheitstermin.dart';
import '../../models/pferd.dart';
import '../../providers/pferde_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

class GesundheitTab extends StatefulWidget {
  final Pferd pferd;

  const GesundheitTab({super.key, required this.pferd});

  @override
  State<GesundheitTab> createState() => _GesundheitTabState();
}

class _GesundheitTabState extends State<GesundheitTab> {
  late Future<List<Gesundheitstermin>> _future;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  void _laden() {
    _future = context.read<PferdeProvider>().gesundheitsterminFor(widget.pferd.id);
  }

  void _neuLaden() => setState(_laden);

  Future<void> _formularOeffnen({Gesundheitstermin? bestehend}) async {
    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GesundheitsterminFormSheet(pferd: widget.pferd, bestehend: bestehend),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _erledigtUmschalten(Gesundheitstermin termin) async {
    termin.erledigt = !termin.erledigt;
    if (termin.erledigt) {
      termin.letzteDurchfuehrungAm = DateTime.now();
    }
    await context.read<PferdeProvider>().saveGesundheitstermin(
          termin,
          widget.pferd.anzeigename,
          isNew: false,
        );
    _neuLaden();
  }

  Future<void> _loeschen(Gesundheitstermin termin) async {
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
      await context.read<PferdeProvider>().deleteGesundheitstermin(termin.id);
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
              label: const Text('Termin erfassen'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Gesundheitstermin>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final liste = snapshot.data!;
              if (liste.isEmpty) {
                return const EmptyState(
                  icon: Icons.local_hospital_outlined,
                  text: 'Noch keine Termine für Hufschmied, Zahnarzt o. Ä. erfasst.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: liste.length,
                itemBuilder: (context, index) {
                  final g = liste[index];
                  final ueberfaellig = !g.erledigt && g.faelligAm.isBefore(DateTime.now());
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Checkbox(value: g.erledigt, onChanged: (_) => _erledigtUmschalten(g)),
                      title: Text(
                        g.typ.label,
                        style: g.erledigt ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
                      ),
                      subtitle: Text(
                        'Fällig: ${g.faelligAm.deDate}'
                        '${g.letzteDurchfuehrungAm != null ? ' · Zuletzt: ${g.letzteDurchfuehrungAm!.deDate}' : ''}',
                        style: TextStyle(color: ueberfaellig ? Colors.red : null),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'bearbeiten') _formularOeffnen(bestehend: g);
                          if (value == 'loeschen') _loeschen(g);
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

class _GesundheitsterminFormSheet extends StatefulWidget {
  final Pferd pferd;
  final Gesundheitstermin? bestehend;

  const _GesundheitsterminFormSheet({required this.pferd, this.bestehend});

  @override
  State<_GesundheitsterminFormSheet> createState() => _GesundheitsterminFormSheetState();
}

class _GesundheitsterminFormSheetState extends State<_GesundheitsterminFormSheet> {
  final _uuid = const Uuid();
  GesundheitsterminTyp _typ = GesundheitsterminTyp.hufschmied;
  DateTime _faelligAm = DateTime.now().add(const Duration(days: 42));
  late final TextEditingController _erinnerungController;
  late final TextEditingController _notizenController;
  String? _dienstleisterId;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _typ = b?.typ ?? GesundheitsterminTyp.hufschmied;
    _faelligAm = b?.faelligAm ?? DateTime.now().add(const Duration(days: 42));
    _erinnerungController = TextEditingController(text: (b?.erinnerungTageVorher ?? 7).toString());
    _notizenController = TextEditingController(text: b?.notizen ?? '');
    _dienstleisterId = b?.dienstleisterId;
  }

  @override
  void dispose() {
    _erinnerungController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _faelligAm,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (gewaehlt != null) setState(() => _faelligAm = gewaehlt);
  }

  Future<void> _speichern() async {
    final provider = context.read<PferdeProvider>();
    final termin = Gesundheitstermin(
      id: widget.bestehend?.id ?? _uuid.v4(),
      pferdId: widget.pferd.id,
      typ: _typ,
      faelligAm: _faelligAm,
      letzteDurchfuehrungAm: widget.bestehend?.letzteDurchfuehrungAm,
      erinnerungTageVorher: int.tryParse(_erinnerungController.text.trim()) ?? 7,
      erledigt: widget.bestehend?.erledigt ?? false,
      dienstleisterId: _dienstleisterId,
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
    );
    await provider.saveGesundheitstermin(termin, widget.pferd.anzeigename, isNew: _isNew);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final dienstleister = context.watch<PferdeProvider>().dienstleister;
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
              _isNew ? 'Gesundheitstermin erfassen' : 'Gesundheitstermin bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GesundheitsterminTyp>(
              initialValue: _typ,
              decoration: const InputDecoration(labelText: 'Art des Termins'),
              items: GesundheitsterminTyp.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _typ = v ?? GesundheitsterminTyp.hufschmied),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _datumWaehlen,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Fällig am'),
                child: Text(_faelligAm.deDate),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _dienstleisterId,
              decoration: const InputDecoration(labelText: 'Dienstleister'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Nicht angegeben')),
                ...dienstleister.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.name} (${d.typ.label})'))),
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
