import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/database.dart';
import '../../domain/heat_calendar.dart';
import '../../domain/heat_prediction.dart';
import '../../notifications/notification_service.dart';
import '../pets/pets_providers.dart';
import 'celo_providers.dart';
import 'heat_form_screen.dart';

class CeloTab extends ConsumerStatefulWidget {
  const CeloTab({super.key, required this.pet});

  final Pet pet;

  @override
  ConsumerState<CeloTab> createState() => _CeloTabState();
}

class _CeloTabState extends ConsumerState<CeloTab> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(heatCyclesProvider(widget.pet.id));
    return cyclesAsync.when(
      data: (cycles) => _content(cycles),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _content(List<HeatCycle> cycles) {
    final starts = cycles.map((c) => dayOnly(c.startDate)).toList();
    final prediction = predictNextHeat(
      species: widget.pet.species,
      starts: starts,
      now: DateTime.now(),
    );

    final bleeding = <DateTime>{};
    final fertile = <DateTime>{};
    for (final c in cycles) {
      bleeding.addAll(bleedingDays(c.startDate, c.endDate));
      if (widget.pet.species == 'dog') {
        fertile.addAll(fertileDaysDog(c.startDate));
      }
    }
    final estimated = prediction == null ? null : dayOnly(prediction.estimated);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _disclaimer(),
        const SizedBox(height: 12),
        _predictionCard(prediction, starts.isEmpty),
        const SizedBox(height: 12),
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2035, 12, 31),
          focusedDay: _focused,
          selectedDayPredicate: (day) => isSameDay(_selected, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selected = selected;
              _focused = focused;
            });
          },
          onPageChanged: (focused) {
            _focused = focused;
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focused) =>
                _dayCell(day, bleeding, fertile, estimated),
            todayBuilder: (context, day, focused) =>
                _dayCell(day, bleeding, fertile, estimated, today: true),
          ),
        ),
        const SizedBox(height: 8),
        _legend(),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HeatFormScreen(petId: widget.pet.id),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Registrar celo'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Historial',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (cycles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Sin registros todavía.'),
          ),
        for (final c in cycles) _cycleTile(c),
      ],
    );
  }

  Widget _disclaimer() {
    return Card(
      color: Colors.amber.shade100,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Las fechas son estimaciones y no son un método anticonceptivo. '
          'Separa a la mascota de machos durante el celo y consulta a tu veterinario.',
        ),
      ),
    );
  }

  Widget _predictionCard(HeatPrediction? p, bool noHistory) {
    final String text;
    if (p != null) {
      text = 'Próximo celo estimado: ${_fmt(p.estimated)}\n'
          'Rango: ${_fmt(p.earliest)} a ${_fmt(p.latest)}';
    } else if (noHistory) {
      text = 'Registra un celo para ver la estimación del próximo.';
    } else {
      text = 'Sin estimación en este momento (fuera de temporada).';
    }
    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
    );
  }

  Widget _dayCell(
    DateTime day,
    Set<DateTime> bleeding,
    Set<DateTime> fertile,
    DateTime? estimated, {
    bool today = false,
  }) {
    final d = dayOnly(day);
    Color? color;
    if (bleeding.contains(d)) {
      color = Colors.red.shade300;
    } else if (estimated != null && d == estimated) {
      color = Colors.pink.shade200;
    } else if (fertile.contains(d)) {
      color = Colors.orange.shade200;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: today ? Border.all(color: Colors.black54) : null,
      ),
      child: Text('${day.day}'),
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _dot(Colors.red.shade300, 'Sangrado'),
        _dot(Colors.orange.shade200, 'Ventana fértil (estimada)'),
        _dot(Colors.pink.shade200, 'Próximo celo (estimado)'),
      ],
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _cycleTile(HeatCycle c) {
    final end = c.endDate == null ? 'en curso' : _fmt(c.endDate!);
    final details = [
      if (c.intensity != null) c.intensity!,
      if (c.flowColor != null) 'flujo ${c.flowColor}',
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${_fmt(c.startDate)} – $end'),
      subtitle: details.isEmpty ? null : Text(details),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmDelete(c),
      ),
    );
  }

  Future<void> _confirmDelete(HeatCycle c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Seguro que quieres eliminar este celo?'),
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
    if (ok == true) {
      final db = ref.read(databaseProvider);
      await deleteHeatCycle(db, c.id);
      await syncReminders(db);
    }
  }

  String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
