import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/database.dart';
import '../../data/photo_storage.dart';
import '../../notifications/notification_service.dart';
import 'pet_photo_field.dart';
import 'pets_providers.dart';

class EditPetScreen extends ConsumerStatefulWidget {
  const EditPetScreen({super.key, required this.pet});

  final Pet pet;

  @override
  ConsumerState<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends ConsumerState<EditPetScreen> {
  late final TextEditingController _nameController;
  late bool _neutered;
  bool _saving = false;

  // Cambios pendientes de foto. Nada se copia hasta pulsar Guardar.
  XFile? _newPhoto;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    _neutered = widget.pet.neutered;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    // Si cierra la galería sin elegir, se conserva la selección anterior.
    if (picked == null || !mounted) return;
    setState(() {
      _newPhoto = picked;
      _removePhoto = false;
    });
  }

  void _quitarFoto() => setState(() {
        _newPhoto = null;
        _removePhoto = true;
      });

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre de la mascota')),
      );
      return;
    }

    setState(() => _saving = true);
    final oldPhoto = widget.pet.photoPath;
    // Por defecto se conserva la foto actual.
    String? newPhoto = oldPhoto;
    String? copiedNow;
    final db = ref.read(databaseProvider);

    try {
      // Primero se copia la foto nueva, luego se guarda su ruta.
      if (_newPhoto != null) {
        copiedNow = await savePetPhoto(_newPhoto!.path);
        newPhoto = copiedNow;
      } else if (_removePhoto) {
        newPhoto = null;
      }

      await (db.update(db.pets)..where((t) => t.id.equals(widget.pet.id)))
          .write(
        PetsCompanion(
          name: Value(name),
          neutered: Value(_neutered),
          photoPath: Value(newPhoto),
        ),
      );
    } catch (_) {
      // Si falla, la foto anterior se mantiene y se puede reintentar.
      await deletePetPhoto(copiedNow);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')),
        );
      }
      return;
    }

    // Al guardar bien, se borra la copia anterior si cambió.
    if (oldPhoto != null && oldPhoto != newPhoto) {
      await deletePetPhoto(oldPhoto);
    }
    await syncReminders(db);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: const Text(
          'Se borrarán también sus celos, eventos y pesos. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final db = ref.read(databaseProvider);
    await (db.delete(db.pets)..where((t) => t.id.equals(widget.pet.id))).go();
    await deletePetPhoto(widget.pet.photoPath);
    await syncReminders(db);
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar mascota')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PetPhotoField(
            name: widget.pet.name,
            species: widget.pet.species,
            savedPhoto: widget.pet.photoPath,
            pendingPhoto: _newPhoto,
            removed: _removePhoto,
            onPick: _pickPhoto,
            onRemove: _quitarFoto,
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.words,
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
          const SizedBox(height: 16),
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar mascota'),
          ),
        ],
      ),
    );
  }
}
