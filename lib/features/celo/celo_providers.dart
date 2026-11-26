import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../pets/pets_providers.dart';

final petByIdProvider = StreamProvider.family<Pet?, int>((ref, petId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.pets)..where((t) => t.id.equals(petId)))
      .watchSingleOrNull();
});

/// Celos de una mascota, del más reciente al más antiguo.
final heatCyclesProvider = StreamProvider.family<List<HeatCycle>, int>((ref, petId) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.heatCycles)
    ..where((t) => t.petId.equals(petId))
    ..orderBy([(t) => OrderingTerm.desc(t.startDate)]);
  return query.watch();
});

Future<void> addHeatCycle(
  AppDatabase db, {
  required int petId,
  required DateTime start,
  DateTime? end,
  String? intensity,
  String? flowColor,
  bool? maleContact,
  String? notes,
}) {
  return db.into(db.heatCycles).insert(
        HeatCyclesCompanion.insert(
          petId: petId,
          startDate: start,
          endDate: Value(end),
          intensity: Value(intensity),
          flowColor: Value(flowColor),
          maleContact: Value(maleContact),
          notes: Value(notes),
        ),
      );
}

Future<void> deleteHeatCycle(AppDatabase db, int id) {
  return (db.delete(db.heatCycles)..where((t) => t.id.equals(id))).go();
}
