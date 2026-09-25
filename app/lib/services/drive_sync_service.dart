import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manueller Google-Drive-Sync mit dem eingeschraenkten Scope `drive.file` -
/// die App sieht dadurch nur Dateien, die sie selbst in einem eigenen
/// "RossKnecht"-Ordner in Drive anlegt. Direkte REST-Calls (kein
/// googleapis-SDK). Voll-Snapshot ohne Merge: "letzter Stand gewinnt" beim
/// Hoch- bzw. Herunterladen.
class DriveSyncService {
  DriveSyncService._();
  static final DriveSyncService instance = DriveSyncService._();

  static const _folderName = 'RossKnecht';
  static const _backupFileName = 'rossknecht_backup.zip';

  final _googleSignIn = GoogleSignIn(scopes: ['https://www.googleapis.com/auth/drive.file']);

  GoogleSignInAccount? _account;
  bool get istAngemeldet => _account != null;
  String? get angemeldetAls => _account?.email;

  Future<bool> anmelden() async {
    _account = await _googleSignIn.signIn();
    return _account != null;
  }

  Future<void> abmelden() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  Future<Map<String, String>> _authHeaders() async {
    final auth = await _account!.authentication;
    return {'Authorization': 'Bearer ${auth.accessToken}'};
  }

  Future<String> _findeOderErstelleOrdner() async {
    final headers = await _authHeaders();
    final query = Uri.encodeComponent(
      "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false",
    );
    final sucheUri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files?q=$query&spaces=drive&fields=files(id,name)',
    );
    final sucheResponse = await http.get(sucheUri, headers: headers);
    final sucheDaten = jsonDecode(sucheResponse.body) as Map<String, dynamic>;
    final gefunden = (sucheDaten['files'] as List?) ?? [];
    if (gefunden.isNotEmpty) {
      return gefunden.first['id'] as String;
    }

    final erstelleUri = Uri.parse('https://www.googleapis.com/drive/v3/files');
    final erstelleResponse = await http.post(
      erstelleUri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'name': _folderName, 'mimeType': 'application/vnd.google-apps.folder'}),
    );
    final erstellt = jsonDecode(erstelleResponse.body) as Map<String, dynamic>;
    return erstellt['id'] as String;
  }

  Future<String?> _findeBackupDateiId(String ordnerId) async {
    final headers = await _authHeaders();
    final query = Uri.encodeComponent("name='$_backupFileName' and '$ordnerId' in parents and trashed=false");
    final uri = Uri.parse('https://www.googleapis.com/drive/v3/files?q=$query&fields=files(id,name)');
    final response = await http.get(uri, headers: headers);
    final daten = jsonDecode(response.body) as Map<String, dynamic>;
    final gefunden = (daten['files'] as List?) ?? [];
    if (gefunden.isEmpty) return null;
    return gefunden.first['id'] as String;
  }

  /// Voll-Snapshot (Datenbank + Dokumentenfotos als ZIP, siehe
  /// LocalBackupService) nach Drive hochladen - ueberschreibt eine
  /// vorhandene Backup-Datei im App-Ordner.
  Future<void> uploadBackup(File zipDatei) async {
    if (!istAngemeldet) throw StateError('Nicht bei Google angemeldet.');
    final ordnerId = await _findeOderErstelleOrdner();
    final vorhandeneId = await _findeBackupDateiId(ordnerId);
    final headers = await _authHeaders();
    final bytes = await zipDatei.readAsBytes();

    final metadata = vorhandeneId == null
        ? {
            'name': _backupFileName,
            'parents': [ordnerId],
          }
        : {'name': _backupFileName};

    final boundary = 'rossknecht_${DateTime.now().millisecondsSinceEpoch}';
    final body = BytesBuilder()
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'))
      ..add(utf8.encode('${jsonEncode(metadata)}\r\n'))
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(utf8.encode('Content-Type: application/zip\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--'));

    final uri = vorhandeneId == null
        ? Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart')
        : Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$vorhandeneId?uploadType=multipart');

    final request = http.Request(vorhandeneId == null ? 'POST' : 'PATCH', uri)
      ..headers.addAll({
        ...headers,
        'Content-Type': 'multipart/related; boundary=$boundary',
      })
      ..bodyBytes = body.toBytes();

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode >= 300) {
      throw StateError('Drive-Upload fehlgeschlagen (${streamedResponse.statusCode}).');
    }
  }

  /// Laedt den Voll-Snapshot herunter und gibt den lokalen Pfad der
  /// heruntergeladenen ZIP-Datei zurueck (zum Import via
  /// LocalBackupService.importFromZip).
  Future<File> downloadBackup() async {
    if (!istAngemeldet) throw StateError('Nicht bei Google angemeldet.');
    final ordnerId = await _findeOderErstelleOrdner();
    final dateiId = await _findeBackupDateiId(ordnerId);
    if (dateiId == null) {
      throw StateError('Kein Backup im Drive-Ordner "$_folderName" gefunden.');
    }
    final headers = await _authHeaders();
    final uri = Uri.parse('https://www.googleapis.com/drive/v3/files/$dateiId?alt=media');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode >= 300) {
      throw StateError('Drive-Download fehlgeschlagen (${response.statusCode}).');
    }
    final tempDir = await getTemporaryDirectory();
    final zielPfad = p.join(tempDir.path, _backupFileName);
    final datei = File(zielPfad);
    await datei.writeAsBytes(response.bodyBytes);
    return datei;
  }
}
