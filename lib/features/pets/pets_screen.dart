import 'pet_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme.dart';
import '../settings/settings_screen.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';
import 'pets_providers.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider);
    void addPet() => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddPetScreen()));
    return Scaffold(
      appBar: AppBar(title: const Text('KoinuCare'), actions: [
        IconButton.filledTonal(
            tooltip: 'Configuración',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        const SizedBox(width: 12),
      ]),
      body: pets.when(
        data: (list) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            itemCount: list.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                          constraints: list.isEmpty
                              ? BoxConstraints(
                                  minHeight:
                                      MediaQuery.sizeOf(context).height * .78)
                              : null,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                              color: peach,
                              borderRadius: BorderRadius.circular(30)),
                          child: CustomPaint(
                              painter: const _Meadow(),
                              child: Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        PetMascot(
                                            species: list.isEmpty
                                                ? 'dog'
                                                : list.first.species,
                                            size: list.isEmpty ? 160 : 96),
                                        const SizedBox(height: 16),
                                        Text(
                                            list.isEmpty
                                                ? 'Tu primera mascota'
                                                : 'Mis mascotas',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 29,
                                                fontWeight: FontWeight.w800,
                                                color: ink)),
                                        const SizedBox(height: 7),
                                        Text(
                                            list.isEmpty
                                                ? 'Crea su ficha para llevar un diario de sus cuidados.'
                                                : 'Consulta su diario, su salud y su peso.',
                                            textAlign: TextAlign.center),
                                        const SizedBox(height: 18),
                                        FilledButton.icon(
                                            onPressed: addPet,
                                            icon:
                                                const Icon(Icons.pets_rounded),
                                            label:
                                                const Text('Agregar mascota')),
                                      ])))),
                      if (list.isNotEmpty)
                        const Padding(
                            padding: EdgeInsets.fromLTRB(4, 24, 4, 6),
                            child: Text('Fichas de mascotas',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold))),
                    ]);
              }
              final pet = list[i - 1];
              final dog = pet.species == 'dog';
              return Card(
                  child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: PetMascot(species: pet.species, size: 48),
                      title: Text(pet.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(dog ? 'Perro' : 'Gato'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PetDetailScreen(petId: pet.id)))));
            }),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _Meadow extends CustomPainter {
  const _Meadow();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
        Offset(w * .17, h * .16), 19, Paint()..color = const Color(0xFFFFEBC0));
    final hill = Path()
      ..moveTo(0, h * .66)
      ..cubicTo(w * .35, h * .44, w * .67, h * .86, w, h * .58)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFFFFE7CB));
    final grass = Path()
      ..moveTo(0, h * .91)
      ..quadraticBezierTo(w * .26, h * .72, w * .57, h * .95)
      ..quadraticBezierTo(w * .82, h * 1.03, w, h * .85)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(grass, Paint()..color = sage);
  }

  @override
  bool shouldRepaint(_Meadow oldDelegate) => false;
}
