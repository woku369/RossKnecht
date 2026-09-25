import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/decke.dart';
import '../models/dienstleister.dart';
import '../models/entwurmung.dart';
import '../models/gesundheitstermin.dart';
import '../models/impfung.dart';
import '../models/pferd.dart';
import '../models/pferde_dokument.dart';
import '../models/pferde_versicherung.dart';
import '../models/turnierlizenz.dart';
import '../models/turnierstart.dart';
import '../models/wartungs_task.dart';

/// Zentraler SQLite-Zugriff. Ein Pferd (`pferde`) ist das Elternobjekt,
/// alle Kind-Tabellen haengen per `ON DELETE CASCADE` daran - Pferd
/// loeschen entfernt automatisch alle zugehoerigen Daten. `dienstleister`
/// ist eigenstaendig und wird von `impfungen`/`gesundheitstermine` nur per
/// nullbarer Fremdschluessel-Spalte referenziert (`ON DELETE SET NULL`).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'rossknecht.db';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createPferdeTable);
    await db.execute(_createDienstleisterTable);
    await db.execute(_createImpfungenTable);
    await db.execute(_createEntwurmungenTable);
    await db.execute(_createGesundheitsterminTable);
    await db.execute(_createTurnierlizenzenTable);
    await db.execute(_createTurnierstartsTable);
    await db.execute(_createDeckenTable);
    await db.execute(_createDokumenteTable);
    await db.execute(_createVersicherungenTable);
    await db.execute(_createWartungsTasksTable);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Noch keine Migrationen noetig (Version 1 = Erstauslieferung). Kuenftige
    // Schema-Aenderungen folgen dem kumulativen Muster aus FuhrparkMeister:
    // if (oldVersion < 2) { await db.execute('ALTER TABLE ... ADD COLUMN ...'); }
  }

  static const String _createPferdeTable = '''
    CREATE TABLE pferde (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      rasse TEXT,
      geschlecht TEXT NOT NULL,
      geburtsjahr INTEGER,
      farbe TEXT,
      abzeichen TEXT,
      lebensnummer TEXT,
      chipnummer TEXT,
      besitzer TEXT,
      stallplatz TEXT,
      ankunftsdatum TEXT,
      foto_pfad TEXT,
      notizen TEXT,
      archiviert INTEGER NOT NULL DEFAULT 0,
      archiviert_grund TEXT,
      archiviert_am TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createDienstleisterTable = '''
    CREATE TABLE dienstleister (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      typ TEXT NOT NULL,
      telefon TEXT,
      adresse TEXT,
      notizen TEXT
    )
  ''';

  static const String _createImpfungenTable = '''
    CREATE TABLE impfungen (
      id TEXT PRIMARY KEY,
      pferd_id TEXT NOT NULL REFERENCES pferde(id) ON DELETE CASCADE,
      impfstoff_typ TEXT NOT NULL,
      geimpft_am TEXT NOT NULL,
      faellig_am TEXT NOT NULL,
      chargennummer TEXT,
      dienstleister_id TEXT REFERENCES dienstleister(id) ON DELETE SET NULL,
      erinnerung_tage_vorher INTEGER NOT NULL DEFAULT 30,
      notizen TEXT
    )
  ''';

  static const String _createEntwurmungenTable = '''
    CREATE TABLE entwurmungen (
      id TEXT PRIMARY KEY,
      pferd_id TEXT NOT NULL REFERENCES pferde(id) ON DELETE CASCADE,
      methode TEXT NOT NULL,
      praeparat_oder_wirkstoff TEXT,
      durchgefuehrt_am TEXT NOT NULL,
      faellig_am TEXT NOT NULL,
      ergebnis TEXT,
      erinnerung_tage_vorher INTEGER NOT NULL DEFAULT 14,
      notizen TEXT
    )
  ''';

  static const String _createGesundheitsterminTable = '''
    CREATE TABLE gesundheitstermine (
      id TEXT PRIMARY KEY,
      pferd_id TEXT NOT NULL REFERENCES pferde(id) ON DELETE CASCADE,
      typ TEXT NOT NULL,
      faellig_am TEXT NOT NULL,
      letzte_durchfuehrung_am TEXT,
      erinnerung_tage_vorher INTEGER NOT NULL DEFAULT 7,
      erledigt INTEGER NOT NULL DEFAULT 0,
      dienstleister_id TEXT REFERENCES dienstleister(id) ON DELETE SET NULL,
      notizen TEXT
    )
  ''';

  static const String _createTurnierlizenzenTable = '''
    CREATE TABLE turnierlizenzen (
      id TEXT PRIMARY KEY,
      pferd_id TEXT NOT NULL REFERENCES pferde(id) ON DELETE CASCADE,
      verband TEXT NOT NULL,
      lizenznummer TEXT,
      gueltig_von TEXT NOT NULL,
      gueltig_bis TEXT NOT NULL,
      erinnerung_tage_vorher INTEGER NOT NULL DEFAULT 30,
      notizen TEXT
    )
  ''';

  static const String _createTurnierstartsTable = '''
    CREATE TABLE turnierstarts (
      id TEXT PRIMARY KEY,
      pferd_id TEXT NOT NULL REFERENCES pferde(id) ON DELETE CASCADE,
      datum TEXT NOT NULL,
      turnierort TEXT NOT NULL,
      disziplin TEXT,
      ergebnis TEXT,
      notizen TEXT
    )
  ''';

  static const String _createDeckenTable = '''
    CREATE TABLE decken (
      id TEXT PRIMARY KEY,
      pferd_id TEXT NOT NULL REFERENCES pferde(id) ON DELETE CASCADE,
      typ TEXT NOT NULL,
      fuellung_gramm INTEGER,
      groesse_cm INTEGER,
      in_gebrauch INTEGER NOT NULL DEFAULT 0,
      zustand TEXT NOT NULL DEFAULT 'gut',
      gewaschen_am TEXT,
      impraegnierung_faellig_am TEXT,
      erinnerung_tage_vorher INTEGER NOT NULL DEFAULT 14,
      notizen TEXT
    )
  ''';

  static const String _createDokumenteTable = '''
    CREATE TABLE dokumente (
      id TEXT PRIMARY KEY,
      pferd_id TEXT NOT NULL REFERENCES pferde(id) ON DELETE CASCADE,
      kategorie TEXT NOT NULL,
      dateipfad TEXT NOT NULL,
      titel TEXT NOT NULL,
      erstellt_am TEXT NOT NULL,
      notizen TEXT
    )
  ''';

  static const String _createVersicherungenTable = '''
    CREATE TABLE versicherungen (
      id TEXT PRIMARY KEY,
      pferd_id TEXT NOT NULL REFERENCES pferde(id) ON DELETE CASCADE,
      gesellschaft TEXT NOT NULL,
      polizzennummer TEXT NOT NULL,
      art TEXT NOT NULL,
      gueltig_ab TEXT,
      faelligkeit_jaehrlich_am TEXT NOT NULL,
      zahlungsintervall TEXT NOT NULL DEFAULT 'jaehrlich',
      praemie_euro REAL,
      notizen TEXT
    )
  ''';

  static const String _createWartungsTasksTable = '''
    CREATE TABLE wartungs_tasks (
      id TEXT PRIMARY KEY,
      pferd_id TEXT NOT NULL REFERENCES pferde(id) ON DELETE CASCADE,
      titel TEXT NOT NULL,
      notizen TEXT,
      erledigt INTEGER NOT NULL DEFAULT 0,
      erstellt_am TEXT NOT NULL,
      erledigt_am TEXT,
      faellig_am TEXT,
      erinnerung_tage_vorher INTEGER NOT NULL DEFAULT 3
    )
  ''';

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_impfungen_pferd ON impfungen(pferd_id)');
    await db.execute('CREATE INDEX idx_entwurmungen_pferd ON entwurmungen(pferd_id)');
    await db.execute('CREATE INDEX idx_gesundheitstermine_pferd ON gesundheitstermine(pferd_id)');
    await db.execute('CREATE INDEX idx_turnierlizenzen_pferd ON turnierlizenzen(pferd_id)');
    await db.execute('CREATE INDEX idx_turnierstarts_pferd ON turnierstarts(pferd_id)');
    await db.execute('CREATE INDEX idx_decken_pferd ON decken(pferd_id)');
    await db.execute('CREATE INDEX idx_dokumente_pferd ON dokumente(pferd_id)');
    await db.execute('CREATE INDEX idx_versicherungen_pferd ON versicherungen(pferd_id)');
    await db.execute('CREATE INDEX idx_wartungs_tasks_pferd ON wartungs_tasks(pferd_id)');
  }

  // ---------------- Pferde ----------------

  Future<void> insertPferd(Pferd p) async {
    final db = await database;
    await db.insert('pferde', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePferd(Pferd p) async {
    final db = await database;
    await db.update('pferde', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deletePferd(String id) async {
    final db = await database;
    await db.delete('pferde', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Pferd>> getAllPferde() async {
    final db = await database;
    final rows = await db.query('pferde', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Pferd.fromMap).toList();
  }

  // ---------------- Dienstleister ----------------

  Future<void> insertDienstleister(Dienstleister d) async {
    final db = await database;
    await db.insert('dienstleister', d.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDienstleister(Dienstleister d) async {
    final db = await database;
    await db.update('dienstleister', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> deleteDienstleister(String id) async {
    final db = await database;
    await db.delete('dienstleister', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Dienstleister>> getAllDienstleister() async {
    final db = await database;
    final rows = await db.query('dienstleister', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Dienstleister.fromMap).toList();
  }

  /// Loescht keine Datensaetze, sondern setzt die Fremdschluessel-Referenz
  /// bei betroffenen Impfungen/Gesundheitsterminen auf null - eine
  /// Behandlungshistorie soll auch nach Wegfall des Dienstleisters
  /// erhalten bleiben.
  Future<void> clearDienstleisterReferences(String dienstleisterId) async {
    final db = await database;
    await db.update(
      'impfungen',
      {'dienstleister_id': null},
      where: 'dienstleister_id = ?',
      whereArgs: [dienstleisterId],
    );
    await db.update(
      'gesundheitstermine',
      {'dienstleister_id': null},
      where: 'dienstleister_id = ?',
      whereArgs: [dienstleisterId],
    );
  }

  // ---------------- Impfungen ----------------

  Future<void> insertImpfung(Impfung i) async {
    final db = await database;
    await db.insert('impfungen', i.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateImpfung(Impfung i) async {
    final db = await database;
    await db.update('impfungen', i.toMap(), where: 'id = ?', whereArgs: [i.id]);
  }

  Future<void> deleteImpfung(String id) async {
    final db = await database;
    await db.delete('impfungen', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Impfung>> getImpfungenForPferd(String pferdId) async {
    final db = await database;
    final rows = await db.query(
      'impfungen',
      where: 'pferd_id = ?',
      whereArgs: [pferdId],
      orderBy: 'geimpft_am DESC',
    );
    return rows.map(Impfung.fromMap).toList();
  }

  Future<List<Impfung>> getAllImpfungen() async {
    final db = await database;
    final rows = await db.query('impfungen', orderBy: 'geimpft_am DESC');
    return rows.map(Impfung.fromMap).toList();
  }

  // ---------------- Entwurmungen ----------------

  Future<void> insertEntwurmung(Entwurmung e) async {
    final db = await database;
    await db.insert('entwurmungen', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEntwurmung(Entwurmung e) async {
    final db = await database;
    await db.update('entwurmungen', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteEntwurmung(String id) async {
    final db = await database;
    await db.delete('entwurmungen', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Entwurmung>> getEntwurmungenForPferd(String pferdId) async {
    final db = await database;
    final rows = await db.query(
      'entwurmungen',
      where: 'pferd_id = ?',
      whereArgs: [pferdId],
      orderBy: 'durchgefuehrt_am DESC',
    );
    return rows.map(Entwurmung.fromMap).toList();
  }

  Future<List<Entwurmung>> getAllEntwurmungen() async {
    final db = await database;
    final rows = await db.query('entwurmungen', orderBy: 'durchgefuehrt_am DESC');
    return rows.map(Entwurmung.fromMap).toList();
  }

  // ---------------- Gesundheitstermine ----------------

  Future<void> insertGesundheitstermin(Gesundheitstermin g) async {
    final db = await database;
    await db.insert('gesundheitstermine', g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateGesundheitstermin(Gesundheitstermin g) async {
    final db = await database;
    await db.update('gesundheitstermine', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<void> deleteGesundheitstermin(String id) async {
    final db = await database;
    await db.delete('gesundheitstermine', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Gesundheitstermin>> getGesundheitsterminForPferd(String pferdId) async {
    final db = await database;
    final rows = await db.query(
      'gesundheitstermine',
      where: 'pferd_id = ?',
      whereArgs: [pferdId],
      orderBy: 'faellig_am ASC',
    );
    return rows.map(Gesundheitstermin.fromMap).toList();
  }

  Future<List<Gesundheitstermin>> getAllOffeneGesundheitstermine() async {
    final db = await database;
    final rows = await db.query('gesundheitstermine', where: 'erledigt = 0', orderBy: 'faellig_am ASC');
    return rows.map(Gesundheitstermin.fromMap).toList();
  }

  // ---------------- Turnierlizenzen ----------------

  Future<void> insertTurnierlizenz(Turnierlizenz t) async {
    final db = await database;
    await db.insert('turnierlizenzen', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTurnierlizenz(Turnierlizenz t) async {
    final db = await database;
    await db.update('turnierlizenzen', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTurnierlizenz(String id) async {
    final db = await database;
    await db.delete('turnierlizenzen', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Turnierlizenz>> getTurnierlizenzenForPferd(String pferdId) async {
    final db = await database;
    final rows = await db.query(
      'turnierlizenzen',
      where: 'pferd_id = ?',
      whereArgs: [pferdId],
      orderBy: 'gueltig_bis DESC',
    );
    return rows.map(Turnierlizenz.fromMap).toList();
  }

  Future<List<Turnierlizenz>> getAllTurnierlizenzen() async {
    final db = await database;
    final rows = await db.query('turnierlizenzen', orderBy: 'gueltig_bis ASC');
    return rows.map(Turnierlizenz.fromMap).toList();
  }

  // ---------------- Turnierstarts ----------------

  Future<void> insertTurnierstart(Turnierstart t) async {
    final db = await database;
    await db.insert('turnierstarts', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTurnierstart(Turnierstart t) async {
    final db = await database;
    await db.update('turnierstarts', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTurnierstart(String id) async {
    final db = await database;
    await db.delete('turnierstarts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Turnierstart>> getTurnierstartsForPferd(String pferdId) async {
    final db = await database;
    final rows = await db.query(
      'turnierstarts',
      where: 'pferd_id = ?',
      whereArgs: [pferdId],
      orderBy: 'datum DESC',
    );
    return rows.map(Turnierstart.fromMap).toList();
  }

  // ---------------- Decken ----------------

  Future<void> insertDecke(Decke d) async {
    final db = await database;
    await db.insert('decken', d.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDecke(Decke d) async {
    final db = await database;
    await db.update('decken', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> deleteDecke(String id) async {
    final db = await database;
    await db.delete('decken', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Decke>> getDeckenForPferd(String pferdId) async {
    final db = await database;
    final rows = await db.query(
      'decken',
      where: 'pferd_id = ?',
      whereArgs: [pferdId],
      orderBy: 'in_gebrauch DESC, typ ASC',
    );
    return rows.map(Decke.fromMap).toList();
  }

  Future<List<Decke>> getAllDecken() async {
    final db = await database;
    final rows = await db.query('decken');
    return rows.map(Decke.fromMap).toList();
  }

  // ---------------- Dokumente ----------------

  Future<void> insertDokument(PferdeDokument d) async {
    final db = await database;
    await db.insert('dokumente', d.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDokument(PferdeDokument d) async {
    final db = await database;
    await db.update('dokumente', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> deleteDokument(String id) async {
    final db = await database;
    await db.delete('dokumente', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PferdeDokument>> getDokumenteForPferd(String pferdId) async {
    final db = await database;
    final rows = await db.query(
      'dokumente',
      where: 'pferd_id = ?',
      whereArgs: [pferdId],
      orderBy: 'erstellt_am DESC',
    );
    return rows.map(PferdeDokument.fromMap).toList();
  }

  // ---------------- Versicherungen ----------------

  Future<void> insertVersicherung(PferdeVersicherung v) async {
    final db = await database;
    await db.insert('versicherungen', v.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateVersicherung(PferdeVersicherung v) async {
    final db = await database;
    await db.update('versicherungen', v.toMap(), where: 'id = ?', whereArgs: [v.id]);
  }

  Future<void> deleteVersicherung(String id) async {
    final db = await database;
    await db.delete('versicherungen', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PferdeVersicherung>> getVersicherungenForPferd(String pferdId) async {
    final db = await database;
    final rows = await db.query(
      'versicherungen',
      where: 'pferd_id = ?',
      whereArgs: [pferdId],
      orderBy: 'faelligkeit_jaehrlich_am ASC',
    );
    return rows.map(PferdeVersicherung.fromMap).toList();
  }

  Future<List<PferdeVersicherung>> getAllVersicherungen() async {
    final db = await database;
    final rows = await db.query('versicherungen');
    return rows.map(PferdeVersicherung.fromMap).toList();
  }

  // ---------------- Wartungs-Tasks ----------------

  Future<void> insertWartungsTask(WartungsTask t) async {
    final db = await database;
    await db.insert('wartungs_tasks', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateWartungsTask(WartungsTask t) async {
    final db = await database;
    await db.update('wartungs_tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteWartungsTask(String id) async {
    final db = await database;
    await db.delete('wartungs_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WartungsTask>> getWartungsTasksForPferd(String pferdId) async {
    final db = await database;
    final rows = await db.query(
      'wartungs_tasks',
      where: 'pferd_id = ?',
      whereArgs: [pferdId],
      orderBy: 'erledigt ASC, faellig_am ASC',
    );
    return rows.map(WartungsTask.fromMap).toList();
  }

  Future<List<WartungsTask>> getAllOffeneWartungsTasksMitFaelligkeit() async {
    final db = await database;
    final rows = await db.query(
      'wartungs_tasks',
      where: 'erledigt = 0 AND faellig_am IS NOT NULL',
      orderBy: 'faellig_am ASC',
    );
    return rows.map(WartungsTask.fromMap).toList();
  }

  // ---------------- Backup: Rohdaten-Export/Import ----------------

  static const List<String> backupTables = [
    'pferde',
    'dienstleister',
    'impfungen',
    'entwurmungen',
    'gesundheitstermine',
    'turnierlizenzen',
    'turnierstarts',
    'decken',
    'dokumente',
    'versicherungen',
    'wartungs_tasks',
  ];

  Future<Map<String, List<Map<String, Object?>>>> exportAllRaw() async {
    final db = await database;
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in backupTables) {
      result[table] = await db.query(table);
    }
    return result;
  }

  /// Ersetzt den kompletten lokalen Datenbestand durch die uebergebenen
  /// Rohdaten ("letzter Stand gewinnt", kein Merge) - fuer ZIP-Restore und
  /// Google-Drive-Download.
  Future<void> replaceAllRaw(Map<String, List<Map<String, Object?>>> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Pferde loeschen cascadet alle Kind-Tabellen automatisch mit.
      await txn.delete('pferde');
      await txn.delete('dienstleister');
      for (final table in backupTables) {
        final rows = data[table];
        if (rows == null) continue;
        for (final row in rows) {
          await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}
