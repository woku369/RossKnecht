enum GesundheitsterminTyp { hufschmied, zahnarzt, tieraerztlicheKontrolle, sonstiges }

extension GesundheitsterminTypX on GesundheitsterminTyp {
  String get label {
    switch (this) {
      case GesundheitsterminTyp.hufschmied:
        return 'Hufschmied / Hufpflege';
      case GesundheitsterminTyp.zahnarzt:
        return 'Zahnarzt';
      case GesundheitsterminTyp.tieraerztlicheKontrolle:
        return 'Tierärztliche Kontrolle';
      case GesundheitsterminTyp.sonstiges:
        return 'Sonstiger Termin';
    }
  }
}

class Gesundheitstermin {
  final String id;
  final String pferdId;
  GesundheitsterminTyp typ;
  DateTime faelligAm;
  DateTime? letzteDurchfuehrungAm;
  int erinnerungTageVorher;
  bool erledigt;
  String? dienstleisterId;
  String? notizen;

  Gesundheitstermin({
    required this.id,
    required this.pferdId,
    required this.typ,
    required this.faelligAm,
    this.letzteDurchfuehrungAm,
    this.erinnerungTageVorher = 7,
    this.erledigt = false,
    this.dienstleisterId,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'typ': typ.name,
      'faellig_am': faelligAm.toIso8601String(),
      'letzte_durchfuehrung_am': letzteDurchfuehrungAm?.toIso8601String(),
      'erinnerung_tage_vorher': erinnerungTageVorher,
      'erledigt': erledigt ? 1 : 0,
      'dienstleister_id': dienstleisterId,
      'notizen': notizen,
    };
  }

  factory Gesundheitstermin.fromMap(Map<String, Object?> map) {
    return Gesundheitstermin(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      typ: GesundheitsterminTyp.values.firstWhere(
        (t) => t.name == map['typ'],
        orElse: () => GesundheitsterminTyp.sonstiges,
      ),
      faelligAm: DateTime.parse(map['faellig_am'] as String),
      letzteDurchfuehrungAm: map['letzte_durchfuehrung_am'] != null
          ? DateTime.parse(map['letzte_durchfuehrung_am'] as String)
          : null,
      erinnerungTageVorher: map['erinnerung_tage_vorher'] as int? ?? 7,
      erledigt: (map['erledigt'] as int? ?? 0) == 1,
      dienstleisterId: map['dienstleister_id'] as String?,
      notizen: map['notizen'] as String?,
    );
  }
}
