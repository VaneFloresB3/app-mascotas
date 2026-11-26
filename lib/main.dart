import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/database_connection.dart';
import 'features/pets/pets_screen.dart';
import 'notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  await requestNotificationPermission();

  // Reconstruye los recordatorios al abrir la app.
  final db = AppDatabase(openConnection());
  await syncReminders(db);
  await db.close();

  runApp(const ProviderScope(child: AppMascotas()));
}

class AppMascotas extends StatelessWidget {
  const AppMascotas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App para mascotas',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4CAF7A),
        useMaterial3: true,
      ),
      home: const PetsScreen(),
    );
  }
}
