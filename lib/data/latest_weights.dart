import 'package:drift/drift.dart';

import 'database.dart';

/// Último peso registrado de cada mascota, en kilos.
Future<Map<int, double>> latestWeightByPet(AppDatabase db) async {
  final rows = await (db.select(db.weights)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .get();
  final out = <int, double>{};
  for (final w in rows) {
    // Como vienen del más reciente, el primero de cada mascota es el último.
    out.putIfAbsent(w.petId, () => w.kg);
  }
  return out;
}
