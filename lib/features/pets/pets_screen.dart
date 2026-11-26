import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_pet_screen.dart';
import '../settings/settings_screen.dart';
import 'pet_detail_screen.dart';
import 'pets_providers.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis mascotas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: pets.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Agrega tu primera mascota'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final pet = list[i];
              return ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PetDetailScreen(petId: pet.id),
                  ),
                ),
                leading: CircleAvatar(
                  child: Text(pet.species == 'dog' ? '🐶' : '🐱'),
                ),
                title: Text(pet.name),
                subtitle: Text(pet.species == 'dog' ? 'Perro' : 'Gato'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddPetScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
