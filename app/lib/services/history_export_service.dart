import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../models/pferd.dart';
import '../widgets/date_format_x.dart';

/// Erstellt eine chronologische Text-Historie (Impfungen, Entwurmungen,
/// erledigte Gesundheitstermine) je Pferd - als Merkliste/Nachweis teilbar,
/// z. B. beim Verkauf oder Stallwechsel.
class HistoryExportService {
  HistoryExportService._();
  static final HistoryExportService instance = HistoryExportService._();

  Future<File> exportTextFor(Pferd pferd) async {
    final db = DatabaseHelper.instance;
    final impfungen = await db.getImpfungenForPferd(pferd.id);
    final entwurmungen = await db.getEntwurmungenForPferd(pferd.id);
    final erledigteTermine =
        (await db.getGesundheitsterminForPferd(pferd.id)).where((g) => g.erledigt).toList();

    final buffer = StringBuffer()
      ..writeln('Gesundheitshistorie – ${pferd.anzeigename}')
      ..writeln('Erstellt am ${DateTime.now().deDate}')
      ..writeln('=' * 50)
      ..writeln();

    buffer.writeln('IMPFUNGEN');
    if (impfungen.isEmpty) buffer.writeln('  (keine Einträge)');
    for (final i in impfungen) {
      buffer.writeln(
        '  ${i.geimpftAm.deDate}  ${i.impfstoffTyp.label}'
        '${i.chargennummer != null ? ' – Charge ${i.chargennummer}' : ''}'
        ' (fällig ab ${i.faelligAm.deDate})',
      );
    }
    buffer.writeln();

    buffer.writeln('ENTWURMUNGEN');
    if (entwurmungen.isEmpty) buffer.writeln('  (keine Einträge)');
    for (final e in entwurmungen) {
      buffer.writeln(
        '  ${e.durchgefuehrtAm.deDate}  ${e.methode.label}'
        '${e.praeparatOderWirkstoff != null ? ' – ${e.praeparatOderWirkstoff}' : ''}'
        '${e.ergebnis != null ? ' (Ergebnis: ${e.ergebnis})' : ''}',
      );
    }
    buffer.writeln();

    buffer.writeln('ERLEDIGTE GESUNDHEITSTERMINE');
    if (erledigteTermine.isEmpty) buffer.writeln('  (keine Einträge)');
    for (final g in erledigteTermine) {
      buffer.writeln('  ${(g.letzteDurchfuehrungAm ?? g.faelligAm).deDate}  ${g.typ.label}');
    }

    final tempDir = await getTemporaryDirectory();
    final dateiName = 'historie_${pferd.name.replaceAll(' ', '_')}.txt';
    final datei = File(p.join(tempDir.path, dateiName));
    await datei.writeAsString(buffer.toString());
    return datei;
  }

  Future<void> exportUndTeilen(Pferd pferd) async {
    final datei = await exportTextFor(pferd);
    await SharePlus.instance.share(ShareParams(files: [XFile(datei.path)]));
  }
}
