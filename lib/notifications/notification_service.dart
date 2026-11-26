import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';
import '../data/settings.dart';
import '../domain/reminders.dart';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

/// Prepara las zonas horarias y el plugin. Llamar una vez al iniciar la app.
Future<void> initNotifications() async {
  tzdata.initializeTimeZones();
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await _plugin.initialize(settings);
}

/// Pide permiso de notificaciones (Android 13 en adelante).
Future<void> requestNotificationPermission() async {
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
}

/// Borra todos los recordatorios programados y los vuelve a crear desde la base de datos.
/// Llamar después de cualquier cambio en mascotas, celos, eventos o configuración.
Future<void> syncReminders(AppDatabase db) async {
  final hour = await getReminderHour();
  final pets = await db.select(db.pets).get();
  final cycles = await db.select(db.heatCycles).get();
  final events = await (db.select(db.events)
        ..where((e) => e.nextDate.isNotNull()))
      .get();

  final petById = {for (final p in pets) p.id: p};

  final heatStarts = <int, List<DateTime>>{};
  final latestByPet = <int, HeatCycle>{};
  for (final c in cycles) {
    heatStarts.putIfAbsent(c.petId, () => <DateTime>[]).add(c.startDate);
    final current = latestByPet[c.petId];
    if (current == null || c.startDate.isAfter(current.startDate)) {
      latestByPet[c.petId] = c;
    }
  }
  final openCycle = <int, bool>{
    for (final entry in latestByPet.entries) entry.key: entry.value.endDate == null,
  };

  final eventInfos = <EventInfo>[];
  for (final e in events) {
    final pet = petById[e.petId];
    final next = e.nextDate;
    if (pet == null || next == null) continue;
    eventInfos.add(EventInfo(
      id: e.id,
      petId: e.petId,
      petName: pet.name,
      type: e.type,
      nextDate: next,
    ));
  }

  final specs = buildReminders(
    pets: [
      for (final p in pets)
        PetInfo(
          id: p.id,
          name: p.name,
          species: p.species,
          sex: p.sex,
          neutered: p.neutered,
        ),
    ],
    heatStarts: heatStarts,
    openCycle: openCycle,
    events: eventInfos,
    now: DateTime.now(),
    hour: hour,
  );

  await _plugin.cancelAll();

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'recordatorios',
      'Recordatorios',
      channelDescription: 'Celo, vacunas y citas',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  final utc = tz.getLocation('UTC');
  for (final s in specs) {
    await _plugin.zonedSchedule(
      s.id,
      s.title,
      s.body,
      tz.TZDateTime.from(s.when, utc),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
