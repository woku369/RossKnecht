enum DienstleisterTyp { tierarzt, hufschmied, sattler, sonstiges }

extension DienstleisterTypX on DienstleisterTyp {
  String get label {
    switch (this) {
      case DienstleisterTyp.tierarzt:
        return 'Tierarzt';
      case DienstleisterTyp.hufschmied:
        return 'Hufschmied';
      case DienstleisterTyp.sattler:
        return 'Sattler';
      case DienstleisterTyp.sonstiges:
        return 'Sonstiges';
    }
  }
}

class Dienstleister {
  final String id;
  String name;
  DienstleisterTyp typ;
  String? telefon;
  String? adresse;
  String? notizen;

  Dienstleister({
    required this.id,
    required this.name,
    required this.typ,
    this.telefon,
    this.adresse,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'typ': typ.name,
      'telefon': telefon,
      'adresse': adresse,
      'notizen': notizen,
    };
  }

  factory Dienstleister.fromMap(Map<String, Object?> map) {
    return Dienstleister(
      id: map['id'] as String,
      name: map['name'] as String,
      typ: DienstleisterTyp.values.firstWhere(
        (t) => t.name == map['typ'],
        orElse: () => DienstleisterTyp.sonstiges,
      ),
      telefon: map['telefon'] as String?,
      adresse: map['adresse'] as String?,
      notizen: map['notizen'] as String?,
    );
  }
}
