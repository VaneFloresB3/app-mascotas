import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/database_connection.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
});

/// Mascotas activas ordenadas por nombre, se actualiza sola al cambiar la base.
final petsProvider = StreamProvider<List<Pet>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.pets)
    ..where((t) => t.deceasedDate.isNull())
    ..orderBy([(t) => OrderingTerm(expression: t.name)]);
  return query.watch();
});

/// Mascotas fallecidas, para la sección de Recuerdos. Más recientes primero.
final deceasedPetsProvider = StreamProvider<List<Pet>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.pets)
    ..where((t) => t.deceasedDate.isNotNull())
    ..orderBy([(t) => OrderingTerm.desc(t.deceasedDate)]);
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
