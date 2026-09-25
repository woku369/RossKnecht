enum DeckenTyp {
  weidedecke,
  stalldecke,
  regendecke,
  abschwitzdecke,
  fliegendecke,
  kombidecke,
  sonstige,
}

extension DeckenTypX on DeckenTyp {
  String get label {
    switch (this) {
      case DeckenTyp.weidedecke:
        return 'Weidedecke';
      case DeckenTyp.stalldecke:
        return 'Stalldecke';
      case DeckenTyp.regendecke:
        return 'Regendecke';
      case DeckenTyp.abschwitzdecke:
        return 'Abschwitzdecke';
      case DeckenTyp.fliegendecke:
        return 'Fliegendecke';
      case DeckenTyp.kombidecke:
        return 'Kombidecke (Weide/Stall)';
      case DeckenTyp.sonstige:
        return 'Sonstige Decke';
    }
  }
}

enum DeckenZustand { neu, gut, reparaturbeduerftig, ausrangiert }

extension DeckenZustandX on DeckenZustand {
  String get label {
    switch (this) {
      case DeckenZustand.neu:
        return 'Neu';
      case DeckenZustand.gut:
        return 'Gut';
      case DeckenZustand.reparaturbeduerftig:
        return 'Reparaturbedürftig';
      case DeckenZustand.ausrangiert:
        return 'Ausrangiert';
    }
  }
}

class Decke {
  final String id;
  final String pferdId;
  DeckenTyp typ;
  int? fuellungGramm;
  int? groesseCm;
  bool inGebrauch;
  DeckenZustand zustand;
  DateTime? gewaschenAm;
  DateTime? impraegnierungFaelligAm;
  int erinnerungTageVorher;
  String? notizen;

  Decke({
    required this.id,
    required this.pferdId,
    required this.typ,
    this.fuellungGramm,
    this.groesseCm,
    this.inGebrauch = false,
    this.zustand = DeckenZustand.gut,
    this.gewaschenAm,
    this.impraegnierungFaelligAm,
    this.erinnerungTageVorher = 14,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'typ': typ.name,
      'fuellung_gramm': fuellungGramm,
      'groesse_cm': groesseCm,
      'in_gebrauch': inGebrauch ? 1 : 0,
      'zustand': zustand.name,
      'gewaschen_am': gewaschenAm?.toIso8601String(),
      'impraegnierung_faellig_am': impraegnierungFaelligAm?.toIso8601String(),
      'erinnerung_tage_vorher': erinnerungTageVorher,
      'notizen': notizen,
    };
  }

  factory Decke.fromMap(Map<String, Object?> map) {
    return Decke(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      typ: DeckenTyp.values.firstWhere(
        (t) => t.name == map['typ'],
        orElse: () => DeckenTyp.sonstige,
      ),
      fuellungGramm: map['fuellung_gramm'] as int?,
      groesseCm: map['groesse_cm'] as int?,
      inGebrauch: (map['in_gebrauch'] as int? ?? 0) == 1,
      zustand: DeckenZustand.values.firstWhere(
        (z) => z.name == map['zustand'],
        orElse: () => DeckenZustand.gut,
      ),
      gewaschenAm: map['gewaschen_am'] != null
          ? DateTime.parse(map['gewaschen_am'] as String)
          : null,
      impraegnierungFaelligAm: map['impraegnierung_faellig_am'] != null
          ? DateTime.parse(map['impraegnierung_faellig_am'] as String)
          : null,
      erinnerungTageVorher: map['erinnerung_tage_vorher'] as int? ?? 14,
      notizen: map['notizen'] as String?,
    );
  }
}
