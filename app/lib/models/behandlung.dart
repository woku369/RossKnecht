class Behandlung {
  final String id;
  final String pferdId;
  DateTime datum;
  String grund;
  String? behandlung;
  String? dienstleisterId;
  double? kostenEuro;
  DateTime? nachkontrolleAm;
  int erinnerungTageVorher;
  String? notizen;

  Behandlung({
    required this.id,
    required this.pferdId,
    required this.datum,
    required this.grund,
    this.behandlung,
    this.dienstleisterId,
    this.kostenEuro,
    this.nachkontrolleAm,
    this.erinnerungTageVorher = 2,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'datum': datum.toIso8601String(),
      'grund': grund,
      'behandlung': behandlung,
      'dienstleister_id': dienstleisterId,
      'kosten_euro': kostenEuro,
      'nachkontrolle_am': nachkontrolleAm?.toIso8601String(),
      'erinnerung_tage_vorher': erinnerungTageVorher,
      'notizen': notizen,
    };
  }

  factory Behandlung.fromMap(Map<String, Object?> map) {
    return Behandlung(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      datum: DateTime.parse(map['datum'] as String),
      grund: map['grund'] as String,
      behandlung: map['behandlung'] as String?,
      dienstleisterId: map['dienstleister_id'] as String?,
      kostenEuro: map['kosten_euro'] as double?,
      nachkontrolleAm: map['nachkontrolle_am'] != null
          ? DateTime.parse(map['nachkontrolle_am'] as String)
          : null,
      erinnerungTageVorher: map['erinnerung_tage_vorher'] as int? ?? 2,
      notizen: map['notizen'] as String?,
    );
  }
}
