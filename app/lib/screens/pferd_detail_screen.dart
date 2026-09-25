import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pferde_provider.dart';
import '../services/history_export_service.dart';
import '../services/pferdeblatt_export_service.dart';
import 'pferd_detail/decken_tab.dart';
import 'pferd_detail/dokumente_versicherung_tab.dart';
import 'pferd_detail/entwurmung_tab.dart';
import 'pferd_detail/gesundheit_tab.dart';
import 'pferd_detail/impfungen_tab.dart';
import 'pferd_detail/turnier_tab.dart';
import 'pferd_detail/uebersicht_tab.dart';
import 'pferd_detail/wartung_tab.dart';
import 'pferd_form_screen.dart';

class PferdDetailScreen extends StatelessWidget {
  final String pferdId;

  const PferdDetailScreen({super.key, required this.pferdId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PferdeProvider>(
      builder: (context, provider, _) {
        final treffer = provider.pferde.where((p) => p.id == pferdId);
        if (treffer.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Pferd wurde gelöscht.')),
          );
        }
        final pferd = treffer.first;

        return DefaultTabController(
          length: 8,
          child: Scaffold(
            appBar: AppBar(
              title: Text(pferd.anzeigename),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Bearbeiten',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PferdFormScreen(bestehendesPferd: pferd)),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'pdf':
                        await PferdeblattExportService.instance.exportUndTeilen(pferd);
                        break;
                      case 'historie':
                        await HistoryExportService.instance.exportUndTeilen(pferd);
                        break;
                      case 'archivieren':
                        await _archivieren(context, provider, pferdId);
                        break;
                      case 'loeschen':
                        await _loeschen(context, provider, pferdId);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pdf', child: Text('Pferdeblatt als PDF exportieren')),
                    const PopupMenuItem(value: 'historie', child: Text('Historie exportieren')),
                    if (!pferd.archiviert)
                      const PopupMenuItem(
                        value: 'archivieren',
                        child: Text('Archivieren (verkauft/verstorben)'),
                      ),
                    const PopupMenuItem(value: 'loeschen', child: Text('Endgültig löschen')),
                  ],
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Übersicht'),
                  Tab(text: 'Impfungen'),
                  Tab(text: 'Entwurmung'),
                  Tab(text: 'Gesundheit'),
                  Tab(text: 'Turnier'),
                  Tab(text: 'Decken'),
                  Tab(text: 'Dokumente'),
                  Tab(text: 'Wartung'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                UebersichtTab(pferd: pferd),
                ImpfungenTab(pferd: pferd),
                EntwurmungTab(pferd: pferd),
                GesundheitTab(pferd: pferd),
                TurnierTab(pferd: pferd),
                DeckenTab(pferd: pferd),
                DokumenteVersicherungTab(pferd: pferd),
                WartungTab(pferd: pferd),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _archivieren(BuildContext context, PferdeProvider provider, String pferdId) async {
    final treffer = provider.pferde.where((p) => p.id == pferdId);
    if (treffer.isEmpty) return;
    final pferd = treffer.first;
    final grundController = TextEditingController();
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pferd archivieren'),
        content: TextField(
          controller: grundController,
          decoration: const InputDecoration(labelText: 'Grund (z. B. verkauft, verstorben)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archivieren')),
        ],
      ),
    );
    if (bestaetigt == true) {
      await provider.archivierePferd(pferd, grund: grundController.text.trim());
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _loeschen(BuildContext context, PferdeProvider provider, String pferdId) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pferd endgültig löschen?'),
        content: const Text(
          'Alle Impfungen, Termine, Dokumente und Historie zu diesem Pferd werden unwiderruflich gelöscht.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (bestaetigt == true) {
      await provider.deletePferd(pferdId);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
