enum ImpfstoffTyp { influenza, tetanus, herpes, tollwut, sonstige }

extension ImpfstoffTypX on ImpfstoffTyp {
  String get label {
    switch (this) {
      case ImpfstoffTyp.influenza:
        return 'Influenza';
      case ImpfstoffTyp.tetanus:
        return 'Tetanus';
      case ImpfstoffTyp.herpes:
        return 'Herpes (Rhinopneumonitis)';
      case ImpfstoffTyp.tollwut:
        return 'Tollwut';
      case ImpfstoffTyp.sonstige:
        return 'Sonstige Impfung';
    }
  }
}

class Impfung {
  final String id;
  final String pferdId;
  ImpfstoffTyp impfstoffTyp;
  DateTime geimpftAm;
  DateTime faelligAm;
  String? chargennummer;
  String? dienstleisterId;
  int erinnerungTageVorher;
  String? notizen;

  Impfung({
    required this.id,
    required this.pferdId,
    required this.impfstoffTyp,
    required this.geimpftAm,
    required this.faelligAm,
    this.chargennummer,
    this.dienstleisterId,
    this.erinnerungTageVorher = 30,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'impfstoff_typ': impfstoffTyp.name,
      'geimpft_am': geimpftAm.toIso8601String(),
      'faellig_am': faelligAm.toIso8601String(),
      'chargennummer': chargennummer,
      'dienstleister_id': dienstleisterId,
      'erinnerung_tage_vorher': erinnerungTageVorher,
      'notizen': notizen,
    };
  }

  factory Impfung.fromMap(Map<String, Object?> map) {
    return Impfung(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      impfstoffTyp: ImpfstoffTyp.values.firstWhere(
        (t) => t.name == map['impfstoff_typ'],
        orElse: () => ImpfstoffTyp.sonstige,
      ),
      geimpftAm: DateTime.parse(map['geimpft_am'] as String),
      faelligAm: DateTime.parse(map['faellig_am'] as String),
      chargennummer: map['chargennummer'] as String?,
      dienstleisterId: map['dienstleister_id'] as String?,
      erinnerungTageVorher: map['erinnerung_tage_vorher'] as int? ?? 30,
      notizen: map['notizen'] as String?,
    );
  }
}
