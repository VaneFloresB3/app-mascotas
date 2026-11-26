import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../notifications/notification_service.dart';
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre de la mascota')),
      );
      return;
    }
    final db = ref.read(databaseProvider);
    await (db.update(db.pets)..where((t) => t.id.equals(widget.pet.id))).write(
      PetsCompanion(
        name: Value(name),
        neutered: Value(_neutered),
      ),
    );
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
          FilledButton(onPressed: _save, child: const Text('Guardar')),
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
