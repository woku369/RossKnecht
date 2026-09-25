enum DokumentKategorie {
  equidenpass,
  impfausweis,
  kaufvertrag,
  versicherungspolizze,
  roentgenbild,
  sonstiges,
}

extension DokumentKategorieX on DokumentKategorie {
  String get label {
    switch (this) {
      case DokumentKategorie.equidenpass:
        return 'Equidenpass';
      case DokumentKategorie.impfausweis:
        return 'Impfausweis';
      case DokumentKategorie.kaufvertrag:
        return 'Kaufvertrag';
      case DokumentKategorie.versicherungspolizze:
        return 'Versicherungspolizze';
      case DokumentKategorie.roentgenbild:
        return 'Röntgenbild';
      case DokumentKategorie.sonstiges:
        return 'Sonstiges';
    }
  }
}

class PferdeDokument {
  final String id;
  final String pferdId;
  DokumentKategorie kategorie;
  String dateipfad;
  String titel;
  DateTime erstelltAm;
  String? notizen;

  PferdeDokument({
    required this.id,
    required this.pferdId,
    required this.kategorie,
    required this.dateipfad,
    required this.titel,
    required this.erstelltAm,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'kategorie': kategorie.name,
      'dateipfad': dateipfad,
      'titel': titel,
      'erstellt_am': erstelltAm.toIso8601String(),
      'notizen': notizen,
    };
  }

  factory PferdeDokument.fromMap(Map<String, Object?> map) {
    return PferdeDokument(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      kategorie: DokumentKategorie.values.firstWhere(
        (k) => k.name == map['kategorie'],
        orElse: () => DokumentKategorie.sonstiges,
      ),
      dateipfad: map['dateipfad'] as String,
      titel: map['titel'] as String,
      erstelltAm: DateTime.parse(map['erstellt_am'] as String),
      notizen: map['notizen'] as String?,
    );
  }
}
