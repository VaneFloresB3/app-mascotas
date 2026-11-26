import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/pets/pets_screen.dart';

void main() {
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
