import 'dart:math';

/// Estimación del próximo celo. Son fechas aproximadas, no un método anticonceptivo.
class HeatPrediction {
  const HeatPrediction({
    required this.earliest,
    required this.estimated,
    required this.latest,
    required this.windowDays,
  });

  /// Inicio del rango observado o esperado para la especie.
  final DateTime earliest;

  /// Fecha calculada del celo.
  final DateTime estimated;

  /// Fin del rango observado o esperado para la especie.
  final DateTime latest;

  /// Días antes y después de [estimated] que forman la ventana de seguridad.
  final int windowDays;

  DateTime get windowStart => _addDays(estimated, -windowDays);
  DateTime get windowEnd => _addDays(estimated, windowDays);
}

/// Calcula el próximo celo a partir de los inicios registrados.
///
/// - Sin historial: parte del tamaño de la perra (según [weightKg]) o del
///   valor por defecto de seis meses. La ventana es de ±14 días.
/// - Con un intervalo: promedia ese intervalo con el punto de partida.
/// - Con 2 o más intervalos: usa la mediana y una ventana de ±10 días.
/// - Gatas: valores fijos de 21 días, solo fuera de temporada devuelve null.
HeatPrediction? predictNextHeat({
  required String species,
  required List<DateTime> starts,
  required DateTime now,
  double? weightKg,
}) {
  if (starts.isEmpty) return null;
  if (species == 'cat' && !_inCatSeason(now)) return null;

  final sorted = [...starts]..sort();
  final last = sorted.last;

  final intervals = <int>[
    for (var i = 1; i < sorted.length; i++)
      sorted[i].difference(sorted[i - 1]).inDays,
  ];

  final int minDays;
  final int typicalDays;
  final int maxDays;
  final int windowDays;

  if (intervals.length >= 2) {
    minDays = intervals.reduce((a, b) => min(a, b));
    maxDays = intervals.reduce((a, b) => max(a, b));
    typicalDays = _median(intervals);
    windowDays = 10;
  } else if (species == 'cat') {
    minDays = 14;
    typicalDays = 21;
    maxDays = 21;
    windowDays = 14;
  } else {
    final prior = _dogPriorDays(weightKg);
    if (intervals.isEmpty) {
      // Perra sin historial: el punto de partida por tamaño, rango de 4 a 12 meses.
      minDays = 120;
      typicalDays = prior;
      maxDays = 365;
    } else {
      // Un solo intervalo real: se promedia con el punto de partida.
      final observed = intervals.single;
      minDays = min(prior, observed);
      maxDays = max(prior, observed);
      typicalDays = ((prior + observed) / 2).round();
    }
    windowDays = 14;
  }

  return HeatPrediction(
    earliest: _addDays(last, minDays),
    estimated: _addDays(last, typicalDays),
    latest: _addDays(last, maxDays),
    windowDays: windowDays,
  );
}

/// Punto de partida para perras sin historial, según su peso.
/// Pequeñas: cada 4 a 6 meses. Medianas y grandes: cada 6 a 8 meses.
int _dogPriorDays(double? weightKg) {
  if (weightKg == null) return 182;
  return weightKg < 10 ? 150 : 210;
}

DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

bool _inCatSeason(DateTime date) => date.month >= 2 && date.month <= 10;

int _median(List<int> values) {
  final s = [...values]..sort();
  final mid = s.length ~/ 2;
  if (s.length.isOdd) return s[mid];
  return (s[mid - 1] + s[mid]) ~/ 2;
}
