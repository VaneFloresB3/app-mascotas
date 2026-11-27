import 'heat_calendar.dart';

/// Etapas aproximadas del celo de una perra.
enum HeatPhase { proestro, estro, diestro }

/// Etapa actual con un consejo de cuidado para esa semana.
class HeatPhaseInfo {
  const HeatPhaseInfo({
    required this.phase,
    required this.dayOfHeat,
    required this.title,
    required this.tip,
  });

  final HeatPhase phase;

  /// Día del celo, contando el primero como día 1.
  final int dayOfHeat;

  final String title;
  final String tip;
}

/// Etapa del celo en curso, o null si no aplica.
///
/// Solo se modelan las perras. Las gatas no siguen estas etapas: son
/// ovuladoras inducidas y no tienen un sangrado con fases fijas.
HeatPhaseInfo? currentHeatPhase({
  required String species,
  required DateTime start,
  required DateTime now,
}) {
  if (species != 'dog') return null;
  final day = dayOnly(now).difference(dayOnly(start)).inDays + 1;
  if (day < 1) return null;

  if (day <= 9) {
    return HeatPhaseInfo(
      phase: HeatPhase.proestro,
      dayOfHeat: day,
      title: 'Proestro',
      tip: 'Puede sangrar y atraer a machos. Cambia sus protectores con '
          'frecuencia y mantenla separada de machos.',
    );
  }
  if (day <= 18) {
    return HeatPhaseInfo(
      phase: HeatPhase.estro,
      dayOfHeat: day,
      title: 'Estro (etapa fértil)',
      tip: 'Es la etapa fértil. Mantenla separada de machos sin excepción.',
    );
  }
  return HeatPhaseInfo(
    phase: HeatPhase.diestro,
    dayOfHeat: day,
    title: 'Diestro',
    tip: 'Su cuerpo vuelve a la normalidad. Observa su apetito y su ánimo, '
        'y consulta a tu veterinario si notas algo raro.',
  );
}
