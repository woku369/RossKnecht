import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

/// Lokales ZIP-Backup ohne jede Einrichtung: Export legt eine Datei im
/// App-eigenen Ordner ab, Import liest die neueste ZIP-Datei aus diesem
/// Ordner ein. Enthaelt backup.json (alle Tabellen als Rohdaten) sowie
/// alle Dokumenten-/Fotodateien.
class LocalBackupService {
  LocalBackupService._();
  static final LocalBackupService instance = LocalBackupService._();

  Future<Directory> _backupDir() async {
    final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'RossKnecht-Backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _dokumenteDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, 'dokumente'));
  }

  Future<File> exportToZip() async {
    final data = await DatabaseHelper.instance.exportAllRaw();
    final json = jsonEncode(data);

    final archive = Archive();
    archive.addFile(ArchiveFile('backup.json', json.length, utf8.encode(json)));

    final dokumenteDir = await _dokumenteDir();
    if (await dokumenteDir.exists()) {
      for (final entity in dokumenteDir.listSync()) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile('documents/${p.basename(entity.path)}', bytes.length, bytes));
        }
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    final backupDir = await _backupDir();
    final zeitstempel = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final zielDatei = File(p.join(backupDir.path, 'rossknecht_backup_$zeitstempel.zip'));
    await zielDatei.writeAsBytes(zipBytes!);
    return zielDatei;
  }

  Future<File?> findeNeuesteBackupDatei() async {
    final backupDir = await _backupDir();
    if (!await backupDir.exists()) return null;
    final dateien = backupDir.listSync().whereType<File>().where((f) => f.path.endsWith('.zip')).toList();
    if (dateien.isEmpty) return null;
    dateien.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return dateien.first;
  }

  Future<void> importFromZip(String pfad) async {
    final bytes = await File(pfad).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dokumenteDir = await _dokumenteDir();
    if (!await dokumenteDir.exists()) {
      await dokumenteDir.create(recursive: true);
    }

    Map<String, List<Map<String, Object?>>>? data;
    for (final file in archive) {
      if (!file.isFile) continue;
      if (file.name == 'backup.json') {
        final content = utf8.decode(file.content as List<int>);
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        data = decoded.map(
          (key, value) => MapEntry(key, (value as List).cast<Map<String, Object?>>()),
        );
      } else if (file.name.startsWith('documents/')) {
        final zielPfad = p.join(dokumenteDir.path, p.basename(file.name));
        await File(zielPfad).writeAsBytes(file.content as List<int>);
      }
    }

    if (data != null) {
      await DatabaseHelper.instance.replaceAllRaw(data);
    }
  }

  Future<void> importNeuesteAusBackupOrdner() async {
    final datei = await findeNeuesteBackupDatei();
    if (datei == null) {
      throw StateError('Keine Backup-Datei im Ordner gefunden.');
    }
    await importFromZip(datei.path);
  }
}
