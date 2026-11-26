import 'package:app_mascotas/domain/heat_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el sangrado incluye el día de inicio y el de fin', () {
    final days = bleedingDays(DateTime(2026, 3, 1), DateTime(2026, 3, 3));
    expect(days.length, 3);
    expect(days.contains(DateTime(2026, 3, 1)), isTrue);
    expect(days.contains(DateTime(2026, 3, 3)), isTrue);
  });

  test('un celo sin fin solo marca el día de inicio', () {
    final days = bleedingDays(DateTime(2026, 3, 1), null);
    expect(days, {DateTime(2026, 3, 1)});
  });

  test('ventana fértil de perra va del día 9 al 14', () {
    final f = fertileDaysDog(DateTime(2026, 3, 1));
    expect(f.length, 6);
    expect(f.contains(DateTime(2026, 3, 10)), isTrue);
    expect(f.contains(DateTime(2026, 3, 15)), isTrue);
    expect(f.contains(DateTime(2026, 3, 16)), isFalse);
  });
}
