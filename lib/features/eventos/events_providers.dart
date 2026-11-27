import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/photo_storage.dart';
import '../pets/pets_providers.dart';

/// Eventos de una mascota, del más reciente al más antiguo.
final eventsProvider = StreamProvider.family<List<Event>, int>((ref, petId) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.events)
    ..where((t) => t.petId.equals(petId))
    ..orderBy([(t) => OrderingTerm.desc(t.date)]);
  return query.watch();
});

Future<void> addEvent(
  AppDatabase db, {
  required int petId,
  required String type,
  required DateTime date,
  String? notes,
  DateTime? nextDate,
  String? photoPath,
}) {
  return db.into(db.events).insert(
        EventsCompanion.insert(
          petId: petId,
          type: type,
          date: date,
          notes: Value(notes),
          nextDate: Value(nextDate),
          photoPath: Value(photoPath),
        ),
      );
}

/// Borra el registro y la foto de su etiqueta, si tenía una.
Future<void> deleteEvent(AppDatabase db, int id) async {
  final event = await (db.select(db.events)..where((t) => t.id.equals(id)))
      .getSingleOrNull();
  await (db.delete(db.events)..where((t) => t.id.equals(id))).go();
  if (event?.photoPath != null) {
    await deletePetPhoto(event!.photoPath);
  }
}

/// Borra las fotos de los registros de una mascota. Úsalo antes de borrar la mascota,
/// porque al borrarla sus registros también desaparecen.
Future<void> deleteEventPhotosOfPet(AppDatabase db, int petId) async {
  final rows = await (db.select(db.events)..where((t) => t.petId.equals(petId)))
      .get();
  for (final e in rows) {
    await deletePetPhoto(e.photoPath);
  }
}
