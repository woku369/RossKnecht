enum Geschlecht { stute, wallach, hengst }

extension GeschlechtX on Geschlecht {
  String get label {
    switch (this) {
      case Geschlecht.stute:
        return 'Stute';
      case Geschlecht.wallach:
        return 'Wallach';
      case Geschlecht.hengst:
        return 'Hengst';
    }
  }
}

class Pferd {
  final String id;
  String name;
  String? eingetragenerName;
  String? rasse;
  Geschlecht geschlecht;
  int? geburtsjahr;
  String? farbe;
  String? abzeichen;
  String? lebensnummer;
  String? chipnummer;
  String? besitzer;
  String? stallplatz;
  String? externerStallname;
  String? externerKontakt;
  DateTime? ankunftsdatum;
  String? fotoPfad;
  String? notizen;
  bool archiviert;
  String? archiviertGrund;
  DateTime? archiviertAm;
  DateTime createdAt;
  DateTime updatedAt;

  Pferd({
    required this.id,
    required this.name,
    this.eingetragenerName,
    this.rasse,
    this.geschlecht = Geschlecht.wallach,
    this.geburtsjahr,
    this.farbe,
    this.abzeichen,
    this.lebensnummer,
    this.chipnummer,
    this.besitzer,
    this.stallplatz,
    this.externerStallname,
    this.externerKontakt,
    this.ankunftsdatum,
    this.fotoPfad,
    this.notizen,
    this.archiviert = false,
    this.archiviertGrund,
    this.archiviertAm,
    required this.createdAt,
    required this.updatedAt,
  });

  String get anzeigename => name;

  int? get alterJahre {
    if (geburtsjahr == null) return null;
    return DateTime.now().year - geburtsjahr!;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'eingetragener_name': eingetragenerName,
      'rasse': rasse,
      'geschlecht': geschlecht.name,
      'geburtsjahr': geburtsjahr,
      'farbe': farbe,
      'abzeichen': abzeichen,
      'lebensnummer': lebensnummer,
      'chipnummer': chipnummer,
      'besitzer': besitzer,
      'stallplatz': stallplatz,
      'externer_stallname': externerStallname,
      'externer_kontakt': externerKontakt,
      'ankunftsdatum': ankunftsdatum?.toIso8601String(),
      'foto_pfad': fotoPfad,
      'notizen': notizen,
      'archiviert': archiviert ? 1 : 0,
      'archiviert_grund': archiviertGrund,
      'archiviert_am': archiviertAm?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Pferd.fromMap(Map<String, Object?> map) {
    return Pferd(
      id: map['id'] as String,
      name: map['name'] as String,
      eingetragenerName: map['eingetragener_name'] as String?,
      rasse: map['rasse'] as String?,
      geschlecht: Geschlecht.values.firstWhere(
        (g) => g.name == map['geschlecht'],
        orElse: () => Geschlecht.wallach,
      ),
      geburtsjahr: map['geburtsjahr'] as int?,
      farbe: map['farbe'] as String?,
      abzeichen: map['abzeichen'] as String?,
      lebensnummer: map['lebensnummer'] as String?,
      chipnummer: map['chipnummer'] as String?,
      besitzer: map['besitzer'] as String?,
      stallplatz: map['stallplatz'] as String?,
      externerStallname: map['externer_stallname'] as String?,
      externerKontakt: map['externer_kontakt'] as String?,
      ankunftsdatum: map['ankunftsdatum'] != null
          ? DateTime.parse(map['ankunftsdatum'] as String)
          : null,
      fotoPfad: map['foto_pfad'] as String?,
      notizen: map['notizen'] as String?,
      archiviert: (map['archiviert'] as int? ?? 0) == 1,
      archiviertGrund: map['archiviert_grund'] as String?,
      archiviertAm: map['archiviert_am'] != null
          ? DateTime.parse(map['archiviert_am'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
