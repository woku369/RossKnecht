import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/dienstleister.dart';
import '../providers/pferde_provider.dart';
import '../widgets/empty_state.dart';

class DienstleisterScreen extends StatelessWidget {
  const DienstleisterScreen({super.key});

  Future<void> _formularOeffnen(BuildContext context, {Dienstleister? bestehend}) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DienstleisterFormSheet(bestehend: bestehend),
    );
  }

  Future<void> _loeschen(BuildContext context, Dienstleister d) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${d.name} löschen?'),
        content: const Text(
          'Bestehende Impfungen/Termine mit diesem Dienstleister bleiben erhalten, verlieren aber die Zuordnung.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (bestaetigt == true && context.mounted) {
      await context.read<PferdeProvider>().deleteDienstleisterById(d.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dienstleister')),
      body: Consumer<PferdeProvider>(
        builder: (context, provider, _) {
          final liste = provider.dienstleister;
          if (liste.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              text: 'Noch keine Tierärzte, Hufschmiede oder Sattler erfasst.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final d = liste[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(d.name),
                  subtitle: Text(
                    [d.typ.label, if (d.telefon != null && d.telefon!.isNotEmpty) d.telefon!].join(' · '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'bearbeiten') _formularOeffnen(context, bestehend: d);
                      if (value == 'loeschen') _loeschen(context, d);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _formularOeffnen(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DienstleisterFormSheet extends StatefulWidget {
  final Dienstleister? bestehend;

  const _DienstleisterFormSheet({this.bestehend});

  @override
  State<_DienstleisterFormSheet> createState() => _DienstleisterFormSheetState();
}

class _DienstleisterFormSheetState extends State<_DienstleisterFormSheet> {
  final _uuid = const Uuid();
  DienstleisterTyp _typ = DienstleisterTyp.tierarzt;
  late final TextEditingController _nameController;
  late final TextEditingController _telefonController;
  late final TextEditingController _adresseController;
  late final TextEditingController _notizenController;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _typ = b?.typ ?? DienstleisterTyp.tierarzt;
    _nameController = TextEditingController(text: b?.name ?? '');
    _telefonController = TextEditingController(text: b?.telefon ?? '');
    _adresseController = TextEditingController(text: b?.adresse ?? '');
    _notizenController = TextEditingController(text: b?.notizen ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _telefonController.dispose();
    _adresseController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    if (_nameController.text.trim().isEmpty) return;
    final dienstleister = Dienstleister(
      id: widget.bestehend?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      typ: _typ,
      telefon: _telefonController.text.trim().isEmpty ? null : _telefonController.text.trim(),
      adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
    );
    await context.read<PferdeProvider>().saveDienstleister(dienstleister, isNew: _isNew);
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
              _isNew ? 'Dienstleister hinzufügen' : 'Dienstleister bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DienstleisterTyp>(
              initialValue: _typ,
              decoration: const InputDecoration(labelText: 'Typ'),
              items: DienstleisterTyp.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (v) => setState(() => _typ = v ?? DienstleisterTyp.tierarzt),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonController,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adresseController,
              decoration: const InputDecoration(labelText: 'Adresse'),
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
