import 'package:shared_preferences/shared_preferences.dart';

const _reminderHourKey = 'reminder_hour';

/// Hora del día (0 a 23) en que llegan los recordatorios. Por defecto 19:00.
Future<int> getReminderHour() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_reminderHourKey) ?? 19;
}

Future<void> setReminderHour(int hour) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_reminderHourKey, hour);
}
