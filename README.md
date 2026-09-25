# RossKnecht

Pferdemanagement für **Impfungen, Entwurmung, Hufschmied/Zahnarzt, Turnierlizenzen und Deckenmanagement** – als Android-App (Flutter), analog zum Schwester-Repo `FuhrparkMeister`.

---

## Projektstruktur

```
├── app/          # Flutter-App (Android)
│   └── lib/
│       ├── models/      # Pferd, Impfung, Entwurmung, Gesundheitstermin, Turnierlizenz,
│       │                # Turnierstart, Decke, PferdeDokument, PferdeVersicherung,
│       │                # WartungsTask, Dienstleister, Reminder
│       ├── database/    # SQLite-Zugriff (sqflite)
│       ├── providers/   # PferdeProvider (State, CRUD, Erinnerungen)
│       ├── services/    # NotificationService, DriveSyncService, LocalBackupService,
│       │                # DocumentStorage, HistoryExportService, PferdeblattExportService
│       ├── screens/     # Home, Pferd-Formular, Pferd-Detail (Tabs), Termine, Dienstleister
│       └── widgets/     # gemeinsame UI-Bausteine
└── ROADMAP.md
```

---

## Features

- **Pferdeverwaltung**: Rufname und optional eingetragener (Papier-)Name, Rasse, Geschlecht, Geburtsjahr, Farbe (Freitext mit Vorschlägen in deutscher und amerikanischer/AQHA-Nomenklatur, z. B. Buckskin, Grullo, Dun – relevant u. a. für Quarter Horses), Abzeichen, Lebensnummer (UELN), Chipnummer, Besitzer, eigener Stallplatz **oder** Name/Kontakt eines auswärtigen Stalls (Pension/Beritt), Ankunftsdatum, Foto
- **Impfungen**: Influenza, Tetanus, Herpes, Tollwut, Sonstige – jeweils mit Chargennummer (Equidenpass-Dokumentationspflicht), Fälligkeit und lokaler Erinnerung X Tage vorher; Verlauf pro Impfstoff bleibt als Historie erhalten, nur der jeweils neueste Eintrag zählt für die Erinnerung
- **Entwurmung**: klassische Wurmkur oder Kotprobe (selektive Entwurmung) mit Präparat/Wirkstoff bzw. Ergebnis, Fälligkeit und Erinnerung
- **Tierärztliche Behandlungen**: ad-hoc erfasste Behandlungsfälle (z. B. Kolik, Verletzung, akute Erkrankung) mit Grund/Diagnose, durchgeführter Behandlung, Tierarzt, Kosten und optionaler Nachkontroll-Erinnerung – als Historie, unabhängig von wiederkehrenden Terminen
- **Gesundheitstermine**: Hufschmied/Hufpflege, Zahnarzt, tierärztliche Kontrolle, Sonstiges – mit Fälligkeit, Erinnerung und Erledigt-Status
- **Turnierlizenzen**: FN/FEI/Landesverband, Lizenznummer, Gültigkeitszeitraum mit Ablauf-Erinnerung
- **Turnierstarts**: einfache Ergebnishistorie (Datum, Ort, Disziplin, Platzierung)
- **Deckenmanagement**: Weide-, Winter-, Stall-, Regen-, Abschwitz-, Flieger- und Kombidecken je Pferd mit Füllung (Gramm), Größe, Zustand, "aktuell in Gebrauch"-Kennzeichnung und optionaler Imprägnierungs-Erinnerung
- **Dokumenten-Galerie**: Fotos von Equidenpass, Impfausweis, Kaufvertrag, Versicherungspolizze, Röntgenbildern etc. je Pferd, kategorisiert, lokal gespeichert
- **Versicherungen**: Haftpflicht, OP-, Lebens- und Krankenversicherung mit Zahlungsintervall und korrekter Fälligkeitsberechnung (Hauptfälligkeit ≠ nächster Zahlungstermin, wird anhand des Intervalls vorgerückt)
- **Dienstleister-Verwaltung**: Tierärzte, Hufschmiede, Sattler – Zuordnung zu Impfungen und Gesundheitsterminen
- **Wartungs-To-Dos**: freie Checkliste je Pferd, unabhängig von den übrigen Terminarten
- **Termine-Übersicht**: alle offenen Fälligkeiten pferdeübergreifend, farblich nach Dringlichkeit sortiert
- **Historie- und PDF-Export**: Gesundheitshistorie als Text sowie ein vollständiges Pferdedatenblatt als A4-PDF, beide teilbar (z. B. für die Stallmappe oder beim Verkauf)
- **Pferde-Archivierung** (verkauft/verstorben): Pferd wird aus der aktiven Liste ausgeblendet, Daten/Historie bleiben erhalten und sind über "Archivierte Pferde" weiterhin einsehbar; archivierte Pferde erzeugen keine Erinnerungen mehr
- **Eigenes Branding**: Stallname und Logo (über Einstellungen-Symbol im Home-Screen) ersetzen dort den Standardtitel "RossKnecht"
- **Offline-fähig**: lokale SQLite-Datenbank als primärer Datenspeicher
- **Lokales ZIP-Backup**: Export/Import ohne jede Einrichtung – Export legt die Datei im App-eigenen Ordner ab und öffnet zusätzlich die Android-Systemfreigabe, Import liest die neueste ZIP-Datei aus diesem Ordner ein oder wird per Android-Teilen-Dialog ("Öffnen mit RossKnecht") direkt angenommen
- **Backup & Geräte-Sync über Google Drive**: manueller Voll-Snapshot (Datenbank + Dokumentenfotos) in einen eigenen Drive-Ordner hoch- und herunterladen, für Nutzung auf mehreren Geräten

