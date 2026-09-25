import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/pferd.dart';
import '../../models/pferde_dokument.dart';
import '../../models/pferde_versicherung.dart';
import '../../providers/pferde_provider.dart';
import '../../services/document_storage.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

class DokumenteVersicherungTab extends StatefulWidget {
  final Pferd pferd;

  const DokumenteVersicherungTab({super.key, required this.pferd});

  @override
  State<DokumenteVersicherungTab> createState() => _DokumenteVersicherungTabState();
}

class _DokumenteVersicherungTabState extends State<DokumenteVersicherungTab> {
  late Future<List<PferdeDokument>> _dokumenteFuture;
  late Future<List<PferdeVersicherung>> _versicherungenFuture;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  void _laden() {
    final provider = context.read<PferdeProvider>();
    _dokumenteFuture = provider.dokumenteFor(widget.pferd.id);
    _versicherungenFuture = provider.versicherungenFor(widget.pferd.id);
  }

  void _neuLaden() => setState(_laden);

  Future<void> _dokumentHinzufuegen() async {
    final quelle = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Foto aufnehmen'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Aus Galerie wählen'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (quelle == null) return;

    final xFile = await ImagePicker().pickImage(source: quelle, maxWidth: 2000);
    if (xFile == null || !mounted) return;

    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DokumentDetailsSheet(pferd: widget.pferd, quellPfad: xFile.path),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _dokumentLoeschen(PferdeDokument dokument) async {
    final bestaetigt = await _bestaetigungLoeschen();
    if (bestaetigt) {
      await context.read<PferdeProvider>().deleteDokument(dokument);
      _neuLaden();
    }
  }

  Future<void> _versicherungFormularOeffnen({PferdeVersicherung? bestehend}) async {
    final ergebnis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VersicherungFormSheet(pferd: widget.pferd, bestehend: bestehend),
    );
    if (ergebnis == true) _neuLaden();
  }

