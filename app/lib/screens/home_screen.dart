import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pferd.dart';
import '../providers/pferde_provider.dart';
import '../services/local_backup_service.dart';
import '../services/share_import_service.dart';
import '../widgets/empty_state.dart';
import 'archived_pferde_screen.dart';
import 'backup_screen.dart';
import 'dienstleister_screen.dart';
import 'pferd_detail_screen.dart';
import 'pferd_form_screen.dart';
import 'reminders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PferdeProvider>().loadAll();
    });
    _aufGeteilteBackupsHoeren();
  }

  // Reagiert auf eine per Android-Teilen-Dialog ("Öffnen mit RossKnecht")
  // empfangene Backup-ZIP-Datei - sowohl beim Kaltstart als auch, wenn die
  // App bereits im Hintergrund lief (siehe MainActivity.kt).
  void _aufGeteilteBackupsHoeren() {
    ShareImportService.instance.holeBeimStartEmpfangeneZip().then((pfad) {
      if (pfad != null) _geteiltesBackupImportieren(pfad);
    });
    ShareImportService.instance.aufNeueGeteilteZipHoeren(_geteiltesBackupImportieren);
  }

  Future<void> _geteiltesBackupImportieren(String pfad) async {
    if (!mounted) return;
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geteiltes Backup importieren?'),
        content: const Text('Der komplette aktuelle Datenbestand wird durch diese Backup-Datei ersetzt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Importieren')),
        ],
      ),
    );
    if (bestaetigt != true || !mounted) return;
    await LocalBackupService.instance.importFromZip(pfad);
    if (!mounted) return;
    await context.read<PferdeProvider>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RossKnecht'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Anstehende Termine',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Dienstleister',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DienstleisterScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Archivierte Pferde',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArchivedPferdeScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_outlined),
            tooltip: 'Backup & Cloud-Sync',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<PferdeProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final aktivePferde = provider.pferde.where((p) => !p.archiviert).toList();
          if (aktivePferde.isEmpty) {
            return const EmptyState(
              icon: Icons.pets_outlined,
              text: 'Noch keine Pferde erfasst.\nMit + unten rechts das erste Pferd anlegen.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: aktivePferde.length,
            itemBuilder: (context, index) => _PferdCard(pferd: aktivePferde[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PferdFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PferdCard extends StatelessWidget {
  final Pferd pferd;

  const _PferdCard({required this.pferd});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: pferd.fotoPfad != null ? FileImage(File(pferd.fotoPfad!)) : null,
          child: pferd.fotoPfad == null ? const Icon(Icons.pets) : null,
        ),
        title: Text(pferd.anzeigename, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          [
            if (pferd.rasse != null && pferd.rasse!.isNotEmpty) pferd.rasse!,
            pferd.geschlecht.label,
            if (pferd.alterJahre != null) '${pferd.alterJahre} Jahre',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PferdDetailScreen(pferdId: pferd.id)),
        ),
      ),
    );
  }
}
