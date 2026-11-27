import 'event_types.dart';
import 'heat_calendar.dart';
import 'heat_prediction.dart';

/// Datos de una mascota necesarios para la sección «Hoy».
class AgendaPet {
  const AgendaPet({
    required this.id,
    required this.name,
    required this.species,
    required this.sex,
    required this.neutered,
    this.photoPath,
  });

  final int id;
  final String name;
  final String species;
  final String sex;
  final bool neutered;
  final String? photoPath;
}

/// Evento con próxima fecha.
class AgendaEvent {
  const AgendaEvent({
    required this.id,
    required this.petId,
    required this.type,
    required this.nextDate,
  });

  final int id;
  final int petId;
  final String type;
  final DateTime nextDate;
}

/// Una fila de la sección «Hoy».
class AgendaItem {
  const AgendaItem({
    required this.petId,
    required this.petName,
    required this.species,
    required this.photoPath,
    required this.label,
    required this.day,
    required this.isToday,
    this.eventId,
    this.isHeat = false,
  });

  final int petId;
  final String petName;
  final String species;
  final String? photoPath;

  /// Nombre corto del cuidado, por ejemplo «Vacuna» o «Celo estimado».
  final String label;

  /// Fecha del cuidado (no la del aviso).
  final DateTime day;
  final bool isToday;

  /// Identificador del evento, si el aviso viene de un evento.
  final int? eventId;
  final bool isHeat;

  String get title => '$petName · $label ${isToday ? 'hoy' : 'mañana'}';
}

/// Nombres cortos para la portada. Los demás tipos usan su nombre completo.
const _agendaLabels = <String, String>{
  'vacuna': 'Vacuna',
  'desparasitante': 'Antiparasitario',
  'medicina': 'Medicina',
  'visita': 'Cita veterinaria',
};

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Calcula los cuidados de hoy y de mañana.
///
/// Usa las mismas reglas que los recordatorios: próxima fecha de los eventos
/// y estimación de celo solo para hembras no esterilizadas. Los de hoy van
/// primero, luego los de mañana, y dentro de cada grupo por nombre.
List<AgendaItem> buildAgenda({
  required List<AgendaPet> pets,
  required List<AgendaEvent> events,
  required Map<int, List<DateTime>> heatStarts,
  required DateTime now,
}) {
  final today = dayOnly(now);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final petById = {for (final p in pets) p.id: p};
  final out = <AgendaItem>[];

  bool inWindow(DateTime day) => _sameDay(day, today) || _sameDay(day, tomorrow);

  for (final e in events) {
    final pet = petById[e.petId];
    if (pet == null) continue;
    final day = dayOnly(e.nextDate);
    if (!inWindow(day)) continue;
    out.add(AgendaItem(
      petId: pet.id,
      petName: pet.name,
      species: pet.species,
      photoPath: pet.photoPath,
      label: _agendaLabels[e.type] ?? eventTypeLabels[e.type] ?? e.type,
      day: day,
      isToday: _sameDay(day, today),
      eventId: e.id,
    ));
  }

  for (final pet in pets) {
    final isCelo = pet.sex == 'female' &&
        !pet.neutered &&
        (pet.species == 'dog' || pet.species == 'cat');
    if (!isCelo) continue;
    final prediction = predictNextHeat(
      species: pet.species,
      starts: heatStarts[pet.id] ?? const <DateTime>[],
      now: now,
    );
    if (prediction == null) continue;
    final day = dayOnly(prediction.estimated);
    if (!inWindow(day)) continue;
    out.add(AgendaItem(
      petId: pet.id,
      petName: pet.name,
      species: pet.species,
      photoPath: pet.photoPath,
      label: 'Celo estimado',
      day: day,
      isToday: _sameDay(day, today),
      isHeat: true,
    ));
  }

  out.sort((a, b) {
    if (a.isToday != b.isToday) return a.isToday ? -1 : 1;
    final byName = a.petName.compareTo(b.petName);
    return byName != 0 ? byName : a.label.compareTo(b.label);
  });
  return out;
}
