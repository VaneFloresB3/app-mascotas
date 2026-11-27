import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/latest_weights.dart';
import '../../domain/agenda.dart';
import '../pets/pets_providers.dart';

/// Cuidados de hoy y mañana para la portada.
///
/// Se recalcula cuando cambian mascotas, eventos o celos, y a medianoche,
/// para que «hoy» y «mañana» sean siempre de la fecha local del teléfono.
final agendaProvider = StreamProvider<List<AgendaItem>>((ref) {
  final db = ref.watch(databaseProvider);

  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(
    nextMidnight.difference(now) + const Duration(seconds: 1),
    () => ref.invalidateSelf(),
  );
  ref.onDispose(timer.cancel);

  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.pets, db.events, db.heatCycles},
      )
      .watch()
      .asyncMap((_) => _loadAgenda(db, DateTime.now()));
});

Future<List<AgendaItem>> _loadAgenda(AppDatabase db, DateTime now) async {
  // Las mascotas fallecidas no aparecen en «Hoy».
  final pets = await (db.select(db.pets)
        ..where((t) => t.deceasedDate.isNull()))
      .get();
  final events = await (db.select(db.events)
        ..where((e) => e.nextDate.isNotNull()))
      .get();
  final cycles = await db.select(db.heatCycles).get();

  final heatStarts = <int, List<DateTime>>{};
  for (final c in cycles) {
    heatStarts.putIfAbsent(c.petId, () => <DateTime>[]).add(c.startDate);
  }

  return buildAgenda(
    pets: [
      for (final p in pets)
        AgendaPet(
          id: p.id,
          name: p.name,
          species: p.species,
          sex: p.sex,
          neutered: p.neutered,
          photoPath: p.photoPath,
        ),
    ],
    events: [
      for (final e in events)
        if (e.nextDate != null)
          AgendaEvent(
            id: e.id,
            petId: e.petId,
            type: e.type,
            nextDate: e.nextDate!,
          ),
    ],
    heatStarts: heatStarts,
    now: now,
    latestKg: await latestWeightByPet(db),
  );
}
