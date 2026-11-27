import 'package:app_mascotas/domain/heat_prediction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final last = DateTime(2026, 1, 1);
  final now = DateTime(2026, 1, 10);

  test('perrita pequeña sin historial parte de unos 5 meses', () {
    final p = predictNextHeat(species: 'dog', starts: [last], now: now, weightKg: 6);
    expect(p!.estimated, last.add(const Duration(days: 150)));
    expect(p.windowDays, 14);
  });

  test('perra mediana o grande parte de unos 7 meses', () {
    final p = predictNextHeat(species: 'dog', starts: [last], now: now, weightKg: 22);
    expect(p!.estimated, last.add(const Duration(days: 210)));
  });

  test('con un solo intervalo real promedia con el punto de partida', () {
    // Partida pequeña (150) y un intervalo real de 200: promedio 175.
    final second = last.add(const Duration(days: 200));
    final p = predictNextHeat(
      species: 'dog',
      starts: [last, second],
      now: now,
      weightKg: 6,
    );
    expect(p!.estimated, second.add(const Duration(days: 175)));
  });

  test('con dos o más intervalos la ventana es de ±10 días', () {
    final a = DateTime(2026, 1, 1);
    final b = a.add(const Duration(days: 180));
    final c = b.add(const Duration(days: 180));
    final p = predictNextHeat(species: 'dog', starts: [a, b, c], now: DateTime(2026, 8, 1));
    expect(p!.windowDays, 10);
    expect(p.windowStart, p.estimated.subtract(const Duration(days: 10)));
    expect(p.windowEnd, p.estimated.add(const Duration(days: 10)));
  });
}
