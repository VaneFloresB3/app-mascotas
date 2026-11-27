import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Carpeta privada de KoinuCare dentro de los documentos de la app.
const _folderName = 'koinucare_fotos';

/// Lado más largo de la copia guardada. Basta para la ficha y la portada.
const _maxSide = 512;

/// Copia la foto elegida a la carpeta privada y devuelve su ruta relativa.
///
/// La imagen se gira según su orientación, se reduce y se guarda como JPG.
/// El nombre es único, así dos fotos con el mismo nombre no se pisan.
Future<String> savePetPhoto(String sourcePath) async {
  final bytes = await File(sourcePath).readAsBytes();
  final jpg = await compute(_processImage, bytes);

  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, _folderName));
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final name =
      '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}.jpg';
  await File(p.join(dir.path, name)).writeAsBytes(jpg, flush: true);
  return '$_folderName/$name';
}

/// Devuelve el archivo de la foto, o null si no hay ruta o el archivo falta.
Future<File?> petPhotoFile(String? relativePath) async {
  if (relativePath == null) return null;
  final docs = await getApplicationDocumentsDirectory();
  final file = File(p.join(docs.path, relativePath));
  return file.existsSync() ? file : null;
}

/// Borra la copia privada de una foto. No hace nada si no existe.
Future<void> deletePetPhoto(String? relativePath) async {
  final file = await petPhotoFile(relativePath);
  if (file != null) await file.delete();
}

Uint8List _processImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('La imagen no se pudo leer.');
  }
  final upright = img.bakeOrientation(decoded);
  final longest = max(upright.width, upright.height);
  final scale = longest > _maxSide ? _maxSide / longest : 1.0;
  final resized = scale < 1
      ? img.copyResize(
          upright,
          width: (upright.width * scale).round(),
          height: (upright.height * scale).round(),
        )
      : upright;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
