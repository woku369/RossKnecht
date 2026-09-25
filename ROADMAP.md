# Roadmap – RossKnecht

## Erledigt (v1.0)
- [x] Pferdeverwaltung (Name, Rasse, Geschlecht, Geburtsjahr, Farbe, Abzeichen, Lebensnummer, Chipnummer, Besitzer, Stallplatz, Ankunftsdatum, Foto)
- [x] Impfungen (Influenza, Tetanus, Herpes, Tollwut, Sonstige) mit Chargennummer, Fälligkeit und lokaler Erinnerung
- [x] Entwurmung (Wurmkur oder Kotprobe) mit Präparat/Ergebnis, Fälligkeit und Erinnerung
- [x] Tierärztliche Behandlungen (ad-hoc, z. B. Kolik/Verletzung) mit Grund, Behandlung, Kosten und optionaler Nachkontroll-Erinnerung
- [x] Gesundheitstermine (Hufschmied/Hufpflege, Zahnarzt, tierärztliche Kontrolle, Sonstiges) mit Erledigt-Status
- [x] Turnierlizenzen (FN/FEI/Landesverband) mit Ablauf-Erinnerung
- [x] Turnierstarts als einfache Ergebnishistorie
- [x] Deckenmanagement (Typ, Füllung, Größe, Zustand, in Gebrauch, optionale Imprägnierungs-Erinnerung)
- [x] Dokumenten-Galerie je Pferd (Foto/Kamera oder Galerie, kategorisiert)
- [x] Versicherungen (Art, Gesellschaft, Polizzennummer, Zahlungsintervall, korrekte Fälligkeitsberechnung)
- [x] Dienstleister-Verwaltung (Tierarzt, Hufschmied, Sattler), Zuordnung zu Impfungen/Gesundheitsterminen
- [x] Wartungs-To-Dos je Pferd, unabhängig von den übrigen Terminarten
- [x] Pferdeübergreifende Termine-Übersicht, farblich nach Dringlichkeit
- [x] Historie-Export (Text) und Pferdeblatt-Export (PDF, DIN A4) je Pferd, teilbar
- [x] Pferde-Archivierung (verkauft/verstorben) mit Grund und Datum, archivierte Pferde ohne Erinnerungen
- [x] Manuelles Backup/Restore über Google Drive (Voll-Snapshot, `drive.file`-Scope)
- [x] Lokales ZIP-Backup (Export/Import ohne Google-Konto) inkl. Import per Android-Teilen-Dialog
- [x] Automatische Build-Versionierung (versionCode = GitHub-Actions-Lauf-Nummer) gegen Paketkonflikte bei der Installation
- [x] Fester, dauerhafter APK-Signatur-Keystore, direkt im App-Modul referenziert
- [x] `android/`-Ordner fest im Repo, Flutter-Version im CI fest gepinnt

## Offen
- [ ] `flutter pub get` / `flutter analyze` / echten Build einmal lokal oder in einer Umgebung mit Flutter-SDK durchführen (hier nicht möglich, siehe README "Bekannte Einschränkungen")
- [ ] Google-Cloud-Projekt + OAuth-Client gemäß README einrichten und Login/Upload/Restore einmal real durchtesten
- [ ] App-Icon gestalten (aktuell Standard-Flutter-Icon)
- [ ] Kostenübersicht/Finanztracker über alle Kostenstellen hinweg (Behandlungen haben bereits ein Kostenfeld; Hufschmied-, Zahnarzt-, Versicherungskosten aktuell nicht gemeinsam ausgewertet) – Anstoß: Vergleich mit EquiCares "Finance Tracker"
- [ ] Gewichts-/Gesundheits-Tracking über die Zeit (z. B. Body Condition Score, Gewicht) – aktuell nicht abgebildet
- [ ] Play-Store-Vorbereitung (Signing-Key, Versionierung) falls gewünscht
- [ ] Verknüpfung mit `Rationsrechner` prüfen (gemeinsame Pferdestammdaten? aktuell zwei getrennte Apps/Datenbanken)
- [ ] Teamzugriff (siehe Konzept-Skizze unten) – Entscheidung noch offen, ob/wann umgesetzt

## Konzept-Skizze: Teamzugriff (noch nicht umgesetzt, nur skizziert)

