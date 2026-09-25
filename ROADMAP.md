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
- [ ] Kostenübersicht (Tierarzt-/Hufschmiedrechnungen) – Wartungs-To-Dos haben aktuell kein Kostenfeld
- [ ] Gewichts-/Gesundheits-Tracking über die Zeit (z. B. Body Condition Score, Gewicht) – aktuell nicht abgebildet
- [ ] Play-Store-Vorbereitung (Signing-Key, Versionierung) falls gewünscht
- [ ] Verknüpfung mit `Rationsrechner` prüfen (gemeinsame Pferdestammdaten? aktuell zwei getrennte Apps/Datenbanken)

## Bewusst nicht geplant
- **Echter Merge-Sync / NAS-Backend**: RossKnecht wird für 6 Pferde unregelmäßig genutzt (Termine erfassen, kein Live-Tracking), das rechtfertigt den Aufwand einer feineren Sync-Logik nicht. Der manuelle Google-Drive-Snapshot reicht für dieses Nutzungsprofil dauerhaft, nicht nur als Übergangslösung.
- **Rationsplanung/Fütterungsberechnung**: Dafür existiert bereits die eigenständige App `Rationsrechner` – RossKnecht dupliziert diese Funktionalität bewusst nicht, sondern konzentriert sich auf Gesundheits- und Verwaltungstermine.
- **Direkter Schreibzugriff auf den öffentlichen Downloads-Ordner**: Seit Android 10 (Scoped Storage) benötigt das ein eigenes Datei-Dialog-Plugin mit bekannten Build-Konflikten (siehe `FuhrparkMeister`-README). Export bleibt im App-eigenen Ordner + Android-Systemfreigabe.
- **iOS-Version**: nicht Ziel dieser App, analog zu den anderen Meister-Apps im Portfolio.
