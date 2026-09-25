import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/pferd.dart';
import '../../models/turnierlizenz.dart';
import '../../models/turnierstart.dart';
import '../../providers/pferde_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

class TurnierTab extends StatefulWidget {
  final Pferd pferd;

  const TurnierTab({super.key, required this.pferd});

  @override
  State<TurnierTab> createState() => _TurnierTabState();
}

class _TurnierTabState extends State<TurnierTab> {
  late Future<List<Turnierlizenz>> _lizenzenFuture;
  late Future<List<Turnierstart>> _startsFuture;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  void _laden() {
    final provider = context.read<PferdeProvider>();
    _lizenzenFuture = provider.turnierlizenzenFor(widget.pferd.id);
    _startsFuture = provider.turnierstartsFor(widget.pferd.id);
  }

  void _neuLaden() => setState(_laden);

  Future<void> _lizenzFormularOeffnen({Turnierlizenz? bestehend}) async {
    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LizenzFormSheet(pferd: widget.pferd, bestehend: bestehend),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _lizenzLoeschen(Turnierlizenz lizenz) async {
    final bestaetigt = await _bestaetigungLoeschen();
    if (!mounted) return;
    if (bestaetigt) {
      await context.read<PferdeProvider>().deleteTurnierlizenz(lizenz.id);
      _neuLaden();
    }
  }

  Future<void> _startFormularOeffnen({Turnierstart? bestehend}) async {
    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StartFormSheet(pferd: widget.pferd, bestehend: bestehend),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _startLoeschen(Turnierstart start) async {
    final bestaetigt = await _bestaetigungLoeschen();
    if (!mounted) return;
    if (bestaetigt) {
      await context.read<PferdeProvider>().deleteTurnierstart(start.id);
      _neuLaden();
    }
  }

  Future<bool> _bestaetigungLoeschen() async {
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
    return bestaetigt == true;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Turnierlizenzen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: () => _lizenzFormularOeffnen(),
              icon: const Icon(Icons.add),
              label: const Text('Lizenz'),
            ),
          ],
        ),
        FutureBuilder<List<Turnierlizenz>>(
          future: _lizenzenFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final liste = snapshot.data!;
            if (liste.isEmpty) {
              return const EmptyState(icon: Icons.badge_outlined, text: 'Noch keine Turnierlizenz erfasst.');
            }
            return Column(
              children: liste.map((l) {
                final abgelaufen = l.gueltigBis.isBefore(DateTime.now());
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.badge_outlined, color: abgelaufen ? Colors.red : null),
                    title: Text('${l.verband.label}${l.lizenznummer != null ? ' · ${l.lizenznummer}' : ''}'),
                    subtitle: Text('Gültig: ${l.gueltigVon.deDate} – ${l.gueltigBis.deDate}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'bearbeiten') _lizenzFormularOeffnen(bestehend: l);
                        if (value == 'loeschen') _lizenzLoeschen(l);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'bearbeiten', child: Text('Bearbeiten')),
                        PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Turnierstarts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: () => _startFormularOeffnen(),
              icon: const Icon(Icons.add),
              label: const Text('Start'),
            ),
          ],
        ),
        FutureBuilder<List<Turnierstart>>(
          future: _startsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final liste = snapshot.data!;
            if (liste.isEmpty) {
              return const EmptyState(icon: Icons.emoji_events_outlined, text: 'Noch keine Turnierstarts erfasst.');
            }
            return Column(
              children: liste.map((s) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(s.turnierort),
                    subtitle: Text(
                      '${s.datum.deDate}'
                      '${s.disziplin != null && s.disziplin!.isNotEmpty ? ' · ${s.disziplin}' : ''}'
                      '${s.ergebnis != null && s.ergebnis!.isNotEmpty ? ' · ${s.ergebnis}' : ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'bearbeiten') _startFormularOeffnen(bestehend: s);
                        if (value == 'loeschen') _startLoeschen(s);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'bearbeiten', child: Text('Bearbeiten')),
                        PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _LizenzFormSheet extends StatefulWidget {
  final Pferd pferd;
  final Turnierlizenz? bestehend;

  const _LizenzFormSheet({required this.pferd, this.bestehend});

  @override
  State<_LizenzFormSheet> createState() => _LizenzFormSheetState();
}

class _LizenzFormSheetState extends State<_LizenzFormSheet> {
  final _uuid = const Uuid();
  Turnierverband _verband = Turnierverband.fn;
  DateTime _gueltigVon = DateTime.now();
  DateTime _gueltigBis = DateTime.now().add(const Duration(days: 365));
  late final TextEditingController _lizenznummerController;
  late final TextEditingController _erinnerungController;
  late final TextEditingController _notizenController;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _verband = b?.verband ?? Turnierverband.fn;
    _gueltigVon = b?.gueltigVon ?? DateTime.now();
    _gueltigBis = b?.gueltigBis ?? DateTime.now().add(const Duration(days: 365));
    _lizenznummerController = TextEditingController(text: b?.lizenznummer ?? '');
    _erinnerungController = TextEditingController(text: (b?.erinnerungTageVorher ?? 30).toString());
    _notizenController = TextEditingController(text: b?.notizen ?? '');
  }

  @override
  void dispose() {
    _lizenznummerController.dispose();
    _erinnerungController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen({required bool istVon}) async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: istVon ? _gueltigVon : _gueltigBis,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (gewaehlt == null) return;
    setState(() {
      if (istVon) {
        _gueltigVon = gewaehlt;
      } else {
        _gueltigBis = gewaehlt;
      }
    });
  }

  Future<void> _speichern() async {
    final provider = context.read<PferdeProvider>();
    final lizenz = Turnierlizenz(
      id: widget.bestehend?.id ?? _uuid.v4(),
      pferdId: widget.pferd.id,
      verband: _verband,
      lizenznummer: _lizenznummerController.text.trim().isEmpty ? null : _lizenznummerController.text.trim(),
      gueltigVon: _gueltigVon,
      gueltigBis: _gueltigBis,
      erinnerungTageVorher: int.tryParse(_erinnerungController.text.trim()) ?? 30,
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
    );
    await provider.saveTurnierlizenz(lizenz, widget.pferd.anzeigename, isNew: _isNew);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isNew ? 'Turnierlizenz erfassen' : 'Turnierlizenz bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Turnierverband>(
              initialValue: _verband,
              decoration: const InputDecoration(labelText: 'Verband'),
              items: Turnierverband.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
              onChanged: (v) => setState(() => _verband = v ?? Turnierverband.fn),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lizenznummerController,
              decoration: const InputDecoration(labelText: 'Lizenznummer'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _datumWaehlen(istVon: true),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Gültig von'),
                child: Text(_gueltigVon.deDate),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _datumWaehlen(istVon: false),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Gültig bis'),
                child: Text(_gueltigBis.deDate),
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

class _StartFormSheet extends StatefulWidget {
  final Pferd pferd;
  final Turnierstart? bestehend;

  const _StartFormSheet({required this.pferd, this.bestehend});

  @override
  State<_StartFormSheet> createState() => _StartFormSheetState();
}

class _StartFormSheetState extends State<_StartFormSheet> {
  final _uuid = const Uuid();
  DateTime _datum = DateTime.now();
  late final TextEditingController _turnierortController;
  late final TextEditingController _disziplinController;
  late final TextEditingController _ergebnisController;
  late final TextEditingController _notizenController;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _datum = b?.datum ?? DateTime.now();
    _turnierortController = TextEditingController(text: b?.turnierort ?? '');
    _disziplinController = TextEditingController(text: b?.disziplin ?? '');
    _ergebnisController = TextEditingController(text: b?.ergebnis ?? '');
    _notizenController = TextEditingController(text: b?.notizen ?? '');
  }

  @override
  void dispose() {
    _turnierortController.dispose();
    _disziplinController.dispose();
    _ergebnisController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (gewaehlt != null) setState(() => _datum = gewaehlt);
  }

  Future<void> _speichern() async {
    if (_turnierortController.text.trim().isEmpty) return;
    final provider = context.read<PferdeProvider>();
    final start = Turnierstart(
      id: widget.bestehend?.id ?? _uuid.v4(),
      pferdId: widget.pferd.id,
      datum: _datum,
      turnierort: _turnierortController.text.trim(),
      disziplin: _disziplinController.text.trim().isEmpty ? null : _disziplinController.text.trim(),
      ergebnis: _ergebnisController.text.trim().isEmpty ? null : _ergebnisController.text.trim(),
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
    );
    await provider.saveTurnierstart(start, isNew: _isNew);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isNew ? 'Turnierstart erfassen' : 'Turnierstart bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _datumWaehlen,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Datum'),
                child: Text(_datum.deDate),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _turnierortController,
              decoration: const InputDecoration(labelText: 'Turnierort *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _disziplinController,
              decoration: const InputDecoration(labelText: 'Disziplin'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ergebnisController,
              decoration: const InputDecoration(labelText: 'Ergebnis / Platzierung'),
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
