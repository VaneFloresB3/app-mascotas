import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../domain/event_types.dart';
import '../../domain/formatting.dart';
import '../../notifications/notification_service.dart';
import '../pets/pets_providers.dart';
import 'event_form_screen.dart';
import 'events_providers.dart';

/// Lista de eventos filtrada por tipos. Se usa en las pestañas Diario y Salud.
class EventsTab extends ConsumerWidget {
  const EventsTab({
    super.key,
    required this.petId,
    required this.types,
    required this.emptyText,
    this.highlightEventId,
  });

  final int petId;
  final Set<String> types;
  final String emptyText;

  /// Registro que se destaca al abrirlo desde la portada.
  final int? highlightEventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider(petId));

    return eventsAsync.when(
      data: (list) {
        final filtered = list.where((e) => types.contains(e.type)).toList();
        return Scaffold(
          body: filtered.isEmpty
              ? Center(child: Text(emptyText))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    final next = e.nextDate;
                    final extra = [
                      if (e.notes != null && e.notes!.isNotEmpty) e.notes!,
                      if (next != null) 'Próxima: ${fmtDate(next)}',
                    ].join(' · ');
                    return ListTile(
                      tileColor: e.id == highlightEventId
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : null,
                      title: Text(eventTypeLabels[e.type] ?? e.type),
                      subtitle: Text(
                        extra.isEmpty
                            ? fmtDateTime(e.date)
                            : '${fmtDateTime(e.date)}\n$extra',
                      ),
                      isThreeLine: extra.isNotEmpty,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(ref, e.id),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventFormScreen(petId: petId, types: types),
              ),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Future<void> _delete(WidgetRef ref, int id) async {
    final db = ref.read(databaseProvider);
    await deleteEvent(db, id);
    await syncReminders(db);
  }
}
