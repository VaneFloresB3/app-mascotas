import 'event_types.dart';
import 'heat_calendar.dart';
import 'heat_prediction.dart';

/// Datos de una mascota necesarios para calcular recordatorios.
class PetInfo {
  const PetInfo({
    required this.id,
    required this.name,
    required this.species,
    required this.sex,
    required this.neutered,
  });

  final int id;
  final String name;
  final String species;
  final String sex;
  final bool neutered;
}

/// Evento con próxima fecha.
class EventInfo {
  const EventInfo({
    required this.id,
    required this.petId,
    required this.petName,
    required this.type,
    required this.nextDate,
  });

  final int id;
  final int petId;
  final String petName;
  final String type;
  final DateTime nextDate;
}

class ReminderSpec {
  const ReminderSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
  });

  final int id;
  final String title;
  final String body;
  final DateTime when;
}

/// IDs estables para poder cancelar y reprogramar sin duplicados.
int _id(int petId, int kind, int sub) => petId * 1000000 + kind * 100000 + sub;

/// Calcula todos los recordatorios futuros.
///
/// - Celo: aviso 7 días antes del estimado, el día estimado, inicio de la
///   ventana fértil (perras) y recordatorios diarios durante un celo en curso.
/// - Eventos con próxima fecha: aviso el día anterior a la hora elegida.
List<ReminderSpec> buildReminders({
  required List<PetInfo> pets,
  required Map<int, List<DateTime>> heatStarts,
  required Map<int, bool> openCycle,
  required List<EventInfo> events,
  required DateTime now,
  required int hour,
}) {
  final out = <ReminderSpec>[];

  void add(int id, String title, String body, DateTime when) {
    if (when.isAfter(now)) {
      out.add(ReminderSpec(id: id, title: title, body: body, when: when));
    }
  }

  DateTime at(DateTime day) => DateTime(day.year, day.month, day.day, hour);

  for (final pet in pets) {
    final isCelo = pet.sex == 'female' &&
        !pet.neutered &&
        (pet.species == 'dog' || pet.species == 'cat');
    if (!isCelo) continue;

    final starts = heatStarts[pet.id] ?? const <DateTime>[];
    final prediction = predictNextHeat(
      species: pet.species,
      starts: starts,
      now: now,
    );

    if (prediction != null) {
      final est = dayOnly(prediction.estimated);
      add(
        _id(pet.id, 1, 0),
        'Próximo celo de ${pet.name}',
        'Se acerca el celo estimado. Revisa su plan de cuidado.',
        at(DateTime(est.year, est.month, est.day - 7)),
      );
      add(
        _id(pet.id, 2, 0),
        'Celo estimado de ${pet.name}',
        'Hoy es la fecha estimada del celo. Mantenla separada de machos.',
        at(est),
      );
    }

    if (pet.species == 'dog' && starts.isNotEmpty) {
      final last = dayOnly(starts.reduce((a, b) => a.isAfter(b) ? a : b));
      add(
        _id(pet.id, 3, 0),
        'Ventana fértil de ${pet.name}',
        'Inicia la ventana fértil estimada. Mantenla separada de machos.',
        at(DateTime(last.year, last.month, last.day + 9)),
      );
    }

    if (openCycle[pet.id] == true) {
      final today = dayOnly(now);
      for (var i = 0; i < 7; i++) {
        final day = DateTime(today.year, today.month, today.day + i);
        add(
          _id(pet.id, 4, i),
          'Celo en curso: ${pet.name}',
          'Revisa signos y mantenla separada de machos.',
          at(day),
        );
      }
    }
  }

  for (final e in events) {
    final next = dayOnly(e.nextDate);
    final label = eventTypeLabels[e.type] ?? e.type;
    add(
      _id(e.petId, 5, e.id % 100000),
      'Mañana: $label de ${e.petName}',
      'Revisa el registro y agenda si hace falta.',
      DateTime(next.year, next.month, next.day - 1, hour),
    );
  }

  return out;
}
