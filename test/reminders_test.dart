import 'package:app_mascotas/domain/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dogs = [
    const PetInfo(id: 1, name: 'Peque', species: 'dog', sex: 'female', neutered: false),
  ];

  test('avisa 7 días antes del celo estimado a la hora elegida', () {
    final r = buildReminders(
      pets: dogs,
      heatStarts: {1: [DateTime(2026, 1, 1)]},
      openCycle: {1: false},
      events: const [],
      now: DateTime(2026, 1, 10, 10),
      hour: 19,
    );

    final aviso = r.firstWhere((x) => x.title == 'Próximo celo de Peque');
    // Estimado: 2 de julio de 2026. Aviso: 25 de junio a las 19:00.
    expect(aviso.when, DateTime(2026, 6, 25, 19));
  });

  test('no programa recordatorios que ya pasaron', () {
    final r = buildReminders(
      pets: dogs,
      heatStarts: {1: [DateTime(2026, 1, 1)]},
      openCycle: {1: false},
      events: const [],
      now: DateTime(2026, 7, 5),
      hour: 19,
    );

    expect(r.any((x) => x.title.startsWith('Próximo celo')), isFalse);
    expect(r.any((x) => x.title.startsWith('Celo estimado')), isFalse);
  });

  test('avisa el día anterior a la próxima vacuna', () {
    final r = buildReminders(
      pets: dogs,
      heatStarts: const {},
      openCycle: const {},
      events: [
        EventInfo(
          id: 7,
          petId: 1,
          petName: 'Peque',
          type: 'vacuna',
          nextDate: DateTime(2026, 1, 20),
        ),
      ],
      now: DateTime(2026, 1, 10),
      hour: 19,
    );

    expect(r.length, 1);
    expect(r.first.title, 'Mañana: Vacunación de Peque');
    expect(r.first.when, DateTime(2026, 1, 19, 19));
  });

  test('gata fuera de temporada no genera avisos de celo', () {
    final r = buildReminders(
      pets: const [
        PetInfo(id: 2, name: 'Mishi', species: 'cat', sex: 'female', neutered: false),
      ],
      heatStarts: {2: [DateTime(2026, 10, 1)]},
      openCycle: {2: false},
      events: const [],
      now: DateTime(2026, 12, 1),
      hour: 19,
    );

    expect(r, isEmpty);
  });
}
