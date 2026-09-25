import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/pferde_provider.dart';
import '../services/drive_sync_service.dart';
import '../services/local_backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String? _status;

  Future<void> _run(Future<void> Function() aktion, {required String erfolgstext}) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await aktion();
      if (!mounted) return;
      setState(() => _status = erfolgstext);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _lokalExportieren() async {
    await _run(() async {
      final datei = await LocalBackupService.instance.exportToZip();
      await SharePlus.instance.share(ShareParams(files: [XFile(datei.path)]));
    }, erfolgstext: 'Backup erstellt und im App-Ordner abgelegt.');
  }

  Future<void> _lokalImportieren() async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup importieren?'),
        content: const Text('Der komplette aktuelle Datenbestand wird durch die neueste Backup-Datei ersetzt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Importieren')),
        ],
      ),
    );
    if (bestaetigt != true) return;
    await _run(() async {
      await LocalBackupService.instance.importNeuesteAusBackupOrdner();
      if (mounted) await context.read<PferdeProvider>().loadAll();
    }, erfolgstext: 'Backup importiert.');
  }

  Future<void> _driveAnmelden() async {
    await _run(() async {
      final erfolgreich = await DriveSyncService.instance.anmelden();
      if (!erfolgreich) throw StateError('Anmeldung abgebrochen.');
    }, erfolgstext: 'Bei Google angemeldet.');
  }

  Future<void> _driveAbmelden() async {
    await _run(() async {
      await DriveSyncService.instance.abmelden();
    }, erfolgstext: 'Abgemeldet.');
  }

  Future<void> _driveHochladen() async {
    await _run(() async {
      final datei = await LocalBackupService.instance.exportToZip();
      await DriveSyncService.instance.uploadBackup(datei);
    }, erfolgstext: 'Backup nach Google Drive hochgeladen.');
  }

  Future<void> _driveHerunterladen() async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup wiederherstellen?'),
        content: const Text('Der komplette aktuelle Datenbestand wird durch das Drive-Backup ersetzt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Wiederherstellen')),
        ],
      ),
    );
    if (bestaetigt != true) return;
    await _run(() async {
      final datei = await DriveSyncService.instance.downloadBackup();
      await LocalBackupService.instance.importFromZip(datei.path);
      if (mounted) await context.read<PferdeProvider>().loadAll();
    }, erfolgstext: 'Backup von Google Drive wiederhergestellt.');
  }

  @override
  Widget build(BuildContext context) {
    final angemeldet = DriveSyncService.instance.istAngemeldet;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Cloud-Sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, style: TextStyle(color: _status!.startsWith('Fehler') ? Colors.red : null)),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lokales Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                    'Ohne Einrichtung: Export legt eine ZIP-Datei im App-Ordner ab und öffnet die Android-Freigabe.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _lokalExportieren,
                    icon: const Icon(Icons.upload_outlined),
                    label: const Text('Backup jetzt erstellen'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _lokalImportieren,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Neuestes Backup importieren'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Google Drive Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    angemeldet
                        ? 'Angemeldet als ${DriveSyncService.instance.angemeldetAls}'
                        : 'Nicht angemeldet. Voraussetzung: eigenes Google-Cloud-Projekt gemäß README.',
                  ),
                  const SizedBox(height: 12),
                  if (!angemeldet)
                    FilledButton.icon(
                      onPressed: _busy ? null : _driveAnmelden,
                      icon: const Icon(Icons.login),
                      label: const Text('Anmelden'),
                    )
                  else ...[
                    FilledButton.icon(
                      onPressed: _busy ? null : _driveHochladen,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Backup jetzt hochladen'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _driveHerunterladen,
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: const Text('Backup wiederherstellen'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _busy ? null : _driveAbmelden, child: const Text('Abmelden')),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
