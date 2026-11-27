import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'pet_avatar.dart';

/// Vista previa y botones para elegir, cambiar o quitar la foto de una mascota.
///
/// El padre guarda la selección pendiente: nada se copia hasta pulsar Guardar.
class PetPhotoField extends StatelessWidget {
  const PetPhotoField({
    super.key,
    required this.name,
    required this.species,
    required this.savedPhoto,
    required this.pendingPhoto,
    required this.removed,
    required this.onPick,
    required this.onRemove,
  });

  final String name;
  final String species;

  /// Ruta de la foto ya guardada en la ficha.
  final String? savedPhoto;

  /// Foto elegida en esta sesión, todavía sin guardar.
  final XFile? pendingPhoto;

  /// Verdadero si la persona quitó la foto y aún no guardó.
  final bool removed;

  final VoidCallback onPick;
  final VoidCallback onRemove;

  bool get _hasPhoto => pendingPhoto != null || (!removed && savedPhoto != null);

  @override
  Widget build(BuildContext context) {
    final who = name.trim().isEmpty ? 'la mascota' : name.trim();

    final Widget preview;
    if (pendingPhoto != null) {
      preview = _circle(Image.file(File(pendingPhoto!.path), fit: BoxFit.cover));
    } else if (removed) {
      preview = PetAvatar(photoPath: null, species: species, size: 112);
    } else {
      preview = PetAvatar(photoPath: savedPhoto, species: species, size: 112);
    }

    return Column(
      children: [
        Center(child: preview),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            Semantics(
              label: _hasPhoto ? 'Cambiar foto de $who' : 'Elegir foto de $who',
              button: true,
              child: FilledButton.tonalIcon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(_hasPhoto ? 'Cambiar foto' : 'Elegir foto'),
              ),
            ),
            if (_hasPhoto)
              Semantics(
                label: 'Quitar foto de $who',
                button: true,
                child: TextButton(
                  onPressed: onRemove,
                  child: const Text('Quitar foto'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _circle(Widget child) => ClipOval(
        child: SizedBox.square(dimension: 112, child: child),
      );
}
