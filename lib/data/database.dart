import 'package:drift/drift.dart';

part 'database.g.dart';

/// Mascotas registradas. species: 'dog' | 'cat'. sex: 'female' | 'male'.
class Pets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get species => text()();
  TextColumn get breed => text().nullable()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get sex => text()();
  BoolColumn get neutered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get neuteredDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Registro de celo. Solo aplica a hembras no esterilizadas.
class HeatCycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId =>
      integer().references(Pets, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get intensity => text().nullable()(); // leve | moderada | alta
  TextColumn get flowColor => text().nullable()(); // rosado | rojo | ambar
  BoolColumn get maleContact => boolean().nullable()();
  TextColumn get notes => text().nullable()();
}

/// Registros de peso.
class Weights extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId =>
      integer().references(Pets, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  RealColumn get kg => real()();
}

/// Eventos: orinal, comida, vacuna, visita, medicina, etc.
/// nextDate: próxima fecha (próxima dosis o cita), si aplica.
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId =>
      integer().references(Pets, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get nextDate => dateTime().nullable()();
}

@DriftDatabase(tables: [Pets, HeatCycles, Weights, Events])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(events, events.nextDate);
          }
        },
        beforeOpen: (details) async {
          // Necesario para que el borrado en cascada funcione.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
