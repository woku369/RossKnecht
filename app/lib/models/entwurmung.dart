enum EntwurmungsMethode { wurmkur, kotprobe }

extension EntwurmungsMethodeX on EntwurmungsMethode {
  String get label {
    switch (this) {
      case EntwurmungsMethode.wurmkur:
        return 'Wurmkur';
      case EntwurmungsMethode.kotprobe:
        return 'Kotprobe (selektive Entwurmung)';
    }
  }
}

class Entwurmung {
  final String id;
  final String pferdId;
  EntwurmungsMethode methode;
  String? praeparatOderWirkstoff;
  DateTime durchgefuehrtAm;
  DateTime faelligAm;
  String? ergebnis;
  int erinnerungTageVorher;
  String? notizen;

  Entwurmung({
    required this.id,
    required this.pferdId,
    required this.methode,
    this.praeparatOderWirkstoff,
    required this.durchgefuehrtAm,
    required this.faelligAm,
    this.ergebnis,
    this.erinnerungTageVorher = 14,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'methode': methode.name,
      'praeparat_oder_wirkstoff': praeparatOderWirkstoff,
      'durchgefuehrt_am': durchgefuehrtAm.toIso8601String(),
      'faellig_am': faelligAm.toIso8601String(),
      'ergebnis': ergebnis,
      'erinnerung_tage_vorher': erinnerungTageVorher,
      'notizen': notizen,
    };
  }

  factory Entwurmung.fromMap(Map<String, Object?> map) {
    return Entwurmung(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      methode: EntwurmungsMethode.values.firstWhere(
        (m) => m.name == map['methode'],
        orElse: () => EntwurmungsMethode.wurmkur,
      ),
      praeparatOderWirkstoff: map['praeparat_oder_wirkstoff'] as String?,
      durchgefuehrtAm: DateTime.parse(map['durchgefuehrt_am'] as String),
      faelligAm: DateTime.parse(map['faellig_am'] as String),
      ergebnis: map['ergebnis'] as String?,
      erinnerungTageVorher: map['erinnerung_tage_vorher'] as int? ?? 14,
      notizen: map['notizen'] as String?,
    );
  }
}