  Future<void> _versicherungLoeschen(PferdeVersicherung v) async {
    final bestaetigt = await _bestaetigungLoeschen();
    if (bestaetigt) {
      await context.read<PferdeProvider>().deleteVersicherung(v.id);
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
            const Text('Dokumente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: _dokumentHinzufuegen,
              icon: const Icon(Icons.add),
              label: const Text('Dokument'),
            ),
          ],
        ),
        FutureBuilder<List<PferdeDokument>>(
          future: _dokumenteFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final liste = snapshot.data!;
            if (liste.isEmpty) {
              return const EmptyState(icon: Icons.folder_outlined, text: 'Noch keine Dokumente erfasst.');
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: liste.length,
              itemBuilder: (context, index) {
                final d = liste[index];
                return GestureDetector(
                  onLongPress: () => _dokumentLoeschen(d),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(d.dateipfad), fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(d.titel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                      Text(d.kategorie.label, maxLines: 1, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Versicherungen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: () => _versicherungFormularOeffnen(),
              icon: const Icon(Icons.add),
              label: const Text('Versicherung'),
            ),
          ],
        ),
        FutureBuilder<List<PferdeVersicherung>>(
          future: _versicherungenFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final liste = snapshot.data!;
            if (liste.isEmpty) {
              return const EmptyState(icon: Icons.shield_outlined, text: 'Noch keine Versicherung erfasst.');
            }
            return Column(
              children: liste.map((v) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: Text('${v.art.label} · ${v.gesellschaft}'),
                    subtitle: Text(
                      'Polizze ${v.polizzennummer} · ${v.zahlungsintervall.label} · '
                      'nächste Fälligkeit ${v.naechsteFaelligkeit.deDate}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'bearbeiten') _versicherungFormularOeffnen(bestehend: v);
                        if (value == 'loeschen') _versicherungLoeschen(v);
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

class _DokumentDetailsSheet extends StatefulWidget {
  final Pferd pferd;
  final String quellPfad;

  const _DokumentDetailsSheet({required this.pferd, required this.quellPfad});

  @override
  State<_DokumentDetailsSheet> createState() => _DokumentDetailsSheetState();
}

class _DokumentDetailsSheetState extends State<_DokumentDetailsSheet> {
  final _uuid = const Uuid();
  DokumentKategorie _kategorie = DokumentKategorie.sonstiges;
  late final TextEditingController _titelController;
  bool _speichert = false;

  @override
  void initState() {
    super.initState();
    _titelController = TextEditingController();
  }

  @override
  void dispose() {
    _titelController.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    if (_titelController.text.trim().isEmpty) return;
    setState(() => _speichert = true);
    final gespeicherterPfad = await DocumentStorage.instance.speichereKopie(widget.quellPfad, praefix: 'dokument');
    final dokument = PferdeDokument(
      id: _uuid.v4(),
      pferdId: widget.pferd.id,
      kategorie: _kategorie,
      dateipfad: gespeicherterPfad,
      titel: _titelController.text.trim(),
      erstelltAm: DateTime.now(),
    );
    await context.read<PferdeProvider>().saveDokument(dokument, isNew: true);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(widget.quellPfad), height: 160, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titelController,
            decoration: const InputDecoration(labelText: 'Titel *'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DokumentKategorie>(
            value: _kategorie,
            decoration: const InputDecoration(labelText: 'Kategorie'),
            items: DokumentKategorie.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))).toList(),
            onChanged: (v) => setState(() => _kategorie = v ?? DokumentKategorie.sonstiges),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _speichert ? null : _speichern,
            child: Text(_speichert ? 'Speichern...' : 'Speichern'),
          ),
        ],
      ),
    );
  }
}

class _VersicherungFormSheet extends StatefulWidget {
  final Pferd pferd;
  final PferdeVersicherung? bestehend;

  const _VersicherungFormSheet({required this.pferd, this.bestehend});

  @override
  State<_VersicherungFormSheet> createState() => _VersicherungFormSheetState();
}

class _VersicherungFormSheetState extends State<_VersicherungFormSheet> {
  final _uuid = const Uuid();
  VersicherungsArt _art = VersicherungsArt.haftpflicht;
  Zahlungsintervall _zahlungsintervall = Zahlungsintervall.jaehrlich;
  DateTime _faelligkeitJaehrlichAm = DateTime.now();
  late final TextEditingController _gesellschaftController;
  late final TextEditingController _polizzennummerController;
  late final TextEditingController _praemieController;
  late final TextEditingController _notizenController;

  bool get _isNew => widget.bestehend == null;

  @override
  void initState() {
    super.initState();
    final b = widget.bestehend;
    _art = b?.art ?? VersicherungsArt.haftpflicht;
    _zahlungsintervall = b?.zahlungsintervall ?? Zahlungsintervall.jaehrlich;
    _faelligkeitJaehrlichAm = b?.faelligkeitJaehrlichAm ?? DateTime.now();
    _gesellschaftController = TextEditingController(text: b?.gesellschaft ?? '');
    _polizzennummerController = TextEditingController(text: b?.polizzennummer ?? '');
    _praemieController = TextEditingController(text: b?.praemieEuro?.toString() ?? '');
    _notizenController = TextEditingController(text: b?.notizen ?? '');
  }

  @override
  void dispose() {
    _gesellschaftController.dispose();
    _polizzennummerController.dispose();
    _praemieController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _datumWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _faelligkeitJaehrlichAm,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (gewaehlt != null) setState(() => _faelligkeitJaehrlichAm = gewaehlt);
  }

  Future<void> _speichern() async {
    if (_gesellschaftController.text.trim().isEmpty || _polizzennummerController.text.trim().isEmpty) return;
    final provider = context.read<PferdeProvider>();
    final versicherung = PferdeVersicherung(
      id: widget.bestehend?.id ?? _uuid.v4(),
      pferdId: widget.pferd.id,
      gesellschaft: _gesellschaftController.text.trim(),
      polizzennummer: _polizzennummerController.text.trim(),
      art: _art,
      faelligkeitJaehrlichAm: _faelligkeitJaehrlichAm,
      zahlungsintervall: _zahlungsintervall,
      praemieEuro: double.tryParse(_praemieController.text.trim().replaceAll(',', '.')),
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
    );
    await provider.saveVersicherung(versicherung, widget.pferd.anzeigename, isNew: _isNew);
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
              _isNew ? 'Versicherung erfassen' : 'Versicherung bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VersicherungsArt>(
              value: _art,
              decoration: const InputDecoration(labelText: 'Art'),
              items: VersicherungsArt.values.map((a) => DropdownMenuItem(value: a, child: Text(a.label))).toList(),
              onChanged: (v) => setState(() => _art = v ?? VersicherungsArt.haftpflicht),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gesellschaftController,
              decoration: const InputDecoration(labelText: 'Gesellschaft *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _polizzennummerController,
              decoration: const InputDecoration(labelText: 'Polizzennummer *'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _datumWaehlen,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Hauptfälligkeit'),
                child: Text(_faelligkeitJaehrlichAm.deDate),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Zahlungsintervall>(
              value: _zahlungsintervall,
              decoration: const InputDecoration(labelText: 'Zahlungsintervall'),
              items: Zahlungsintervall.values.map((z) => DropdownMenuItem(value: z, child: Text(z.label))).toList(),
              onChanged: (v) => setState(() => _zahlungsintervall = v ?? Zahlungsintervall.jaehrlich),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _praemieController,
              decoration: const InputDecoration(labelText: 'Prämie (€)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
