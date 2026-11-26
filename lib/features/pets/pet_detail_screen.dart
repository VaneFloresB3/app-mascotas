import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../celo/celo_providers.dart';
import '../celo/celo_tab.dart';

class PetDetailScreen extends ConsumerWidget {
  const PetDetailScreen({super.key, required this.petId});

  final int petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petByIdProvider(petId));

    return petAsync.when(
      data: (pet) {
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Mascota no encontrada')),
          );
        }

        // El celo solo aplica a hembras no esterilizadas.
        final showCelo = pet.sex == 'female' && !pet.neutered;

        return DefaultTabController(
          length: showCelo ? 2 : 1,
          child: Scaffold(
            appBar: AppBar(
              title: Text(pet.name),
              bottom: TabBar(
                tabs: [
                  const Tab(text: 'Resumen'),
                  if (showCelo) const Tab(text: 'Celo'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Especie: ${pet.species == 'dog' ? 'Perro' : 'Gato'}'),
                    Text('Sexo: ${pet.sex == 'female' ? 'Hembra' : 'Macho'}'),
                    Text(
                      'Esterilizada: ${pet.neutered ? 'Sí' : 'No'}',
                    ),
                    const SizedBox(height: 24),
                    const Text('Más secciones próximamente.'),
                  ],
                ),
                if (showCelo) CeloTab(pet: pet),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
