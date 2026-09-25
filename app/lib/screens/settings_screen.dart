import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/document_storage.dart';
import '../services/settings_service.dart';

/// App-Einstellungen: Stallname und Logo für den Home-Screen. Kein Bezug zu
/// einem einzelnen Pferd - gilt fürs ganze Gestüt/den Betrieb.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _stallNameController;
  String? _logoPfad;
  bool _geladen = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stallNameController = TextEditingController();
    _laden();
  }

  Future<void> _laden() async {
    final name = await SettingsService.instance.getStallName();
    final logo = await SettingsService.instance.getLogoPfad();
    if (!mounted) return;
    setState(() {
      _stallNameController.text = name ?? '';
      _logoPfad = logo;
      _geladen = true;
    });
  }

  @override
  void dispose() {
    _stallNameController.dispose();
    super.dispose();
  }

  Future<void> _logoAuswaehlen(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, maxWidth: 1200);
    if (xFile == null) return;
    final gespeicherterPfad = await DocumentStorage.instance.speichereKopie(xFile.path, praefix: 'stalllogo');
    if (!mounted) return;
    setState(() => _logoPfad = gespeicherterPfad);
  }

  Future<void> _speichern() async {
    setState(() => _saving = true);
    await SettingsService.instance.setStallName(_stallNameController.text);
    await SettingsService.instance.setLogoPfad(_logoPfad);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: !_geladen
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                                _logoAuswaehlen(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Aus Galerie wählen'),
                              onTap: () {
                                Navigator.pop(context);
                                _logoAuswaehlen(ImageSource.gallery);
                              },
                            ),
                            if (_logoPfad != null)
                              ListTile(
                                leading: const Icon(Icons.delete_outline),
                                title: const Text('Logo entfernen'),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() => _logoPfad = null);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: _logoPfad != null ? FileImage(File(_logoPfad!)) : null,
                      child: _logoPfad == null ? const Icon(Icons.add_photo_alternate_outlined, size: 32) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text('Stall-Logo (optional)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _stallNameController,
                  decoration: const InputDecoration(
                    labelText: 'Stallname',
                    helperText: 'Wird oben im Home-Screen anstelle von "RossKnecht" angezeigt',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _speichern,
                  child: Text(_saving ? 'Speichern...' : 'Speichern'),
                ),
              ],
            ),
    );
  }
}
