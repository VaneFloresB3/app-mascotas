import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/database_connection.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
});

/// Lista de mascotas ordenada por nombre, se actualiza sola al cambiar la base.
final petsProvider = StreamProvider<List<Pet>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.pets)
    ..orderBy([(t) => OrderingTerm(expression: t.name)]);
  return query.watch();
});

Future<void> addPet(
  AppDatabase db, {
  required String name,
  required String species,
  required String sex,
  bool neutered = false,
  String? photoPath,
}) {
  return db.into(db.pets).insert(
        PetsCompanion.insert(
          name: name,
          species: species,
          sex: sex,
          neutered: Value(neutered),
          photoPath: Value(photoPath),
        ),
      );
}
