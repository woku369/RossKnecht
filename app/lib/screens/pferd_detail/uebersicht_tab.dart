import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/pferd.dart';
import '../../widgets/date_format_x.dart';

class UebersichtTab extends StatelessWidget {
  final Pferd pferd;

  const UebersichtTab({super.key, required this.pferd});

  @override
  Widget build(BuildContext context) {
    final zeilen = <MapEntry<String, String>>[
      if (pferd.eingetragenerName != null && pferd.eingetragenerName!.isNotEmpty)
        MapEntry('Eingetragener Name', pferd.eingetragenerName!),
      MapEntry('Rasse', pferd.rasse ?? '-'),
      MapEntry('Geschlecht', pferd.geschlecht.label),
      MapEntry('Geburtsjahr', pferd.geburtsjahr != null ? '${pferd.geburtsjahr} (${pferd.alterJahre} Jahre)' : '-'),
      MapEntry('Farbe', pferd.farbe ?? '-'),
      MapEntry('Abzeichen', pferd.abzeichen ?? '-'),
      MapEntry('Lebensnummer (UELN)', pferd.lebensnummer ?? '-'),
      MapEntry('Chipnummer', pferd.chipnummer ?? '-'),
      MapEntry('Besitzer', pferd.besitzer ?? '-'),
      MapEntry('Stallplatz', pferd.stallplatz ?? '-'),
      if (pferd.externerStallname != null && pferd.externerStallname!.isNotEmpty)
        MapEntry('Auswärtiger Stall', pferd.externerStallname!),
      if (pferd.externerKontakt != null && pferd.externerKontakt!.isNotEmpty)
        MapEntry('Kontakt (auswärts)', pferd.externerKontakt!),
      MapEntry('Ankunftsdatum', pferd.ankunftsdatum != null ? pferd.ankunftsdatum!.deDate : '-'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pferd.fotoPfad != null)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(pferd.fotoPfad!), height: 200, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: zeilen
                  .map(
                    (z) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 160,
                            child: Text(z.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Expanded(child: Text(z.value)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (pferd.notizen != null && pferd.notizen!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notizen', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(pferd.notizen!),
                ],
              ),
            ),
          ),
        ],
        if (pferd.archiviert) ...[
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archiviert${pferd.archiviertAm != null ? ' am ${pferd.archiviertAm!.deDate}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (pferd.archiviertGrund != null && pferd.archiviertGrund!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Grund: ${pferd.archiviertGrund}'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