---

## App einrichten (Flutter)

### Voraussetzungen
- Flutter SDK ≥ 3.22
- Android Studio oder VS Code mit Flutter-Extension

### Erstmaliges Setup

Dieses Repo enthält den kompletten Dart-Quellcode (`app/lib/`) und die `pubspec.yaml` sowie den `android/`-Ordner. Da in der Cloud-Session, die diesen Code erzeugt hat, kein Flutter-SDK installiert war, wurde nichts davon gebaut/getestet. Vor dem ersten Build:

```bash
cd app
flutter pub get
flutter analyze
```

Prüfen, dass in `android/app/src/main/AndroidManifest.xml` folgende Berechtigungen vorhanden sind (werden von den Plugins meist automatisch per Manifest-Merge ergänzt):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

`flutter_local_notifications` verlangt **Core Library Desugaring** (bereits in `android/app/build.gradle.kts` konfiguriert) – ohne das bricht `flutter build apk` mit `Execution failed for task ':app:checkReleaseAarMetadata'` ab.

### Starten / Bauen

```bash
flutter run                    # auf angeschlossenem Android-Gerät
flutter build apk --release    # installierbare APK
```

Die fertige APK liegt danach unter `app/build/app/outputs/flutter-apk/app-release.apk`.

**Build-Nummer (versionCode):** Die CI-Pipeline setzt bei jedem Build automatisch `--build-number=<GitHub-Actions-Lauf-Nummer>`, damit jede veröffentlichte APK einen garantiert höheren `versionCode` als die vorherige hat. Baust du lokal eine APK, die eine über CI installierte App ersetzen soll, ebenfalls eine höhere Nummer mitgeben:

```bash
flutter build apk --release --build-name=1.0.0 --build-number=999
```

**Update-Fähigkeit / Signierschlüssel:** Damit eine neu gebaute APK die alte auf dem Handy als Update ersetzt, müssen beide mit demselben Debug-Key signiert sein. Im Repo liegt dafür ein fester, dauerhafter Debug-Keystore unter `ci/debug.keystore` (Standard-Passwörter `android`/`androiddebugkey`, wie Androids eigener Debug-Keystore). Die CI-Pipeline nutzt ihn automatisch. Für lokale Builds, die mit den CI-Builds austauschbar bleiben sollen, einmalig:

```bash
mkdir -p ~/.android
cp ../ci/debug.keystore ~/.android/debug.keystore   # aus app/ heraus; Windows: %USERPROFILE%\.android\debug.keystore
```

### Alternative: APK ohne eigenen PC/Flutter-Installation bauen (z. B. vom Handy aus)

Ein GitHub-Actions-Workflow (`.github/workflows/build-apk.yml`) baut die APK bei jedem Push auf diesen Branch automatisch in der Cloud:

1. Auf GitHub im Tab **Actions** den Workflow „APK bauen" öffnen und **Run workflow** antippen (geht auch über die GitHub-App oder den mobilen Browser, ganz ohne PC)
2. Nach ca. 3–5 Minuten ist der Build fertig
3. Die APK liegt danach direkt zum Download unter **Releases → „RossKnecht – aktueller Build"** (Tag `latest-apk`) – auf dem Handy antippen, herunterladen, „Installation aus unbekannten Quellen" erlauben, installieren
4. Alternativ liegt die APK auch als Artefakt am jeweiligen Actions-Lauf (verfällt nach 90 Tagen, braucht GitHub-Login und muss entzippt werden – der Release-Download unter Punkt 3 ist der einfachere Weg)

---

## Cloud-Sync einrichten (Google Drive)

Die App nutzt die Google-Drive-API mit dem eingeschränkten Scope `drive.file` –
sie sieht dadurch **nur** die Dateien, die sie selbst in einem eigenen
`RossKnecht`-Ordner in deinem Drive anlegt, nichts anderes im Google-Konto.
Dafür muss einmalig ein eigenes Google-Cloud-Projekt eingerichtet werden
(kann Claude nicht für dich erledigen, da es dein persönliches Google-Konto
betrifft):

