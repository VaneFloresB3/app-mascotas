import 'package:app_mascotas/domain/heat_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 11, 1);

  test('el primer día del celo es proestro, día 1', () {
    final p = currentHeatPhase(species: 'dog', start: start, now: DateTime(2026, 11, 1, 22));
    expect(p!.phase, HeatPhase.proestro);
    expect(p.dayOfHeat, 1);
  });

  test('del día 10 al 18 es estro', () {
    expect(currentHeatPhase(species: 'dog', start: start, now: DateTime(2026, 11, 9))!.phase, HeatPhase.proestro);
    expect(currentHeatPhase(species: 'dog', start: start, now: DateTime(2026, 11, 10))!.phase, HeatPhase.estro);
    expect(currentHeatPhase(species: 'dog', start: start, now: DateTime(2026, 11, 18))!.phase, HeatPhase.estro);
  });

  test('desde el día 19 es diestro', () {
    final p = currentHeatPhase(species: 'dog', start: start, now: DateTime(2026, 11, 19));
    expect(p!.phase, HeatPhase.diestro);
    expect(p.dayOfHeat, 19);
  });

  test('antes del inicio no hay etapa', () {
    expect(currentHeatPhase(species: 'dog', start: start, now: DateTime(2026, 10, 31)), isNull);
  });

  test('las gatas no tienen etapas', () {
    expect(currentHeatPhase(species: 'cat', start: start, now: DateTime(2026, 11, 2)), isNull);
  });
}
