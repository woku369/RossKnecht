import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Verwaltet Bilddateien (Pferdefotos, Dokumenten-Scans) im App-eigenen
/// Speicher. Nur der Dateipfad wird in der Datenbank abgelegt, die Datei
/// selbst liegt lokal im App-Verzeichnis.
class DocumentStorage {
  DocumentStorage._();
  static final DocumentStorage instance = DocumentStorage._();

  Future<Directory> _dokumenteDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'dokumente'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Kopiert eine Datei (z. B. von image_picker) in den App-eigenen Ordner
  /// und gibt den neuen, dauerhaften Pfad zurueck.
  Future<String> speichereKopie(String quellPfad, {required String praefix}) async {
    final dir = await _dokumenteDir();
    final erweiterung = p.extension(quellPfad);
    final zielName = '${praefix}_${DateTime.now().millisecondsSinceEpoch}$erweiterung';
    final zielPfad = p.join(dir.path, zielName);
    await File(quellPfad).copy(zielPfad);
    return zielPfad;
  }

  Future<void> deleteFile(String pfad) async {
    final file = File(pfad);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
