import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../domain/agenda.dart';
import '../../domain/formatting.dart';
import '../../theme.dart';
import '../agenda/agenda_providers.dart';
import '../settings/settings_screen.dart';
import 'add_pet_screen.dart';
import 'pet_avatar.dart';
import 'pet_detail_screen.dart';
import 'pet_mascot.dart';
import 'pets_providers.dart';

class PetsScreen extends ConsumerStatefulWidget {
  const PetsScreen({super.key});

  @override
  ConsumerState<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends ConsumerState<PetsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver a la app se recalcula «Hoy», por si cambió el día.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(agendaProvider);
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider);
    final agenda = ref.watch(agendaProvider).valueOrNull ?? const <AgendaItem>[];

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
                      if (list.isNotEmpty) _HoySection(items: agenda),
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
                      leading: PetAvatar(
                          photoPath: pet.photoPath,
                          species: pet.species,
                          size: 48),
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

/// Cuidados de hoy y mañana. Al tocar una fila se abre el registro exacto.
class _HoySection extends ConsumerWidget {
  const _HoySection({required this.items});

  final List<AgendaItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 24, 4, 6),
          child: Text('Hoy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text('Sin recordatorios para hoy ni mañana'),
          )
        else
          Card(
            child: Column(
              children: [
                for (final item in items)
                  ListTile(
                    leading: PetAvatar(
                        photoPath: item.photoPath,
                        species: item.species,
                        size: 40),
                    title: Text(item.title),
                    subtitle: Text(fmtDate(item.day)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _abrir(context, ref, item),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _abrir(BuildContext context, WidgetRef ref, AgendaItem item) async {
    final db = ref.read(databaseProvider);
    if (item.eventId != null) {
      // Si el registro se borró con la portada abierta, avisa y no navega.
      final existe = await (db.select(db.events)
            ..where((t) => t.id.equals(item.eventId!)))
          .getSingleOrNull();
      if (existe == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ese registro ya no existe.')),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PetDetailScreen(
        petId: item.petId,
        initialTab: item.isHeat ? PetTab.celo : PetTab.salud,
        highlightEventId: item.eventId,
      ),
    ));
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
