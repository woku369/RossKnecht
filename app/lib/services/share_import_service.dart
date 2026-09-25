import 'package:flutter/services.dart';

/// Empfaengt eine per Android-Teilen-Dialog geschickte Backup-ZIP-Datei vom
/// nativen MainActivity-Code (siehe android/.../MainActivity.kt) und stellt
/// sie als Dart-Callback bereit.
class ShareImportService {
  ShareImportService._();
  static final ShareImportService instance = ShareImportService._();

  static const _channel = MethodChannel('at.kraeutermeister.rossknecht/import');

  Future<String?> holeBeimStartEmpfangeneZip() {
    return _channel.invokeMethod<String>('consumeSharedZip');
  }

  void aufNeueGeteilteZipHoeren(void Function(String pfad) onReceived) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedZipReceived') {
        onReceived(call.arguments as String);
      }
    });
  }
}
