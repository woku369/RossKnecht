class Turnierstart {
  final String id;
  final String pferdId;
  DateTime datum;
  String turnierort;
  String? disziplin;
  String? ergebnis;
  String? notizen;

  Turnierstart({
    required this.id,
    required this.pferdId,
    required this.datum,
    required this.turnierort,
    this.disziplin,
    this.ergebnis,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pferd_id': pferdId,
      'datum': datum.toIso8601String(),
      'turnierort': turnierort,
      'disziplin': disziplin,
      'ergebnis': ergebnis,
      'notizen': notizen,
    };
  }

  factory Turnierstart.fromMap(Map<String, Object?> map) {
    return Turnierstart(
      id: map['id'] as String,
      pferdId: map['pferd_id'] as String,
      datum: DateTime.parse(map['datum'] as String),
      turnierort: map['turnierort'] as String,
      disziplin: map['disziplin'] as String?,
      ergebnis: map['ergebnis'] as String?,
      notizen: map['notizen'] as String?,
    );
  }
}
