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

/// Pestañas de la ficha. Se usa para abrir una sección concreta desde la portada.
enum PetTab { resumen, diario, salud, peso, celo }

/// Ficha de una mascota con navegación inferior:
/// Inicio, Celo, Carnet médico (salud y peso) y Diario.
class PetDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  static const _inicio = 0;
  static const _celo = 1;
  static const _carnet = 2;
  static const _diario = 3;

  int _index = _inicio;
  bool _carnetPeso = false;
  bool _initialized = false;

  int _destinoDe(PetTab tab) => switch (tab) {
        PetTab.resumen => _inicio,
        PetTab.celo => _celo,
        PetTab.salud => _carnet,
        PetTab.peso => _carnet,
        PetTab.diario => _diario,
      };

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petByIdProvider(widget.petId));

    return petAsync.when(
      data: (pet) {
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Mascota no encontrada')),
          );
        }

        if (!_initialized) {
          _initialized = true;
          _index = _destinoDe(widget.initialTab);
          _carnetPeso = widget.initialTab == PetTab.peso;
        }

        return Scaffold(
          appBar: AppBar(title: Text(pet.name)),
          body: IndexedStack(
            index: _index,
            children: [
              _ResumenView(pet: pet),
              _celoView(pet),
              _carnetView(pet),
              EventsTab(
                petId: pet.id,
                types: dailyTypes,
                emptyText: 'Registra orinal, comidas o paseos.',
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.water_drop_outlined),
                selectedIcon: Icon(Icons.water_drop),
                label: 'Celo',
              ),
              NavigationDestination(
                icon: Icon(Icons.medical_services_outlined),
                selectedIcon: Icon(Icons.medical_services),
                label: 'Carnet médico',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Diario',
              ),
            ],
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

  /// El celo solo aplica a hembras no esterilizadas.
  Widget _celoView(Pet pet) {
    if (pet.sex == 'female' && !pet.neutered) {
      return CeloTab(pet: pet);
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'El módulo de celo aplica a hembras no esterilizadas.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _carnetView(Pet pet) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Salud')),
              ButtonSegment(value: true, label: Text('Peso')),
            ],
            selected: {_carnetPeso},
            onSelectionChanged: (s) => setState(() => _carnetPeso = s.first),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _carnetPeso ? 1 : 0,
            children: [
              EventsTab(
                petId: pet.id,
                types: healthTypes,
                emptyText: 'Registra vacunas, citas o medicinas.',
                highlightEventId: widget.highlightEventId,
              ),
              WeightTab(petId: pet.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumenView extends ConsumerWidget {
  const _ResumenView({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weights = ref.watch(weightsProvider(pet.id)).valueOrNull ?? const <Weight>[];
    final last = weights.isEmpty
        ? null
        : weights.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

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
                Text('Especie: ${pet.species == 'dog' ? 'Perro' : 'Gato'}'),
                Text('Sexo: ${pet.sex == 'female' ? 'Hembra' : 'Macho'}'),
                Text('Esterilizada: ${pet.neutered ? 'Sí' : 'No'}'),
                if (pet.birthDate != null) ...[
                  Text('Nacimiento: ${fmtDate(pet.birthDate!)}'),
                  Text('Edad: ${_edad(pet.birthDate!, DateTime.now())}'),
                ],
                if (last != null)
                  Text(
                    'Último peso: ${last.kg.toStringAsFixed(1)} kg '
                    '(${fmtDate(last.date)})',
                  ),
              ],
            ),
          ),
        ),
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

  String _edad(DateTime nacimiento, DateTime hoy) {
    var meses =
        (hoy.year - nacimiento.year) * 12 + (hoy.month - nacimiento.month);
    if (hoy.day < nacimiento.day) meses--;
    if (meses < 0) meses = 0;
    final anios = meses ~/ 12;
    final resto = meses % 12;
    final mesesTxt = '$resto ${resto == 1 ? 'mes' : 'meses'}';
    if (anios == 0) return mesesTxt;
    final aniosTxt = '$anios ${anios == 1 ? 'año' : 'años'}';
    return resto == 0 ? aniosTxt : '$aniosTxt y $mesesTxt';
  }
}
