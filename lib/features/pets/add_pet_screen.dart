import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pets_providers.dart';

class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _nameController = TextEditingController();
  String _species = 'dog';
  String _sex = 'female';
  bool _neutered = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre de la mascota')),
      );
      return;
    }

    setState(() => _saving = true);
    await addPet(
      ref.read(databaseProvider),
      name: name,
      species: _species,
      sex: _sex,
      neutered: _neutered,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva mascota')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _species,
            decoration: const InputDecoration(labelText: 'Especie'),
            items: const [
              DropdownMenuItem(value: 'dog', child: Text('Perro')),
              DropdownMenuItem(value: 'cat', child: Text('Gato')),
            ],
            onChanged: (v) => setState(() => _species = v ?? 'dog'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _sex,
            decoration: const InputDecoration(labelText: 'Sexo'),
            items: const [
              DropdownMenuItem(value: 'female', child: Text('Hembra')),
              DropdownMenuItem(value: 'male', child: Text('Macho')),
            ],
            onChanged: (v) => setState(() => _sex = v ?? 'female'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Esterilizada'),
            value: _neutered,
            onChanged: (v) => setState(() => _neutered = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
