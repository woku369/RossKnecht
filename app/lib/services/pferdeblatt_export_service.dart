import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../models/decke.dart';
import '../models/entwurmung.dart';
import '../models/impfung.dart';
import '../models/pferd.dart';
import '../models/pferde_versicherung.dart';
import '../models/turnierlizenz.dart';

/// Erstellt ein A4-Datenblatt je Pferd - Stammdaten, Impf-/Entwurmungs-
/// historie, Turnierlizenzen, Decken, Versicherungen - fuer die physische
/// Papierablage (z. B. Stallmappe), ohne Fotos aus der Dokumenten-Galerie.
class PferdeblattExportService {
  PferdeblattExportService._();
  static final PferdeblattExportService instance = PferdeblattExportService._();

  Future<File> exportPdfFor(Pferd pferd) async {
    final db = DatabaseHelper.instance;
    final impfungen = await db.getImpfungenForPferd(pferd.id);
    final entwurmungen = await db.getEntwurmungenForPferd(pferd.id);
    final behandlungen = await db.getBehandlungenForPferd(pferd.id);
    final lizenzen = await db.getTurnierlizenzenForPferd(pferd.id);
    final decken = await db.getDeckenForPferd(pferd.id);
    final versicherungen = await db.getVersicherungenForPferd(pferd.id);

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: 'Pferdedatenblatt – ${pferd.anzeigename}'),
          _stammdatenTabelle(pferd),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Impfungen'),
          _tabelle(
            spalten: const ['Datum', 'Impfstoff', 'Charge', 'Fällig ab'],
            zeilen: impfungen
                .map((i) => [_fmt(i.geimpftAm), i.impfstoffTyp.label, i.chargennummer ?? '-', _fmt(i.faelligAm)])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Entwurmung'),
          _tabelle(
            spalten: const ['Datum', 'Methode', 'Präparat/Ergebnis', 'Fällig ab'],
            zeilen: entwurmungen
                .map((e) => [
                      _fmt(e.durchgefuehrtAm),
                      e.methode.label,
                      e.praeparatOderWirkstoff ?? e.ergebnis ?? '-',
                      _fmt(e.faelligAm),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Tierärztliche Behandlungen'),
          _tabelle(
            spalten: const ['Datum', 'Grund', 'Behandlung', 'Kosten'],
            zeilen: behandlungen
                .map((b) => [
                      _fmt(b.datum),
                      b.grund,
                      b.behandlung ?? '-',
                      b.kostenEuro != null ? '${b.kostenEuro!.toStringAsFixed(2)} €' : '-',
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Turnierlizenzen'),
          _tabelle(
            spalten: const ['Verband', 'Lizenznummer', 'Gültig von', 'Gültig bis'],
            zeilen: lizenzen
                .map((l) => [l.verband.label, l.lizenznummer ?? '-', _fmt(l.gueltigVon), _fmt(l.gueltigBis)])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Decken'),
          _tabelle(
            spalten: const ['Typ', 'Füllung (g)', 'Größe (cm)', 'Zustand', 'In Gebrauch'],
            zeilen: decken
                .map((d) => [
                      d.typ.label,
                      d.fuellungGramm?.toString() ?? '-',
                      d.groesseCm?.toString() ?? '-',
                      d.zustand.label,
                      d.inGebrauch ? 'Ja' : 'Nein',
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Versicherungen'),
          _tabelle(
            spalten: const ['Art', 'Gesellschaft', 'Polizzennummer', 'Fälligkeit'],
            zeilen: versicherungen
                .map((v) => [v.art.label, v.gesellschaft, v.polizzennummer, _fmt(v.naechsteFaelligkeit)])
                .toList(),
          ),
        ],
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final dateiName = 'pferdeblatt_${pferd.name.replaceAll(' ', '_')}.pdf';
    final datei = File(p.join(tempDir.path, dateiName));
    await datei.writeAsBytes(await doc.save());
    return datei;
  }

  Future<void> exportUndTeilen(Pferd pferd) async {
    final datei = await exportPdfFor(pferd);
    await SharePlus.instance.share(ShareParams(files: [XFile(datei.path)]));
  }

  pw.Widget _stammdatenTabelle(Pferd pferd) {
    final zeilen = <List<String>>[
      ['Rufname', pferd.anzeigename],
      if (pferd.eingetragenerName != null && pferd.eingetragenerName!.isNotEmpty)
        ['Eingetragener Name', pferd.eingetragenerName!],
      ['Rasse', pferd.rasse ?? '-'],
      ['Geschlecht', pferd.geschlecht.label],
      ['Geburtsjahr', pferd.geburtsjahr?.toString() ?? '-'],
      ['Farbe', pferd.farbe ?? '-'],
      ['Abzeichen', pferd.abzeichen ?? '-'],
      ['Lebensnummer (UELN)', pferd.lebensnummer ?? '-'],
      ['Chipnummer', pferd.chipnummer ?? '-'],
      ['Besitzer', pferd.besitzer ?? '-'],
      ['Stallplatz', pferd.stallplatz ?? '-'],
      if (pferd.externerStallname != null && pferd.externerStallname!.isNotEmpty)
        ['Auswärtiger Stall', pferd.externerStallname!],
      if (pferd.externerKontakt != null && pferd.externerKontakt!.isNotEmpty)
        ['Kontakt (auswärts)', pferd.externerKontakt!],
    ];
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(2)},
      children: zeilen
          .map(
            (z) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(z[0], style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(z[1])),
            ]),
          )
          .toList(),
    );
  }

  pw.Widget _tabelle({required List<String> spalten, required List<List<String>> zeilen}) {
    if (zeilen.isEmpty) {
      return pw.Text('(keine Einträge)', style: const pw.TextStyle(color: PdfColors.grey600));
    }
    return pw.TableHelper.fromTextArray(
      headers: spalten,
      data: zeilen,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}
