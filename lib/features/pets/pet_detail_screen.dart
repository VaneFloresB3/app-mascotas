import 'pet_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../domain/event_types.dart';
import '../../domain/formatting.dart';
import '../celo/celo_providers.dart';
import '../celo/celo_tab.dart';
import '../eventos/events_tab.dart';
import '../peso/weight_tab.dart';
import 'edit_pet_screen.dart';

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

        final tabs = <Tab>[
          const Tab(text: 'Resumen'),
          const Tab(text: 'Diario'),
          const Tab(text: 'Salud'),
          const Tab(text: 'Peso'),
          if (showCelo) const Tab(text: 'Celo'),
        ];

        final views = <Widget>[
          _ResumenView(pet: pet),
          EventsTab(
            petId: pet.id,
            species: pet.species,
            types: dailyTypes,
            emptyText: 'Registra orinal, comidas o paseos.',
          ),
          EventsTab(
            petId: pet.id,
            species: pet.species,
            types: healthTypes,
            emptyText: 'Registra vacunas, citas o medicinas.',
          ),
          WeightTab(petId: pet.id, species: pet.species),
          if (showCelo) CeloTab(pet: pet),
        ];

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(pet.name),
              bottom: TabBar(isScrollable: true, tabs: tabs),
            ),
            body: TabBarView(children: views),
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

class _ResumenView extends StatelessWidget {
  const _ResumenView({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PetMascot(species: pet.species, size: 96),
                      const SizedBox(height: 8),
                      Text('Ficha de ' + pet.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Text(
                          'Especie: ${pet.species == 'dog' ? 'Perro' : 'Gato'}'),
                      Text('Sexo: ${pet.sex == 'female' ? 'Hembra' : 'Macho'}'),
                      Text('Esterilizada: ${pet.neutered ? 'Sí' : 'No'}'),
                      if (pet.birthDate != null)
                        Text('Nacimiento: ${fmtDate(pet.birthDate!)}'),
                    ]))),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EditPetScreen(pet: pet)),
          ),
          icon: const Icon(Icons.edit),
          label: const Text('Editar mascota'),
        ),
      ],
    );
  }
}
