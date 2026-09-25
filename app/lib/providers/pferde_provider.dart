import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/behandlung.dart';
import '../models/decke.dart';
import '../models/dienstleister.dart';
import '../models/entwurmung.dart';
import '../models/gesundheitstermin.dart';
import '../models/impfung.dart';
import '../models/pferd.dart';
import '../models/pferde_dokument.dart';
import '../models/pferde_versicherung.dart';
import '../models/reminder.dart';
import '../models/turnierlizenz.dart';
import '../models/turnierstart.dart';
import '../models/wartungs_task.dart';
import '../services/document_storage.dart';
import '../services/notification_service.dart';

/// Zentraler App-State. Haelt die Pferdeliste, buendelt CRUD fuer alle
/// Kind-Entitaeten und kuemmert sich beim Speichern/Loeschen jeweils
/// auch um das Planen/Abbestellen lokaler Erinnerungen.
class PferdeProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<Pferd> _pferde = [];
  List<Dienstleister> _dienstleister = [];
  bool _loading = false;

  List<Pferd> get pferde => List.unmodifiable(_pferde);
  List<Dienstleister> get dienstleister => List.unmodifiable(_dienstleister);
  bool get loading => _loading;

  static const _versicherungReminderTage = 14;

  Future<void> loadAll() async {
    await Future.wait([loadPferde(), loadDienstleister()]);
  }

  Future<void> loadPferde() async {
    _loading = true;
    notifyListeners();
    _pferde = await _db.getAllPferde();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadDienstleister() async {
    _dienstleister = await _db.getAllDienstleister();
    notifyListeners();
  }

  // ---------------- Pferde ----------------

  Future<Pferd> addPferd({
    required String name,
    String? rasse,
    Geschlecht geschlecht = Geschlecht.wallach,
    int? geburtsjahr,
    String? farbe,
    String? abzeichen,
    String? lebensnummer,
    String? chipnummer,
    String? besitzer,
    String? stallplatz,
    DateTime? ankunftsdatum,
    String? fotoPfad,
    String? notizen,
  }) async {
    final now = DateTime.now();
    final pferd = Pferd(
      id: _uuid.v4(),
      name: name,
      rasse: rasse,
      geschlecht: geschlecht,
      geburtsjahr: geburtsjahr,
      farbe: farbe,
      abzeichen: abzeichen,
      lebensnummer: lebensnummer,
      chipnummer: chipnummer,
      besitzer: besitzer,
      stallplatz: stallplatz,
      ankunftsdatum: ankunftsdatum,
      fotoPfad: fotoPfad,
      notizen: notizen,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertPferd(pferd);
    await loadPferde();
    return pferd;
  }

  Future<void> updatePferd(Pferd pferd) async {
    pferd.updatedAt = DateTime.now();
    await _db.updatePferd(pferd);
    await loadPferde();
  }

  Future<void> archivierePferd(Pferd pferd, {required String grund}) async {
    pferd.archiviert = true;
    pferd.archiviertGrund = grund;
    pferd.archiviertAm = DateTime.now();
    await updatePferd(pferd);
  }

  Future<void> reaktivierePferd(Pferd pferd) async {
    pferd.archiviert = false;
    pferd.archiviertGrund = null;
    pferd.archiviertAm = null;
    await updatePferd(pferd);
  }

  Future<void> deletePferd(String id) async {
    final impfungen = await _db.getImpfungenForPferd(id);
    final entwurmungen = await _db.getEntwurmungenForPferd(id);
    final behandlungen = await _db.getBehandlungenForPferd(id);
    final gesundheitstermine = await _db.getGesundheitsterminForPferd(id);
    final turnierlizenzen = await _db.getTurnierlizenzenForPferd(id);
    final decken = await _db.getDeckenForPferd(id);
    final versicherungen = await _db.getVersicherungenForPferd(id);
    final wartungsTasks = await _db.getWartungsTasksForPferd(id);

    // Notification-Fehler duerfen das eigentliche Loeschen nie blockieren.
    try {
      for (final i in impfungen) {
        await NotificationService.instance.cancelReminder(i.id);
      }
      for (final e in entwurmungen) {
        await NotificationService.instance.cancelReminder(e.id);
      }
      for (final b in behandlungen) {
        await NotificationService.instance.cancelReminder(b.id);
      }
      for (final g in gesundheitstermine) {
        await NotificationService.instance.cancelReminder(g.id);
      }
      for (final t in turnierlizenzen) {
        await NotificationService.instance.cancelReminder(t.id);
      }
      for (final d in decken) {
        await NotificationService.instance.cancelReminder(d.id);
      }
      for (final v in versicherungen) {
        await NotificationService.instance.cancelReminder(v.id);
      }
      for (final w in wartungsTasks) {
        await NotificationService.instance.cancelReminder(w.id);
      }
    } catch (_) {}

    await _db.deletePferd(id); // CASCADE entfernt alle Kind-Datensaetze
    await loadPferde();
  }

  // ---------------- Dienstleister ----------------

  Future<void> saveDienstleister(Dienstleister d, {required bool isNew}) async {
    if (isNew) {
      await _db.insertDienstleister(d);
    } else {
      await _db.updateDienstleister(d);
    }
    await loadDienstleister();
  }

  Future<void> deleteDienstleisterById(String id) async {
    await _db.clearDienstleisterReferences(id);
    await _db.deleteDienstleister(id);
    await loadDienstleister();
  }

  // ---------------- Impfungen ----------------

  Future<List<Impfung>> impfungenFor(String pferdId) => _db.getImpfungenForPferd(pferdId);

  Future<void> saveImpfung(Impfung impfung, String pferdName, {required bool isNew}) async {
    if (isNew) {
      await _db.insertImpfung(impfung);
    } else {
      await _db.updateImpfung(impfung);
    }
    try {
      await NotificationService.instance.cancelReminder(impfung.id);
      await NotificationService.instance.scheduleReminder(
        sourceId: impfung.id,
        title: 'Impfung fällig: $pferdName',
        body: '${impfung.impfstoffTyp.label}-Impfung bei $pferdName ist fällig.',
        scheduledDate: impfung.faelligAm.subtract(Duration(days: impfung.erinnerungTageVorher)),
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteImpfung(String id) async {
    await _db.deleteImpfung(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- Entwurmungen ----------------

  Future<List<Entwurmung>> entwurmungenFor(String pferdId) => _db.getEntwurmungenForPferd(pferdId);

  Future<void> saveEntwurmung(Entwurmung entwurmung, String pferdName, {required bool isNew}) async {
    if (isNew) {
      await _db.insertEntwurmung(entwurmung);
    } else {
      await _db.updateEntwurmung(entwurmung);
    }
    try {
      await NotificationService.instance.cancelReminder(entwurmung.id);
      await NotificationService.instance.scheduleReminder(
        sourceId: entwurmung.id,
        title: 'Entwurmung fällig: $pferdName',
        body: 'Nächste Entwurmung (${entwurmung.methode.label}) bei $pferdName ist fällig.',
        scheduledDate: entwurmung.faelligAm.subtract(Duration(days: entwurmung.erinnerungTageVorher)),
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteEntwurmung(String id) async {
    await _db.deleteEntwurmung(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- Behandlungen (ad-hoc tierärztliche Behandlungen) ----------------

  Future<List<Behandlung>> behandlungenFor(String pferdId) => _db.getBehandlungenForPferd(pferdId);

  Future<void> saveBehandlung(Behandlung behandlung, String pferdName, {required bool isNew}) async {
    if (isNew) {
      await _db.insertBehandlung(behandlung);
    } else {
      await _db.updateBehandlung(behandlung);
    }
    try {
      await NotificationService.instance.cancelReminder(behandlung.id);
      final nachkontrolleAm = behandlung.nachkontrolleAm;
      if (nachkontrolleAm != null) {
        await NotificationService.instance.scheduleReminder(
          sourceId: behandlung.id,
          title: 'Nachkontrolle fällig: $pferdName',
          body: 'Nachkontrolle zu "${behandlung.grund}" bei $pferdName ist fällig.',
          scheduledDate: nachkontrolleAm.subtract(Duration(days: behandlung.erinnerungTageVorher)),
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteBehandlung(String id) async {
    await _db.deleteBehandlung(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- Gesundheitstermine ----------------

  Future<List<Gesundheitstermin>> gesundheitsterminFor(String pferdId) =>
      _db.getGesundheitsterminForPferd(pferdId);

  Future<void> saveGesundheitstermin(
    Gesundheitstermin termin,
    String pferdName, {
    required bool isNew,
  }) async {
    if (isNew) {
      await _db.insertGesundheitstermin(termin);
    } else {
      await _db.updateGesundheitstermin(termin);
    }
    try {
      await NotificationService.instance.cancelReminder(termin.id);
      if (!termin.erledigt) {
        await NotificationService.instance.scheduleReminder(
          sourceId: termin.id,
          title: '${termin.typ.label} fällig: $pferdName',
          body: '${termin.typ.label} bei $pferdName ist fällig.',
          scheduledDate: termin.faelligAm.subtract(Duration(days: termin.erinnerungTageVorher)),
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteGesundheitstermin(String id) async {
    await _db.deleteGesundheitstermin(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- Turnierlizenzen ----------------

  Future<List<Turnierlizenz>> turnierlizenzenFor(String pferdId) =>
      _db.getTurnierlizenzenForPferd(pferdId);

  Future<void> saveTurnierlizenz(
    Turnierlizenz lizenz,
    String pferdName, {
    required bool isNew,
  }) async {
    if (isNew) {
      await _db.insertTurnierlizenz(lizenz);
    } else {
      await _db.updateTurnierlizenz(lizenz);
    }
    try {
      await NotificationService.instance.cancelReminder(lizenz.id);
      await NotificationService.instance.scheduleReminder(
        sourceId: lizenz.id,
        title: 'Turnierlizenz läuft ab: $pferdName',
        body: 'Turnierlizenz ${lizenz.verband.label} für $pferdName läuft ab.',
        scheduledDate: lizenz.gueltigBis.subtract(Duration(days: lizenz.erinnerungTageVorher)),
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteTurnierlizenz(String id) async {
    await _db.deleteTurnierlizenz(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- Turnierstarts (reine Historie, keine Erinnerung) ----------------

  Future<List<Turnierstart>> turnierstartsFor(String pferdId) => _db.getTurnierstartsForPferd(pferdId);

  Future<void> saveTurnierstart(Turnierstart start, {required bool isNew}) async {
    if (isNew) {
      await _db.insertTurnierstart(start);
    } else {
      await _db.updateTurnierstart(start);
    }
    notifyListeners();
  }

  Future<void> deleteTurnierstart(String id) async {
    await _db.deleteTurnierstart(id);
    notifyListeners();
  }

  // ---------------- Decken ----------------

  Future<List<Decke>> deckenFor(String pferdId) => _db.getDeckenForPferd(pferdId);

  Future<void> saveDecke(Decke decke, String pferdName, {required bool isNew}) async {
    if (isNew) {
      await _db.insertDecke(decke);
    } else {
      await _db.updateDecke(decke);
    }
    try {
      await NotificationService.instance.cancelReminder(decke.id);
      final faelligAm = decke.impraegnierungFaelligAm;
      if (faelligAm != null) {
        await NotificationService.instance.scheduleReminder(
          sourceId: decke.id,
          title: 'Imprägnierung fällig: $pferdName',
          body: '${decke.typ.label} von $pferdName sollte neu imprägniert werden.',
          scheduledDate: faelligAm.subtract(Duration(days: decke.erinnerungTageVorher)),
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteDecke(String id) async {
    await _db.deleteDecke(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- Dokumente (keine Erinnerung) ----------------

  Future<List<PferdeDokument>> dokumenteFor(String pferdId) => _db.getDokumenteForPferd(pferdId);

  Future<void> saveDokument(PferdeDokument dokument, {required bool isNew}) async {
    if (isNew) {
      await _db.insertDokument(dokument);
    } else {
      await _db.updateDokument(dokument);
    }
    notifyListeners();
  }

  Future<void> deleteDokument(PferdeDokument dokument) async {
    await _db.deleteDokument(dokument.id);
    try {
      await DocumentStorage.instance.deleteFile(dokument.dateipfad);
    } catch (_) {
      // Fehlende/bereits geloeschte Datei soll den DB-Eintrag nicht blockieren.
    }
    notifyListeners();
  }

  // ---------------- Versicherungen ----------------

  Future<List<PferdeVersicherung>> versicherungenFor(String pferdId) =>
      _db.getVersicherungenForPferd(pferdId);

  Future<void> saveVersicherung(
    PferdeVersicherung versicherung,
    String pferdName, {
    required bool isNew,
  }) async {
    if (isNew) {
      await _db.insertVersicherung(versicherung);
    } else {
      await _db.updateVersicherung(versicherung);
    }
    try {
      await NotificationService.instance.cancelReminder(versicherung.id);
      await NotificationService.instance.scheduleReminder(
        sourceId: versicherung.id,
        title: 'Versicherung fällig: $pferdName',
        body: '${versicherung.art.label} (${versicherung.gesellschaft}) für $pferdName ist fällig.',
        scheduledDate: versicherung.naechsteFaelligkeit.subtract(
          const Duration(days: _versicherungReminderTage),
        ),
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteVersicherung(String id) async {
    await _db.deleteVersicherung(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- Wartungs-Tasks ----------------

  Future<List<WartungsTask>> wartungsTasksFor(String pferdId) => _db.getWartungsTasksForPferd(pferdId);

  Future<void> saveWartungsTask(WartungsTask task, String pferdName, {required bool isNew}) async {
    if (isNew) {
      await _db.insertWartungsTask(task);
    } else {
      await _db.updateWartungsTask(task);
    }
    try {
      await NotificationService.instance.cancelReminder(task.id);
      final faelligAm = task.faelligAm;
      if (faelligAm != null && !task.erledigt) {
        await NotificationService.instance.scheduleReminder(
          sourceId: task.id,
          title: 'Aufgabe fällig: $pferdName',
          body: '${task.titel} bei $pferdName ist fällig.',
          scheduledDate: faelligAm.subtract(Duration(days: task.erinnerungTageVorher)),
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteWartungsTask(String id) async {
    await _db.deleteWartungsTask(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- Anstehende Termine, pferdeuebergreifend ----------------

  /// Fasst alle offenen Faelligkeiten ueber alle nicht archivierten Pferde
  /// zu einer gemeinsamen, nach Faelligkeit sortierten Liste zusammen.
  /// Bei Impfungen/Entwurmungen/Turnierlizenzen (fortlaufende Historie statt
  /// einzelnem "erledigt"-Flag) zaehlt jeweils nur der neueste Eintrag je
  /// Pferd und Unterart - sonst wuerden laengst ueberholte alte Eintraege
  /// weiter als faellig auftauchen.
  Future<List<Reminder>> getUpcomingReminders() async {
    final aktivePferde = _pferde.where((p) => !p.archiviert).toList();
    final pferdeById = {for (final p in aktivePferde) p.id: p};
    final reminders = <Reminder>[];

    final alleImpfungen = (await _db.getAllImpfungen())
        .where((i) => pferdeById.containsKey(i.pferdId))
        .toList();
    for (final i in _neuesteJeSchluessel(alleImpfungen, (i) => '${i.pferdId}::${i.impfstoffTyp.name}',
        (i) => i.geimpftAm)) {
      final pferd = pferdeById[i.pferdId]!;
      reminders.add(Reminder(
        quelleId: i.id,
        pferdId: pferd.id,
        pferdName: pferd.anzeigename,
        typ: ReminderTyp.impfung,
        titel: '${i.impfstoffTyp.label}-Impfung',
        faelligAm: i.faelligAm,
      ));
    }

    final alleEntwurmungen = (await _db.getAllEntwurmungen())
        .where((e) => pferdeById.containsKey(e.pferdId))
        .toList();
    for (final e in _neuesteJeSchluessel(alleEntwurmungen, (e) => e.pferdId, (e) => e.durchgefuehrtAm)) {
      final pferd = pferdeById[e.pferdId]!;
      reminders.add(Reminder(
        quelleId: e.id,
        pferdId: pferd.id,
        pferdName: pferd.anzeigename,
        typ: ReminderTyp.entwurmung,
        titel: 'Entwurmung (${e.methode.label})',
        faelligAm: e.faelligAm,
      ));
    }

    final behandlungenMitNachkontrolle = (await _db.getAllBehandlungenMitNachkontrolle())
        .where((b) => pferdeById.containsKey(b.pferdId) && b.nachkontrolleAm != null);
    for (final b in behandlungenMitNachkontrolle) {
      final pferd = pferdeById[b.pferdId]!;
      reminders.add(Reminder(
        quelleId: b.id,
        pferdId: pferd.id,
        pferdName: pferd.anzeigename,
        typ: ReminderTyp.behandlung,
        titel: 'Nachkontrolle: ${b.grund}',
        faelligAm: b.nachkontrolleAm!,
      ));
    }

    final offeneGesundheitstermine =
        (await _db.getAllOffeneGesundheitstermine()).where((g) => pferdeById.containsKey(g.pferdId));
    for (final g in offeneGesundheitstermine) {
      final pferd = pferdeById[g.pferdId]!;
      reminders.add(Reminder(
        quelleId: g.id,
        pferdId: pferd.id,
        pferdName: pferd.anzeigename,
        typ: ReminderTyp.gesundheitstermin,
        titel: g.typ.label,
        faelligAm: g.faelligAm,
      ));
    }

    final alleLizenzen = (await _db.getAllTurnierlizenzen())
        .where((t) => pferdeById.containsKey(t.pferdId))
        .toList();
    for (final t in _neuesteJeSchluessel(alleLizenzen, (t) => '${t.pferdId}::${t.verband.name}',
        (t) => t.gueltigBis)) {
      final pferd = pferdeById[t.pferdId]!;
      reminders.add(Reminder(
        quelleId: t.id,
        pferdId: pferd.id,
        pferdName: pferd.anzeigename,
        typ: ReminderTyp.turnierlizenz,
        titel: 'Turnierlizenz ${t.verband.label}',
        faelligAm: t.gueltigBis,
      ));
    }

    final alleDecken = (await _db.getAllDecken()).where(
      (d) => pferdeById.containsKey(d.pferdId) && d.impraegnierungFaelligAm != null,
    );
    for (final d in alleDecken) {
      final pferd = pferdeById[d.pferdId]!;
      reminders.add(Reminder(
        quelleId: d.id,
        pferdId: pferd.id,
        pferdName: pferd.anzeigename,
        typ: ReminderTyp.decke,
        titel: 'Imprägnierung ${d.typ.label}',
        faelligAm: d.impraegnierungFaelligAm!,
      ));
    }

    final alleVersicherungen =
        (await _db.getAllVersicherungen()).where((v) => pferdeById.containsKey(v.pferdId));
    for (final v in alleVersicherungen) {
      final pferd = pferdeById[v.pferdId]!;
      reminders.add(Reminder(
        quelleId: v.id,
        pferdId: pferd.id,
        pferdName: pferd.anzeigename,
        typ: ReminderTyp.versicherung,
        titel: '${v.art.label} (${v.gesellschaft})',
        faelligAm: v.naechsteFaelligkeit,
      ));
    }

    final offeneTasks = (await _db.getAllOffeneWartungsTasksMitFaelligkeit())
        .where((t) => pferdeById.containsKey(t.pferdId));
    for (final t in offeneTasks) {
      final pferd = pferdeById[t.pferdId]!;
      reminders.add(Reminder(
        quelleId: t.id,
        pferdId: pferd.id,
        pferdName: pferd.anzeigename,
        typ: ReminderTyp.wartungsTask,
        titel: t.titel,
        faelligAm: t.faelligAm!,
      ));
    }

    reminders.sort((a, b) => a.faelligAm.compareTo(b.faelligAm));
    return reminders;
  }

  /// Behaelt je Gruppierungsschluessel nur das Element mit dem neuesten
  /// Datum - Grundlage fuer "nur der letzte Eintrag zaehlt als aktueller
  /// Status" bei fortlaufenden Historien (Impfungen, Entwurmungen, Lizenzen).
  List<T> _neuesteJeSchluessel<T>(
    List<T> items,
    String Function(T) schluesselVon,
    DateTime Function(T) datumVon,
  ) {
    final neueste = <String, T>{};
    for (final item in items) {
      final schluessel = schluesselVon(item);
      final bestehender = neueste[schluessel];
      if (bestehender == null || datumVon(item).isAfter(datumVon(bestehender))) {
        neueste[schluessel] = item;
      }
    }
    return neueste.values.toList();
  }
}
