import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/pferd.dart';
import '../providers/pferde_provider.dart';
import '../services/document_storage.dart';
import '../widgets/date_format_x.dart';

/// Kombinierte Farbliste: deutsche Fellfarben-Begriffe plus die von der AQHA
/// (American Quarter Horse Association) offiziell geführten Farben - relevant
/// z. B. bei Quarter Horses, deren Papiere/Community oft die amerikanischen
/// Bezeichnungen verwenden (Buckskin, Grullo, Dun, Roan ...).
const List<String> _farbVorschlaege = [
  'Fuchs',
  'Rappe',
  'Braun',
  'Dunkelbraun',
  'Schimmel',
  'Falbe',
  'Isabell',
  'Schecke',
  'Tigerschecke',
  'Bay',
  'Black',
  'Blue Roan',
  'Brown',
  'Buckskin',
  'Chestnut',
  'Cremello',
  'Dun',
  'Gray',
  'Grullo',
  'Palomino',
  'Perlino',
  'Red Dun',
  'Red Roan',
  'Roan',
  'Sorrel',
];

class PferdFormScreen extends StatefulWidget {
  final Pferd? bestehendesPferd;

  const PferdFormScreen({super.key, this.bestehendesPferd});

  @override
  State<PferdFormScreen> createState() => _PferdFormScreenState();
}

class _PferdFormScreenState extends State<PferdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _eingetragenerNameController;
  late final TextEditingController _rasseController;
  late final TextEditingController _geburtsjahrController;
  late final TextEditingController _farbeController;
  late final TextEditingController _abzeichenController;
  late final TextEditingController _lebensnummerController;
  late final TextEditingController _chipnummerController;
  late final TextEditingController _besitzerController;
  late final TextEditingController _stallplatzController;
  late final TextEditingController _externerStallnameController;
  late final TextEditingController _externerKontaktController;
  late final TextEditingController _notizenController;
  final _farbeFocusNode = FocusNode();

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
    _eingetragenerNameController = TextEditingController(text: p?.eingetragenerName ?? '');
    _rasseController = TextEditingController(text: p?.rasse ?? '');
    _geburtsjahrController = TextEditingController(text: p?.geburtsjahr?.toString() ?? '');
    _farbeController = TextEditingController(text: p?.farbe ?? '');
    _abzeichenController = TextEditingController(text: p?.abzeichen ?? '');
    _lebensnummerController = TextEditingController(text: p?.lebensnummer ?? '');
    _chipnummerController = TextEditingController(text: p?.chipnummer ?? '');
    _besitzerController = TextEditingController(text: p?.besitzer ?? '');
    _stallplatzController = TextEditingController(text: p?.stallplatz ?? '');
    _externerStallnameController = TextEditingController(text: p?.externerStallname ?? '');
    _externerKontaktController = TextEditingController(text: p?.externerKontakt ?? '');
    _notizenController = TextEditingController(text: p?.notizen ?? '');
    _geschlecht = p?.geschlecht ?? Geschlecht.wallach;
    _ankunftsdatum = p?.ankunftsdatum;
    _fotoPfad = p?.fotoPfad;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _eingetragenerNameController.dispose();
    _rasseController.dispose();
    _geburtsjahrController.dispose();
    _farbeController.dispose();
    _abzeichenController.dispose();
    _lebensnummerController.dispose();
    _chipnummerController.dispose();
    _besitzerController.dispose();
    _stallplatzController.dispose();
    _externerStallnameController.dispose();
    _externerKontaktController.dispose();
    _notizenController.dispose();
    _farbeFocusNode.dispose();
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
      p.eingetragenerName = _leerZuNull(_eingetragenerNameController.text);
      p.rasse = _leerZuNull(_rasseController.text);
      p.geschlecht = _geschlecht;
      p.geburtsjahr = geburtsjahr;
      p.farbe = _leerZuNull(_farbeController.text);
      p.abzeichen = _leerZuNull(_abzeichenController.text);
      p.lebensnummer = _leerZuNull(_lebensnummerController.text);
      p.chipnummer = _leerZuNull(_chipnummerController.text);
      p.besitzer = _leerZuNull(_besitzerController.text);
      p.stallplatz = _leerZuNull(_stallplatzController.text);
      p.externerStallname = _leerZuNull(_externerStallnameController.text);
      p.externerKontakt = _leerZuNull(_externerKontaktController.text);
      p.ankunftsdatum = _ankunftsdatum;
      p.fotoPfad = _fotoPfad;
      p.notizen = _leerZuNull(_notizenController.text);
      await provider.updatePferd(p);
    } else {
      await provider.addPferd(
        name: _nameController.text.trim(),
        eingetragenerName: _leerZuNull(_eingetragenerNameController.text),
        rasse: _leerZuNull(_rasseController.text),
        geschlecht: _geschlecht,
        geburtsjahr: geburtsjahr,
        farbe: _leerZuNull(_farbeController.text),
        abzeichen: _leerZuNull(_abzeichenController.text),
        lebensnummer: _leerZuNull(_lebensnummerController.text),
        chipnummer: _leerZuNull(_chipnummerController.text),
        besitzer: _leerZuNull(_besitzerController.text),
        stallplatz: _leerZuNull(_stallplatzController.text),
        externerStallname: _leerZuNull(_externerStallnameController.text),
        externerKontakt: _leerZuNull(_externerKontaktController.text),
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
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
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
              decoration: const InputDecoration(labelText: 'Rufname *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Rufname erforderlich' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _eingetragenerNameController,
              decoration: const InputDecoration(
                labelText: 'Eingetragener Name (Papiere)',
                helperText: 'Offizieller Zuchtname, falls abweichend vom Rufnamen',
              ),
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
            RawAutocomplete<String>(
              textEditingController: _farbeController,
              focusNode: _farbeFocusNode,
              optionsBuilder: (value) {
                if (value.text.trim().isEmpty) return _farbVorschlaege;
                final suche = value.text.toLowerCase();
                return _farbVorschlaege.where((f) => f.toLowerCase().contains(suche));
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Farbe',
                    helperText: 'Freitext oder Vorschlag (deutsch & amerikanisch, z. B. Buckskin, Grullo, Dun)',
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(option),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
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
              decoration: const InputDecoration(labelText: 'Stallplatz / Box (eigener Stall)'),
            ),
            const SizedBox(height: 20),
            const Text('Auswärtige Unterbringung', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Nur ausfüllen, wenn das Pferd nicht im eigenen Stall, sondern in Pension/Beritt o. Ä. steht.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _externerStallnameController,
              decoration: const InputDecoration(labelText: 'Name des auswärtigen Stalls'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _externerKontaktController,
              decoration: const InputDecoration(labelText: 'Kontakt dort (Person/Telefon)'),
            ),
            const SizedBox(height: 20),
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
