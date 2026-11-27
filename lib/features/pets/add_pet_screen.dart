import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/photo_storage.dart';
import 'pet_photo_field.dart';
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
  XFile? _photo;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    // Si cierra la galería sin elegir, se conserva la selección anterior.
    if (picked == null || !mounted) return;
    setState(() => _photo = picked);
  }

  void _removePhoto() => setState(() => _photo = null);

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre de la mascota')),
      );
      return;
    }

    setState(() => _saving = true);
    String? photoPath;
    try {
      if (_photo != null) photoPath = await savePetPhoto(_photo!.path);
      await addPet(
        ref.read(databaseProvider),
        name: name,
        species: _species,
        sex: _sex,
        neutered: _neutered,
        photoPath: photoPath,
      );
    } catch (_) {
      // Si falla el guardado, se borra la copia nueva y se puede reintentar.
      await deletePetPhoto(photoPath);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')),
        );
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva mascota')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PetPhotoField(
            name: _nameController.text,
            species: _species,
            savedPhoto: null,
            pendingPhoto: _photo,
            removed: false,
            onPick: _pickPhoto,
            onRemove: _removePhoto,
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
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
