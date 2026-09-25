enum ReminderTyp {
  impfung,
  entwurmung,
  gesundheitstermin,
  turnierlizenz,
  decke,
  versicherung,
  wartungsTask,
}

extension ReminderTypX on ReminderTyp {
  String get label {
    switch (this) {
      case ReminderTyp.impfung:
        return 'Impfung';
      case ReminderTyp.entwurmung:
        return 'Entwurmung';
      case ReminderTyp.gesundheitstermin:
        return 'Gesundheitstermin';
      case ReminderTyp.turnierlizenz:
        return 'Turnierlizenz';
      case ReminderTyp.decke:
        return 'Decke';
      case ReminderTyp.versicherung:
        return 'Versicherung';
      case ReminderTyp.wartungsTask:
        return 'Wartungs-To-Do';
    }
  }
}

class Reminder {
  final String quelleId;
  final String pferdId;
  final String pferdName;
  final ReminderTyp typ;
  final String titel;
  final DateTime faelligAm;

  Reminder({
    required this.quelleId,
    required this.pferdId,
    required this.pferdName,
    required this.typ,
    required this.titel,
    required this.faelligAm,
  });

  int get tageBisFaellig => faelligAm.difference(DateTime.now()).inDays;
  bool get ueberfaellig => faelligAm.isBefore(DateTime.now());
}