Anstoß: EquiCare bietet "Shared Access" (Stallpersonal/Einsteller können mitpflegen,
Profil-Transfer bei Verkauf). RossKnecht ist aktuell bewusst Single-User/lokale
SQLite-DB pro Gerät – für "mehrere Personen pflegen dieselben Pferde mit"
reicht der bestehende manuelle Drive-Snapshot nicht (kein Realtime-Sync, "letzter
Upload gewinnt" überschreibt gleichzeitige Änderungen anderer).

**Rollenmodell (Vorschlag):**
- **Besitzer**: voller Zugriff, verwaltet Team-Mitglieder, kann Pferde archivieren/löschen
- **Stallpersonal/Mitarbeiter**: Lese-/Schreibzugriff auf Termine, Behandlungen, Wartungs-To-Dos; keine Rechte zum Löschen von Pferden oder Team-Verwaltung
- **Beobachter** (z. B. externer Tierarzt, Beritt): nur lesend, z. B. für Gesundheitshistorie

**Technischer Ansatz (Vorschlag, keine finale Festlegung):**
Migration der Datenhaltung von reinem lokalem SQLite zu **Cloud Firestore +
Firebase Authentication**, statt einer selbstgebauten Merge-Sync-Logik:
- `google_sign_in` ist bereits Abhängigkeit (App-Login) – direkt für Firebase Auth wiederverwendbar
- Firestore bringt Offline-Persistenz und Realtime-Sync bereits mit (kein eigener Konfliktlösungs-Code für "wer hat zuletzt geschrieben" nötig)
- Datenmodell bleibt strukturell erhalten (Collections statt SQLite-Tabellen), `pferde`-Dokumente bekommen zusätzlich ein `team_id`-Feld
- Einladung neuer Team-Mitglieder über einen zeitlich begrenzten Einladungscode (Firestore-Dokument mit Ablaufzeit), Beitritt per Google-Konto
- Bestehende lokale SQLite-Daten werden beim ersten Team-Setup einmalig hochgeladen (ähnlich dem bestehenden Drive-Backup-Export, nur strukturiert statt als ZIP-Blob)
- Fotos/Dokumente müssten auf Firebase Storage umziehen (aktuell lokaler App-Ordner) – Kostenfaktor bei vielen Bildern beachten
- Provider-Schicht (`PferdeProvider`) bliebe stabil, nur `DatabaseHelper` würde durch/neben ein Firestore-Repository ersetzt – Screens brauchen dadurch keine grundlegende Überarbeitung
- Für 6 Pferde und wenige Nutzer reicht der kostenlose Firebase-Spark-Plan voraussichtlich dauerhaft aus [Einschätzung, nicht mit aktuellen Firebase-Preisen/Limits gegengeprüft]

**Offene Fragen vor einer Umsetzungsentscheidung:**
- Berechtigungsgranularität: pro Stall (alle Pferde) oder pro einzelnem Pferd?
- Reicht Google-Sign-In als einziger Auth-Weg, oder braucht es auch E-Mail-Einladung ohne Google-Konto?
- Lohnt sich der Migrationsaufwand angesichts der Nutzungsgröße (6 Pferde), oder ist ein einfacherer Zwischenschritt (z. B. gemeinsam genutzte Drive-Datei mit Konflikt-Warnung statt echtem Merge) ausreichend?

**Damit ersetzt/relativiert dieser Punkt** die bisherige Einschätzung unter
"Bewusst nicht geplant" unten, die sich nur auf Sync **desselben** Nutzers über
mehrere eigene Geräte bezog – Teamzugriff mit mehreren **unterschiedlichen**
Nutzern ist ein eigenständiges Thema und wird hier separat offengehalten.

## Bewusst nicht geplant
- **Echter Merge-Sync für denselben Nutzer über mehrere eigene Geräte** (nicht zu verwechseln mit Teamzugriff oben): RossKnecht wird für 6 Pferde unregelmäßig genutzt (Termine erfassen, kein Live-Tracking), das rechtfertigt für diesen Fall den Aufwand einer feineren Sync-Logik nicht. Der manuelle Google-Drive-Snapshot reicht dafür weiterhin aus.
- **Rationsplanung/Fütterungsberechnung**: Dafür existiert bereits die eigenständige App `Rationsrechner` – RossKnecht dupliziert diese Funktionalität bewusst nicht, sondern konzentriert sich auf Gesundheits- und Verwaltungstermine.
- **Direkter Schreibzugriff auf den öffentlichen Downloads-Ordner**: Seit Android 10 (Scoped Storage) benötigt das ein eigenes Datei-Dialog-Plugin mit bekannten Build-Konflikten (siehe `FuhrparkMeister`-README). Export bleibt im App-eigenen Ordner + Android-Systemfreigabe.
- **iOS-Version**: nicht Ziel dieser App, analog zu den anderen Meister-Apps im Portfolio.
