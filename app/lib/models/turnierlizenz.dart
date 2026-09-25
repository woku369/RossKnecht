enum Turnierverband { fn, fei, landesverband, sonstiger }

extension TurnierverbandX on Turnierverband {
  String get label {
    switch (this) {
      case Turnierverband.fn:
        return 'FN (Deutsche Reiterliche Vereinigung)';
      case Turnierverband.fei:
        return 'FEI (International)';
      case Turnierverband.landesverband:
        return 'Landesverband';
      case Turnierverband.sonstiger:
        return 'Sonstiger Verband';
    }
  }
}

class Turnierlizenz {
  final String id;
  final String pferdId;
  Turnierverband verband;
  String? lizenznummer;
  DateTime gueltigVon;
  DateTime gueltigBis;
  int erinnerungTageVorher;
  String? notizen;

  Turnierlizenz({
    required this.id,
    required this.pferdId,
    required this.verband,
    this.lizenznummer,
    required this.gueltigVon,
    required this.gueltigBis,
    this.erinnerungTageVorher = 30,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'verband': verband.name,
      'lizenznummer': lizenznummer,
      'gueltig_von': gueltigVon.toIso8601String(),
      'gueltig_bis': gueltigBis.toIso8601String(),
      'erinnerung_tage_vorher': erinnerungTageVorher,
      'notizen': notizen,
    };
  }

  factory Turnierlizenz.fromMap(Map<String, Object?> map) {
    return Turnierlizenz(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      verband: Turnierverband.values.firstWhere(
        (v) => v.name == map['verband'],
        orElse: () => Turnierverband.sonstiger,
      ),
      lizenznummer: map['lizenznummer'] as String?,
      gueltigVon: DateTime.parse(map['gueltig_von'] as String),
      gueltigBis: DateTime.parse(map['gueltig_bis'] as String),
      erinnerungTageVorher: map['erinnerung_tage_vorher'] as int? ?? 30,
      notizen: map['notizen'] as String?,
    );
  }
}
