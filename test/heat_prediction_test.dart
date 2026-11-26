import 'package:app_mascotas/domain/heat_prediction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('perra sin historial usa el valor por defecto de seis meses', () {
    final last = DateTime(2026, 1, 1);
    final p = predictNextHeat(
      species: 'dog',
      starts: [last],
      now: DateTime(2026, 1, 10),
    );

    expect(p, isNotNull);
    expect(p!.estimated, last.add(const Duration(days: 182)));
    expect(p.earliest, last.add(const Duration(days: 120)));
    expect(p.latest, last.add(const Duration(days: 365)));
  });

  test('con historial usa la mediana de los intervalos reales', () {
    final first = DateTime(2026, 1, 1);
    final second = first.add(const Duration(days: 181));
    final third = second.add(const Duration(days: 181));
    final p = predictNextHeat(
      species: 'dog',
      starts: [first, second, third],
      now: DateTime(2027, 1, 1),
    );

    expect(p, isNotNull);
    expect(p!.estimated, third.add(const Duration(days: 181)));
  });

  test('sin registros no hay predicción', () {
    final p = predictNextHeat(
      species: 'dog',
      starts: const [],
      now: DateTime(2026, 1, 1),
    );
    expect(p, isNull);
  });

  test('gata en temporada tiene estimación de 21 días', () {
    final last = DateTime(2026, 4, 1);
    final p = predictNextHeat(
      species: 'cat',
      starts: [last],
      now: DateTime(2026, 4, 2),
    );

    expect(p, isNotNull);
    expect(p!.estimated, last.add(const Duration(days: 21)));
  });

  test('gata fuera de temporada no muestra predicción', () {
    final p = predictNextHeat(
      species: 'cat',
      starts: [DateTime(2026, 10, 1)],
      now: DateTime(2026, 12, 1),
    );
    expect(p, isNull);
  });
}
