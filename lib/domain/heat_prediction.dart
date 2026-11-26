/// Estimación del próximo celo. Son fechas aproximadas, no un método anticonceptivo.
class HeatPrediction {
  const HeatPrediction({
    required this.earliest,
    required this.estimated,
    required this.latest,
  });

  final DateTime earliest;
  final DateTime estimated;
  final DateTime latest;
}

/// Calcula el próximo celo a partir de los inicios registrados.
///
/// - Sin historial suficiente (menos de 2 intervalos): usa valores por defecto
///   según la especie.
/// - Con 2 o más intervalos: usa la mediana y el rango observado.
/// - Gatas fuera de temporada (fuera de febrero a octubre): devuelve null.
HeatPrediction? predictNextHeat({
  required String species,
  required List<DateTime> starts,
  required DateTime now,
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

  if (intervals.length >= 2) {
    minDays = intervals.reduce((a, b) => a < b ? a : b);
    maxDays = intervals.reduce((a, b) => a > b ? a : b);
    typicalDays = _median(intervals);
  } else if (species == 'cat') {
    minDays = 14;
    typicalDays = 21;
    maxDays = 21;
  } else {
    // Perra: alrededor de seis meses, con rango de 4 a 12 meses.
    minDays = 120;
    typicalDays = 182;
    maxDays = 365;
  }

  return HeatPrediction(
    earliest: last.add(Duration(days: minDays)),
    estimated: last.add(Duration(days: typicalDays)),
    latest: last.add(Duration(days: maxDays)),
  );
}

bool _inCatSeason(DateTime date) => date.month >= 2 && date.month <= 10;

int _median(List<int> values) {
  final s = [...values]..sort();
  final mid = s.length ~/ 2;
  if (s.length.isOdd) return s[mid];
  return (s[mid - 1] + s[mid]) ~/ 2;
}
