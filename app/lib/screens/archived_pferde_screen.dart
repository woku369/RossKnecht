import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pferde_provider.dart';
import '../widgets/date_format_x.dart';
import '../widgets/empty_state.dart';
import 'pferd_detail_screen.dart';

class ArchivedPferdeScreen extends StatelessWidget {
  const ArchivedPferdeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archivierte Pferde')),
      body: Consumer<PferdeProvider>(
        builder: (context, provider, _) {
          final archivierte = provider.pferde.where((p) => p.archiviert).toList();
          if (archivierte.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              text: 'Keine archivierten Pferde.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: archivierte.length,
            itemBuilder: (context, index) {
              final p = archivierte[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.pets_outlined),
                  title: Text(p.anzeigename),
                  subtitle: Text(
                    '${p.archiviertGrund ?? 'Kein Grund angegeben'}'
                    '${p.archiviertAm != null ? ' · ${p.archiviertAm!.deDate}' : ''}',
                  ),
                  trailing: TextButton(
                    onPressed: () => provider.reaktivierePferd(p),
                    child: const Text('Reaktivieren'),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PferdDetailScreen(pferdId: p.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
