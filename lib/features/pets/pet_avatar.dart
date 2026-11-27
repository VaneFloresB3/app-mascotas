import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'pet_mascot.dart';

/// Carpeta de documentos, se pide una sola vez.
final _docsDirProvider = FutureProvider<String>((ref) async {
  return (await getApplicationDocumentsDirectory()).path;
});

/// Foto de la mascota en círculo. Si no hay foto, o el archivo falta o está
/// dañado, muestra la ilustración de su especie.
class PetAvatar extends ConsumerWidget {
  const PetAvatar({
    super.key,
    required this.photoPath,
    required this.species,
    required this.size,
  });

  final String? photoPath;
  final String species;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final illustration = PetMascot(species: species, size: size);
    final docs = ref.watch(_docsDirProvider).valueOrNull;
    if (photoPath == null || docs == null) return illustration;

    final file = File(p.join(docs, photoPath!));
    if (!file.existsSync()) return illustration;

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => illustration,
        ),
      ),
    );
  }
}
