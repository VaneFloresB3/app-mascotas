import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
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
}) {
  return db.into(db.events).insert(
        EventsCompanion.insert(
          petId: petId,
          type: type,
          date: date,
          notes: Value(notes),
          nextDate: Value(nextDate),
        ),
      );
}

Future<void> deleteEvent(AppDatabase db, int id) {
  return (db.delete(db.events)..where((t) => t.id.equals(id))).go();
}
