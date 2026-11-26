/// Fecha sin hora, para comparar días en el calendario.
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Días con sangrado, desde el inicio hasta el fin (o solo el inicio si no hay fin).
Set<DateTime> bleedingDays(DateTime start, DateTime? end) {
  final last = dayOnly(end ?? start);
  final result = <DateTime>{};
  for (var d = dayOnly(start); !d.isAfter(last); d = DateTime(d.year, d.month, d.day + 1)) {
    result.add(d);
  }
  return result;
}

/// Ventana fértil estimada en perras: del día 9 al 14 desde el inicio del celo.
/// Es una aproximación; la prueba de progesterona con el veterinario es la referencia.
Set<DateTime> fertileDaysDog(DateTime start) {
  final s = dayOnly(start);
  return {
    for (var i = 9; i <= 14; i++) DateTime(s.year, s.month, s.day + i),
  };
}
