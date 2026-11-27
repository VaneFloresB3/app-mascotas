import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/database_connection.dart';
import 'features/pets/pets_screen.dart';
import 'notifications/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // La app se muestra primero. Las notificaciones se preparan en segundo plano,
  // así un problema con ellas nunca deja la pantalla de arranque congelada.
  runApp(const ProviderScope(child: AppMascotas()));
  unawaited(_iniciarNotificaciones());
}

Future<void> _iniciarNotificaciones() async {
  try {
    await initNotifications();
    await requestNotificationPermission();

    // Reconstruye los recordatorios al abrir la app.
    final db = AppDatabase(openConnection());
    await syncReminders(db);
    await db.close();
  } catch (error, stack) {
    debugPrint('Error al preparar notificaciones: $error\n$stack');
  }
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
