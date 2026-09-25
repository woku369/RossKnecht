import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/decke.dart';
import '../../models/pferd.dart';
import '../../providers/pferde_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

class DeckenTab extends StatefulWidget {
  final Pferd pferd;

  const DeckenTab({super.key, required this.pferd});

  @override
  State<DeckenTab> createState() => _DeckenTabState();
}

class _DeckenTabState extends State<DeckenTab> {
  late Future<List<Decke>> _future;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  void _laden() {
    _future = context.read<PferdeProvider>().deckenFor(widget.pferd.id);
  }

  void _neuLaden() => setState(_laden);

  Future<void> _formularOeffnen({Decke? bestehend}) async {
    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeckeFormSheet(pferd: widget.pferd, bestehend: bestehend),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _inGebrauchUmschalten(Decke decke) async {
    decke.inGebrauch = !decke.inGebrauch;
    await context.read<PferdeProvider>().saveDecke(decke, widget.pferd.anzeigename, isNew: false);
    _neuLaden();
  }

  Future<void> _loeschen(Decke decke) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decke löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (bestaetigt == true) {
      await context.read<PferdeProvider>().deleteDecke(decke.id);
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
              label: const Text('Decke hinzufügen'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Decke>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final liste = snapshot.data!;
              if (liste.isEmpty) {
                return const EmptyState(
                  icon: Icons.checkroom_outlined,
                  text: 'Noch keine Decken für dieses Pferd erfasst.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: liste.length,
                itemBuilder: (context, index) {
                  final d = liste[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: d.inGebrauch ? Theme.of(context).colorScheme.primaryContainer : null,
                    child: ListTile(
                      leading: Icon(
                        Icons.checkroom_outlined,
                        color: d.zustand == DeckenZustand.reparaturbeduerftig ? Colors.orange : null,
                      ),
                      title: Text(d.typ.label),
                      subtitle: Text(
                        [
                          if (d.fuellungGramm != null) '${d.fuellungGramm} g',
                          if (d.groesseCm != null) '${d.groesseCm} cm',
                          d.zustand.label,
                          if (d.inGebrauch) 'in Gebrauch',
                          if (d.impraegnierungFaelligAm != null)
                            'Imprägnierung fällig: ${d.impraegnierungFaelligAm!.deDate}',
                        ].join(' · '),
                      ),
                      onTap: () => _inGebrauchUmschalten(d),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'bearbeiten') _formularOeffnen(bestehend: d);
                          if (value == 'loeschen') _loeschen(d);
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

class _DeckeFormSheet extends StatefulWidget {
  final Pferd pferd;
  final Decke? bestehend;

  const _DeckeFormSheet({required this.pferd, this.bestehend});

  @override
  State<_DeckeFormSheet> createState() => _DeckeFormSheetState();
}

class _DeckeFormSheetState extends State<_DeckeFormSheet> {
  final _uuid = const Uuid();
  DeckenTyp _typ = DeckenTyp.weidedecke;
  DeckenZustand _zustand = DeckenZustand.gut;
  late final TextEditingController _fuellungController;
  late final TextEditingController _groesseController;
  late final TextEditingController _erinnerungController;
  late final TextEditingController _notizenController;
  bool _inGebrauch = false;
  DateTime? _impraegnierungFaelligAm;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _typ = b?.typ ?? DeckenTyp.weidedecke;
    _zustand = b?.zustand ?? DeckenZustand.gut;
    _fuellungController = TextEditingController(text: b?.fuellungGramm?.toString() ?? '');
    _groesseController = TextEditingController(text: b?.groesseCm?.toString() ?? '');
    _erinnerungController = TextEditingController(text: (b?.erinnerungTageVorher ?? 14).toString());
    _notizenController = TextEditingController(text: b?.notizen ?? '');
    _inGebrauch = b?.inGebrauch ?? false;
    _impraegnierungFaelligAm = b?.impraegnierungFaelligAm;
  }

  @override
  void dispose() {
    _fuellungController.dispose();
    _groesseController.dispose();
    _erinnerungController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _impraegnierungFaelligAm ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (gewaehlt != null) setState(() => _impraegnierungFaelligAm = gewaehlt);
  }

  Future<void> _speichern() async {
    final provider = context.read<PferdeProvider>();
    final decke = Decke(
      id: widget.bestehend?.id ?? _uuid.v4(),
      pferdId: widget.pferd.id,
      typ: _typ,
      fuellungGramm: int.tryParse(_fuellungController.text.trim()),
      groesseCm: int.tryParse(_groesseController.text.trim()),
      inGebrauch: _inGebrauch,
      zustand: _zustand,
      gewaschenAm: widget.bestehend?.gewaschenAm,
      impraegnierungFaelligAm: _impraegnierungFaelligAm,
      erinnerungTageVorher: int.tryParse(_erinnerungController.text.trim()) ?? 14,
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
    );
    await provider.saveDecke(decke, widget.pferd.anzeigename, isNew: _isNew);
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
            Text(_isNew ? 'Decke hinzufügen' : 'Decke bearbeiten', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<DeckenTyp>(
              value: _typ,
              decoration: const InputDecoration(labelText: 'Typ'),
              items: DeckenTyp.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (v) => setState(() => _typ = v ?? DeckenTyp.weidedecke),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fuellungController,
              decoration: const InputDecoration(labelText: 'Füllung (Gramm)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groesseController,
              decoration: const InputDecoration(labelText: 'Größe (cm)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DeckenZustand>(
              value: _zustand,
              decoration: const InputDecoration(labelText: 'Zustand'),
              items: DeckenZustand.values.map((z) => DropdownMenuItem(value: z, child: Text(z.label))).toList(),
              onChanged: (v) => setState(() => _zustand = v ?? DeckenZustand.gut),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktuell in Gebrauch'),
              value: _inGebrauch,
              onChanged: (v) => setState(() => _inGebrauch = v),
            ),
            InkWell(
              onTap: _datumWaehlen,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Imprägnierung fällig am (optional)'),
                child: Text(_impraegnierungFaelligAm != null ? _impraegnierungFaelligAm!.deDate : 'Nicht gesetzt'),
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
