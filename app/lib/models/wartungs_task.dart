class WartungsTask {
  final String id;
  final String pferdId;
  String titel;
  String? notizen;
  bool erledigt;
  DateTime erstelltAm;
  DateTime? erledigtAm;
  DateTime? faelligAm;
  int erinnerungTageVorher;

  WartungsTask({
    required this.id,
    required this.pferdId,
    required this.titel,
    this.notizen,
    this.erledigt = false,
    required this.erstelltAm,
    this.erledigtAm,
    this.faelligAm,
    this.erinnerungTageVorher = 3,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'titel': titel,
      'notizen': notizen,
      'erledigt': erledigt ? 1 : 0,
      'erstellt_am': erstelltAm.toIso8601String(),
      'erledigt_am': erledigtAm?.toIso8601String(),
      'faellig_am': faelligAm?.toIso8601String(),
      'erinnerung_tage_vorher': erinnerungTageVorher,
    };
  }

  factory WartungsTask.fromMap(Map<String, Object?> map) {
    return WartungsTask(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      titel: map['titel'] as String,
      notizen: map['notizen'] as String?,
      erledigt: (map['erledigt'] as int? ?? 0) == 1,
      erstelltAm: DateTime.parse(map['erstellt_am'] as String),
      erledigtAm: map['erledigt_am'] != null
          ? DateTime.parse(map['erledigt_am'] as String)
          : null,
      faelligAm: map['faellig_am'] != null
          ? DateTime.parse(map['faellig_am'] as String)
          : null,
      erinnerungTageVorher: map['erinnerung_tage_vorher'] as int? ?? 3,
    );
  }
}
