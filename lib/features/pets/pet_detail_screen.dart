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
import 'pet_avatar.dart';

/// Pestañas de la ficha. Se usa para abrir una pestaña concreta desde la portada.
enum PetTab { resumen, diario, salud, peso, celo }

class PetDetailScreen extends ConsumerWidget {
  const PetDetailScreen({
    super.key,
    required this.petId,
    this.initialTab = PetTab.resumen,
    this.highlightEventId,
  });

  final int petId;
  final PetTab initialTab;

  /// Registro de Salud que se destaca al abrir la ficha.
  final int? highlightEventId;

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

        final kinds = <PetTab>[
          PetTab.resumen,
          PetTab.diario,
          PetTab.salud,
          PetTab.peso,
          if (showCelo) PetTab.celo,
        ];

        final tabs = <Tab>[
          for (final k in kinds) Tab(text: _labelOf(k)),
        ];

        final views = <Widget>[
          for (final k in kinds) _viewOf(k, pet),
        ];

        final found = kinds.indexOf(initialTab);
        final initialIndex = found < 0 ? 0 : found;

        return DefaultTabController(
          length: tabs.length,
          initialIndex: initialIndex,
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

  String _labelOf(PetTab tab) => switch (tab) {
        PetTab.resumen => 'Resumen',
        PetTab.diario => 'Diario',
        PetTab.salud => 'Salud',
        PetTab.peso => 'Peso',
        PetTab.celo => 'Celo',
      };

  Widget _viewOf(PetTab tab, Pet pet) => switch (tab) {
        PetTab.resumen => _ResumenView(pet: pet),
        PetTab.diario => EventsTab(
            petId: pet.id,
            types: dailyTypes,
            emptyText: 'Registra orinal, comidas o paseos.',
          ),
        PetTab.salud => EventsTab(
            petId: pet.id,
            types: healthTypes,
            emptyText: 'Registra vacunas, citas o medicinas.',
            highlightEventId: highlightEventId,
          ),
        PetTab.peso => WeightTab(petId: pet.id),
        PetTab.celo => CeloTab(pet: pet),
      };
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
                      Row(children: [
                        PetAvatar(
                            photoPath: pet.photoPath,
                            species: pet.species,
                            size: 72),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text('Ficha de ${pet.name}',
                              style: Theme.of(context).textTheme.headlineSmall),
                        ),
                      ]),
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
