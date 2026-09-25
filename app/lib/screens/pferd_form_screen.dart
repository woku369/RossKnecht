import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/pferd.dart';
import '../providers/pferde_provider.dart';
import '../services/document_storage.dart';
import '../widgets/date_format_x.dart';

class PferdFormScreen extends StatefulWidget {
  final Pferd? bestehendesPferd;

  const PferdFormScreen({super.key, this.bestehendesPferd});

  @override
  State<PferdFormScreen> createState() => _PferdFormScreenState();
}

class _PferdFormScreenState extends State<PferdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _rasseController;
  late final TextEditingController _geburtsjahrController;
  late final TextEditingController _farbeController;
  late final TextEditingController _abzeichenController;
  late final TextEditingController _lebensnummerController;
  late final TextEditingController _chipnummerController;
  late final TextEditingController _besitzerController;
  late final TextEditingController _stallplatzController;
  late final TextEditingController _notizenController;

  Geschlecht _geschlecht = Geschlecht.wallach;
  DateTime? _ankunftsdatum;
  String? _fotoPfad;
  bool _saving = false;

  bool get _isEdit => widget.bestehendesPferd != null;

  @override
  void initState() {
    super.initState();
    final p = widget.bestehendesPferd;
    _nameController = TextEditingController(text: p?.name ?? '');
    _rasseController = TextEditingController(text: p?.rasse ?? '');
    _geburtsjahrController = TextEditingController(text: p?.geburtsjahr?.toString() ?? '');
    _farbeController = TextEditingController(text: p?.farbe ?? '');
    _abzeichenController = TextEditingController(text: p?.abzeichen ?? '');
    _lebensnummerController = TextEditingController(text: p?.lebensnummer ?? '');
    _chipnummerController = TextEditingController(text: p?.chipnummer ?? '');
    _besitzerController = TextEditingController(text: p?.besitzer ?? '');
    _stallplatzController = TextEditingController(text: p?.stallplatz ?? '');
    _notizenController = TextEditingController(text: p?.notizen ?? '');
    _geschlecht = p?.geschlecht ?? Geschlecht.wallach;
    _ankunftsdatum = p?.ankunftsdatum;
    _fotoPfad = p?.fotoPfad;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rasseController.dispose();
    _geburtsjahrController.dispose();
    _farbeController.dispose();
    _abzeichenController.dispose();
    _lebensnummerController.dispose();
    _chipnummerController.dispose();
    _besitzerController.dispose();
    _stallplatzController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _fotoAuswaehlen(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, maxWidth: 1600);
    if (xFile == null) return;
    final gespeicherterPfad = await DocumentStorage.instance.speichereKopie(xFile.path, praefix: 'pferdfoto');
    if (!mounted) return;
    setState(() => _fotoPfad = gespeicherterPfad);
  }

  Future<void> _datumWaehlen() async {
    final gewaehlt = await showDatePicker(
      context: context,
      initialDate: _ankunftsdatum ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );
    if (gewaehlt != null) setState(() => _ankunftsdatum = gewaehlt);
  }

  String? _leerZuNull(String text) => text.trim().isEmpty ? null : text.trim();

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<PferdeProvider>();
    final geburtsjahr =
        _geburtsjahrController.text.trim().isEmpty ? null : int.tryParse(_geburtsjahrController.text.trim());

    if (_isEdit) {
      final p = widget.bestehendesPferd!;
      p.name = _nameController.text.trim();
      p.rasse = _leerZuNull(_rasseController.text);
      p.geschlecht = _geschlecht;
      p.geburtsjahr = geburtsjahr;
      p.farbe = _leerZuNull(_farbeController.text);
      p.abzeichen = _leerZuNull(_abzeichenController.text);
      p.lebensnummer = _leerZuNull(_lebensnummerController.text);
      p.chipnummer = _leerZuNull(_chipnummerController.text);
      p.besitzer = _leerZuNull(_besitzerController.text);
      p.stallplatz = _leerZuNull(_stallplatzController.text);
      p.ankunftsdatum = _ankunftsdatum;
      p.fotoPfad = _fotoPfad;
      p.notizen = _leerZuNull(_notizenController.text);
      await provider.updatePferd(p);
    } else {
      await provider.addPferd(
        name: _nameController.text.trim(),
        rasse: _leerZuNull(_rasseController.text),
        geschlecht: _geschlecht,
        geburtsjahr: geburtsjahr,
        farbe: _leerZuNull(_farbeController.text),
        abzeichen: _leerZuNull(_abzeichenController.text),
        lebensnummer: _leerZuNull(_lebensnummerController.text),
        chipnummer: _leerZuNull(_chipnummerController.text),
        besitzer: _leerZuNull(_besitzerController.text),
        stallplatz: _leerZuNull(_stallplatzController.text),
        ankunftsdatum: _ankunftsdatum,
        fotoPfad: _fotoPfad,
        notizen: _leerZuNull(_notizenController.text),
      );
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Pferd bearbeiten' : 'Neues Pferd')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_camera),
                          title: const Text('Foto aufnehmen'),
                          onTap: () {
                            Navigator.pop(context);
                            _fotoAuswaehlen(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Aus Galerie wählen'),
                          onTap: () {
                            Navigator.pop(context);
                            _fotoAuswaehlen(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: _fotoPfad != null ? FileImage(File(_fotoPfad!)) : null,
                  child: _fotoPfad == null ? const Icon(Icons.add_a_photo, size: 32) : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name erforderlich' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rasseController,
              decoration: const InputDecoration(labelText: 'Rasse'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Geschlecht>(
              initialValue: _geschlecht,
              decoration: const InputDecoration(labelText: 'Geschlecht'),
              items: Geschlecht.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
              onChanged: (v) => setState(() => _geschlecht = v ?? Geschlecht.wallach),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _geburtsjahrController,
              decoration: const InputDecoration(labelText: 'Geburtsjahr'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _farbeController,
              decoration: const InputDecoration(labelText: 'Farbe'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _abzeichenController,
              decoration: const InputDecoration(labelText: 'Abzeichen'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lebensnummerController,
              decoration: const InputDecoration(labelText: 'Lebensnummer (UELN)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _chipnummerController,
              decoration: const InputDecoration(labelText: 'Chipnummer'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _besitzerController,
              decoration: const InputDecoration(labelText: 'Besitzer'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stallplatzController,
              decoration: const InputDecoration(labelText: 'Stallplatz / Box'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _datumWaehlen,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Ankunftsdatum'),
                child: Text(_ankunftsdatum != null ? _ankunftsdatum!.deDate : 'Nicht gesetzt'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notizenController,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _speichern,
              child: Text(_saving ? 'Speichern...' : 'Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
