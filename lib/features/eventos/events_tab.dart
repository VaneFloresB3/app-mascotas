import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/photo_storage.dart';
import '../../domain/event_types.dart';
import '../../domain/formatting.dart';
import '../../notifications/notification_service.dart';
import '../pets/activity_header.dart';
import '../pets/pet_mascot.dart';
import '../pets/pets_providers.dart';
import 'event_form_screen.dart';
import 'events_providers.dart';

/// Lista de eventos filtrada por tipos. Se usa en las pestañas Diario y Salud.
class EventsTab extends ConsumerWidget {
  const EventsTab({
    super.key,
    required this.petId,
    required this.species,
    required this.types,
    required this.emptyText,
    this.highlightEventId,
  });

  final String species;
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
          body: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: filtered.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                final diary = types == dailyTypes;
                return ActivityHeader(
                    species: species,
                    activity:
                        diary ? MascotActivity.diary : MascotActivity.health,
                    title: diary ? 'Diario de cuidados' : 'Historial de salud',
                    description: filtered.isEmpty
                        ? emptyText
                        : filtered.length == 1
                            ? '1 registro'
                            : '${filtered.length} registros',
                    color: diary
                        ? const Color(0xffffe5cd)
                        : const Color(0xffffe0dc));
              }
              final e = filtered[i - 1];
              final next = e.nextDate;
              final extra = [
                if (e.notes != null && e.notes!.isNotEmpty) e.notes!,
                if (next != null) 'Próxima: ${fmtDate(next)}',
              ].join(' · ');
              return Card(
                child: ListTile(
                  tileColor: e.id == highlightEventId
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                  leading: e.photoPath == null
                      ? null
                      : _Thumb(photoPath: e.photoPath!),
                  onTap: e.photoPath == null
                      ? null
                      : () => _verFoto(context, e.photoPath!),
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
            tooltip: 'Agregar registro',
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

  void _verFoto(BuildContext context, String photoPath) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: FutureBuilder<File?>(
          future: petPhotoFile(photoPath),
          builder: (ctx, snap) {
            final file = snap.data;
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (file == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('La foto ya no está disponible.'),
              );
            }
            return InteractiveViewer(child: Image.file(file));
          },
        ),
      ),
    );
  }
}

/// Miniatura de la foto de una etiqueta. Muestra un icono si el archivo falta.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: petPhotoFile(photoPath),
      builder: (context, snap) {
        final file = snap.data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 48,
            height: 48,
            child: file == null
                ? const Icon(Icons.image_not_supported_outlined)
                : Image.file(file, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