1. **Google-Cloud-Projekt anlegen** unter [console.cloud.google.com](https://console.cloud.google.com)
2. **Drive API aktivieren**: *APIs & Dienste → Bibliothek* → „Google Drive API" suchen → aktivieren
3. **OAuth-Zustimmungsbildschirm konfigurieren**: *APIs & Dienste → OAuth consent screen* → „Extern" → App-Name, Support-E-Mail eintragen, dich selbst als **Testnutzer** hinzufügen
4. **SHA-1-Fingerabdruck ermitteln**:
   ```bash
   cd app/android && ./gradlew signingReport
   ```
   (Abschnitt „Variant: debug" → SHA-1 kopieren; für die spätere Release-APK denselben Schritt mit dem Release-Keystore wiederholen)
5. **OAuth-Client-ID erstellen**: *APIs & Dienste → Anmeldedaten → Anmeldedaten erstellen → OAuth-Client-ID* → Typ „Android" → Package-Name (`at.kraeutermeister.rossknecht`) + SHA-1 eintragen

### Wichtiger Hinweis zum Testmodus
[Vermutung/Hinweis, Stand der Recherche September 2026, bitte in der aktuellen Google-Cloud-Console gegenprüfen]: Solange der OAuth-Zustimmungsbildschirm auf **„Testing"** steht, laufen ausgestellte Tokens nach **7 Tagen** ab – du müsstest dich dann in der App neu anmelden. Um das zu vermeiden, den Zustimmungsbildschirm auf **„In Produktion"** stellen; bei einem reinen Privat-Tool mit dem eingeschränkten `drive.file`-Scope ist dafür nach bisherigem Kenntnisstand keine Google-Verifizierung nötig, es kann aber weiterhin eine „Unverifizierte App"-Warnung erscheinen, die man beim Login manuell bestätigt.

### Nutzung in der App
*Backup & Cloud-Sync* (Wolken-Symbol oben rechts im Home-Screen) → „Anmelden" → **Backup jetzt hochladen** bzw. **Backup wiederherstellen**. Es ist ein vollständiger Schnappschuss ohne automatischen Merge: vor dem Gerätewechsel hochladen, auf dem Zielgerät herunterladen.

---

## Datenmodell (Kurzüberblick)

| Tabelle | Zweck |
|---|---|
| `pferde` | Stammdaten je Pferd |
| `impfungen` | Impfhistorie je Pferd und Impfstoff, mit Chargennummer und Fälligkeit |
| `entwurmungen` | Wurmkur-/Kotprobenhistorie je Pferd |
| `behandlungen` | Ad-hoc tierärztliche Behandlungen (Grund, Behandlung, Kosten, optionale Nachkontrolle) |
| `gesundheitstermine` | Hufschmied/Zahnarzt/tierärztliche Kontrolle/Sonstiges, mit Erledigt-Status |
| `turnierlizenzen` | Turnierlizenzen je Verband und Gültigkeitszeitraum |
| `turnierstarts` | Ergebnishistorie einzelner Turnierstarts |
| `decken` | Deckeninventar je Pferd (Typ, Füllung, Größe, in Gebrauch, Zustand) |
| `dokumente` | Foto-Galerie je Pferd (Pfad auf lokalem Dateisystem) |
| `versicherungen` | Versicherungspolizzen je Pferd |
| `wartungs_tasks` | Freie To-Dos je Pferd, ohne Fälligkeitsdatum optional |
| `dienstleister` | Tierärzte, Hufschmiede, Sattler – eigenständig, nullbar referenziert von Impfungen/Gesundheitsterminen |

Alle Kind-Tabellen (außer `dienstleister`) hängen per `ON DELETE CASCADE` an `pferde` – Pferd löschen entfernt automatisch alle zugehörigen Daten. `dienstleister`-Referenzen werden beim Löschen eines Dienstleisters stattdessen auf `null` gesetzt (`ON DELETE SET NULL`), damit die Behandlungshistorie erhalten bleibt.

---

## Bekannte Einschränkungen

- **Nicht in dieser Umgebung gebaut/getestet**: In der Cloud-Session, die diesen Code erzeugt hat, war kein Flutter-SDK verfügbar. Der Dart-Code wurde sorgfältig nach Konventionen des Schwester-Repos `FuhrparkMeister` geschrieben, aber weder `flutter pub get` noch `flutter analyze` noch ein echter Build konnten hier ausgeführt werden. Vor dem ersten Release-Build lokal `flutter analyze` laufen lassen.
- **Zeitzone für Erinnerungen** ist fest auf `Europe/Vienna` codiert.
- **Cloud-Sync ist manuell, kein Merge**: Der Google-Drive-Sync überschreibt beim Hochladen/Herunterladen jeweils den kompletten Gegenstand ("letzter Stand gewinnt"). Werden auf zwei Geräten parallel Änderungen gemacht, ohne dazwischen zu synchronisieren, gehen die zuletzt nicht hochgeladenen Änderungen beim nächsten Download verloren.
- **App-Icon**: aktuell Standard-Flutter-Icon, noch nicht gestaltet.
- **iOS**: nicht Ziel dieser App (analog zu den anderen Meister-Apps im Portfolio).
