import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/pferd.dart';
import '../../models/wartungs_task.dart';
import '../../providers/pferde_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

class WartungTab extends StatefulWidget {
  final Pferd pferd;

  const WartungTab({super.key, required this.pferd});

  @override
  State<WartungTab> createState() => _WartungTabState();
}

class _WartungTabState extends State<WartungTab> {
  late Future<List<WartungsTask>> _future;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  void _laden() {
    _future = context.read<PferdeProvider>().wartungsTasksFor(widget.pferd.id);
  }

  void _neuLaden() => setState(_laden);

  Future<void> _formularOeffnen({WartungsTask? bestehend}) async {
    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WartungsTaskFormSheet(pferd: widget.pferd, bestehend: bestehend),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _erledigtUmschalten(WartungsTask task) async {
    task.erledigt = !task.erledigt;
    task.erledigtAm = task.erledigt ? DateTime.now() : null;
    await context.read<PferdeProvider>().saveWartungsTask(task, widget.pferd.anzeigename, isNew: false);
    _neuLaden();
  }

  Future<void> _loeschen(WartungsTask task) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aufgabe löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (!mounted) return;
    if (bestaetigt == true) {
      await context.read<PferdeProvider>().deleteWartungsTask(task.id);
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
              label: const Text('Aufgabe hinzufügen'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<WartungsTask>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final liste = snapshot.data!;
              if (liste.isEmpty) {
                return const EmptyState(
                  icon: Icons.checklist_outlined,
                  text: 'Noch keine freien Aufgaben/To-Dos erfasst.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: liste.length,
                itemBuilder: (context, index) {
                  final t = liste[index];
                  final ueberfaellig = !t.erledigt && t.faelligAm != null && t.faelligAm!.isBefore(DateTime.now());
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Checkbox(value: t.erledigt, onChanged: (_) => _erledigtUmschalten(t)),
                      title: Text(
                        t.titel,
                        style: t.erledigt ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
                      ),
                      subtitle: t.faelligAm != null || (t.notizen != null && t.notizen!.isNotEmpty)
                          ? Text(
                              [
                                if (t.faelligAm != null) 'Fällig: ${t.faelligAm!.deDate}',
                                if (t.notizen != null && t.notizen!.isNotEmpty) t.notizen!,
                              ].join(' · '),
                              style: TextStyle(color: ueberfaellig ? Colors.red : null),
                            )
                          : null,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'bearbeiten') _formularOeffnen(bestehend: t);
                          if (value == 'loeschen') _loeschen(t);
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

class _WartungsTaskFormSheet extends StatefulWidget {
  final Pferd pferd;
  final WartungsTask? bestehend;

  const _WartungsTaskFormSheet({required this.pferd, this.bestehend});

  @override
  State<_WartungsTaskFormSheet> createState() => _WartungsTaskFormSheetState();
}

class _WartungsTaskFormSheetState extends State<_WartungsTaskFormSheet> {
  final _uuid = const Uuid();
  late final TextEditingController _titelController;
  late final TextEditingController _erinnerungController;
  late final TextEditingController _notizenController;
  DateTime? _faelligAm;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _titelController = TextEditingController(text: b?.titel ?? '');
    _erinnerungController = TextEditingController(text: (b?.erinnerungTageVorher ?? 3).toString());
    _notizenController = TextEditingController(text: b?.notizen ?? '');
    _faelligAm = b?.faelligAm;
  }

  @override
  void dispose() {
    _titelController.dispose();
    _erinnerungController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _faelligAm ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (gewaehlt != null) setState(() => _faelligAm = gewaehlt);
  }

  Future<void> _speichern() async {
    if (_titelController.text.trim().isEmpty) return;
    final provider = context.read<PferdeProvider>();
    final task = WartungsTask(
      id: widget.bestehend?.id ?? _uuid.v4(),
      pferdId: widget.pferd.id,
      titel: _titelController.text.trim(),
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
      erledigt: widget.bestehend?.erledigt ?? false,
      erstelltAm: widget.bestehend?.erstelltAm ?? DateTime.now(),
      erledigtAm: widget.bestehend?.erledigtAm,
      faelligAm: _faelligAm,
      erinnerungTageVorher: int.tryParse(_erinnerungController.text.trim()) ?? 3,
    );
    await provider.saveWartungsTask(task, widget.pferd.anzeigename, isNew: _isNew);
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
              _isNew ? 'Aufgabe hinzufügen' : 'Aufgabe bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titelController,
              decoration: const InputDecoration(labelText: 'Titel *'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _datumWaehlen,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Fällig am (optional)'),
                child: Text(_faelligAm != null ? _faelligAm!.deDate : 'Nicht gesetzt'),
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
