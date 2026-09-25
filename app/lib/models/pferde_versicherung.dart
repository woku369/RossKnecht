enum VersicherungsArt { haftpflicht, opVersicherung, lebensversicherung, krankenversicherung }

extension VersicherungsArtX on VersicherungsArt {
  String get label {
    switch (this) {
      case VersicherungsArt.haftpflicht:
        return 'Tierhalterhaftpflicht';
      case VersicherungsArt.opVersicherung:
        return 'OP-Versicherung';
      case VersicherungsArt.lebensversicherung:
        return 'Pferdelebensversicherung';
      case VersicherungsArt.krankenversicherung:
        return 'Krankenversicherung';
    }
  }
}

enum Zahlungsintervall { jaehrlich, halbjaehrlich, vierteljaehrlich, monatlich }

extension ZahlungsintervallX on Zahlungsintervall {
  String get label {
    switch (this) {
      case Zahlungsintervall.jaehrlich:
        return 'Jährlich';
      case Zahlungsintervall.halbjaehrlich:
        return 'Halbjährlich';
      case Zahlungsintervall.vierteljaehrlich:
        return 'Vierteljährlich';
      case Zahlungsintervall.monatlich:
        return 'Monatlich';
    }
  }

  int get monate {
    switch (this) {
      case Zahlungsintervall.jaehrlich:
        return 12;
      case Zahlungsintervall.halbjaehrlich:
        return 6;
      case Zahlungsintervall.vierteljaehrlich:
        return 3;
      case Zahlungsintervall.monatlich:
        return 1;
    }
  }
}

class PferdeVersicherung {
  final String id;
  final String pferdId;
  String gesellschaft;
  String polizzennummer;
  VersicherungsArt art;
  DateTime? gueltigAb;
  DateTime faelligkeitJaehrlichAm;
  Zahlungsintervall zahlungsintervall;
  double? praemieEuro;
  String? notizen;

  PferdeVersicherung({
    required this.id,
    required this.pferdId,
    required this.gesellschaft,
    required this.polizzennummer,
    required this.art,
    this.gueltigAb,
    required this.faelligkeitJaehrlichAm,
    this.zahlungsintervall = Zahlungsintervall.jaehrlich,
    this.praemieEuro,
    this.notizen,
  });

  /// Naechster tatsaechlicher Zahlungstermin, ausgehend von der
  /// Hauptfaelligkeit anhand des Zahlungsintervalls vorgerueckt, bis er
  /// in der Zukunft liegt (Hauptfaelligkeit != naechster Zahlungstermin).
  DateTime get naechsteFaelligkeit {
    var termin = faelligkeitJaehrlichAm;
    final jetzt = DateTime.now();
    while (termin.isBefore(jetzt)) {
      termin = DateTime(termin.year, termin.month + zahlungsintervall.monate, termin.day);
    }
    return termin;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'gesellschaft': gesellschaft,
      'polizzennummer': polizzennummer,
      'art': art.name,
      'gueltig_ab': gueltigAb?.toIso8601String(),
      'faelligkeit_jaehrlich_am': faelligkeitJaehrlichAm.toIso8601String(),
      'zahlungsintervall': zahlungsintervall.name,
      'praemie_euro': praemieEuro,
      'notizen': notizen,
    };
  }

  factory PferdeVersicherung.fromMap(Map<String, Object?> map) {
    return PferdeVersicherung(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      gesellschaft: map['gesellschaft'] as String,
      polizzennummer: map['polizzennummer'] as String,
      art: VersicherungsArt.values.firstWhere(
        (a) => a.name == map['art'],
        orElse: () => VersicherungsArt.haftpflicht,
      ),
      gueltigAb: map['gueltig_ab'] != null
          ? DateTime.parse(map['gueltig_ab'] as String)
          : null,
      faelligkeitJaehrlichAm: DateTime.parse(map['faelligkeit_jaehrlich_am'] as String),
      zahlungsintervall: Zahlungsintervall.values.firstWhere(
        (z) => z.name == map['zahlungsintervall'],
        orElse: () => Zahlungsintervall.jaehrlich,
      ),
      praemieEuro: map['praemie_euro'] as double?,
      notizen: map['notizen'] as String?,
    );
  }
}
