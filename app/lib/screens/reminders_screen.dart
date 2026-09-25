import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder.dart';
import '../providers/pferde_provider.dart';
import '../widgets/date_format_x.dart';
import '../widgets/empty_state.dart';
import 'pferd_detail_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late Future<List<Reminder>> _future;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  void _laden() {
    _future = context.read<PferdeProvider>().getUpcomingReminders();
  }

  Color? _farbe(Reminder r) {
    if (r.ueberfaellig) return Colors.red;
    if (r.tageBisFaellig <= 14) return Colors.orange;
    return null;
  }

  IconData _icon(ReminderTyp typ) {
    switch (typ) {
      case ReminderTyp.impfung:
        return Icons.vaccines;
      case ReminderTyp.entwurmung:
        return Icons.bug_report_outlined;
      case ReminderTyp.gesundheitstermin:
        return Icons.local_hospital_outlined;
      case ReminderTyp.turnierlizenz:
        return Icons.badge_outlined;
      case ReminderTyp.decke:
        return Icons.checkroom_outlined;
      case ReminderTyp.versicherung:
        return Icons.shield_outlined;
      case ReminderTyp.wartungsTask:
        return Icons.checklist_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anstehende Termine')),
      body: FutureBuilder<List<Reminder>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final liste = snapshot.data!;
          if (liste.isEmpty) {
            return const EmptyState(icon: Icons.event_available_outlined, text: 'Keine anstehenden Termine.');
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(_laden);
              await _future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: liste.length,
              itemBuilder: (context, index) {
                final r = liste[index];
                final farbe = _farbe(r);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(_icon(r.typ), color: farbe),
                    title: Text(r.titel),
                    subtitle: Text(
                      '${r.pferdName} · ${r.typ.label} · fällig ${r.faelligAm.deDate}'
                      '${r.ueberfaellig ? ' (überfällig)' : ''}',
                    ),
                    trailing: farbe != null ? Icon(Icons.warning_amber_rounded, color: farbe) : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PferdDetailScreen(pferdId: r.pferdId)),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
