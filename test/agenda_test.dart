import 'package:flutter_test/flutter_test.dart';

import 'package:app_mascotas/domain/agenda.dart';

void main() {
  final now = DateTime(2026, 11, 27, 15, 30);

  AgendaPet pet(int id, String name, {String species = 'dog', String sex = 'male', bool neutered = false}) =>
      AgendaPet(id: id, name: name, species: species, sex: sex, neutered: neutered);

  test('muestra avisos de hoy y de mañana, y no los de pasado mañana', () {
    final items = buildAgenda(
      pets: [pet(1, 'Luna')],
      events: [
        AgendaEvent(id: 10, petId: 1, type: 'vacuna', nextDate: DateTime(2026, 11, 27)),
        AgendaEvent(id: 11, petId: 1, type: 'medicina', nextDate: DateTime(2026, 11, 28)),
        AgendaEvent(id: 12, petId: 1, type: 'visita', nextDate: DateTime(2026, 11, 29)),
      ],
      heatStarts: const {},
      now: now,
    );

    expect(items.map((i) => i.title), [
      'Luna · Vacuna hoy',
      'Luna · Medicina mañana',
    ]);
  });

  test('los de hoy van primero aunque el nombre sea posterior', () {
    final items = buildAgenda(
      pets: [pet(1, 'Ana'), pet(2, 'Zeus')],
      events: [
        AgendaEvent(id: 1, petId: 1, type: 'vacuna', nextDate: DateTime(2026, 11, 28)),
        AgendaEvent(id: 2, petId: 2, type: 'vacuna', nextDate: DateTime(2026, 11, 27)),
      ],
      heatStarts: const {},
      now: now,
    );

    expect(items.map((i) => i.petName), ['Zeus', 'Ana']);
    expect(items.first.isToday, isTrue);
  });

  test('dos mascotas con el mismo nombre conservan su evento', () {
    final items = buildAgenda(
      pets: [pet(1, 'Luna'), pet(2, 'Luna')],
      events: [
        AgendaEvent(id: 100, petId: 1, type: 'vacuna', nextDate: DateTime(2026, 11, 27)),
        AgendaEvent(id: 200, petId: 2, type: 'vacuna', nextDate: DateTime(2026, 11, 27)),
      ],
      heatStarts: const {},
      now: now,
    );

    expect(items.map((i) => (i.petId, i.eventId)), [(1, 100), (2, 200)]);
  });

  test('el celo estimado conserva la palabra estimado', () {
    final items = buildAgenda(
      pets: [pet(1, 'Luna', sex: 'female')],
      events: const [],
      // Inicio hace 120 días: el estimado cae hoy.
      heatStarts: {1: [now.subtract(const Duration(days: 120))]},
      now: now,
    );

    expect(items, hasLength(1));
    expect(items.single.isHeat, isTrue);
    expect(items.single.title, 'Luna · Celo estimado hoy');
    expect(items.single.eventId, isNull);
  });

  test('sin avisos la lista queda vacía', () {
    final items = buildAgenda(
      pets: [pet(1, 'Luna')],
      events: const [],
      heatStarts: const {},
      now: now,
    );
    expect(items, isEmpty);
  });

  test('evento de una mascota que ya no existe se ignora', () {
    final items = buildAgenda(
      pets: const [],
      events: [AgendaEvent(id: 1, petId: 9, type: 'vacuna', nextDate: DateTime(2026, 11, 27))],
      heatStarts: const {},
      now: now,
    );
    expect(items, isEmpty);
  });
}
