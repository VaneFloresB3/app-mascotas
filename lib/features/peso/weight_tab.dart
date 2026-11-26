import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../domain/formatting.dart';
import '../pets/pets_providers.dart';

/// Pesos de una mascota, del más antiguo al más reciente.
final weightsProvider = StreamProvider.family<List<Weight>, int>((ref, petId) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.weights)
    ..where((t) => t.petId.equals(petId))
    ..orderBy([(t) => OrderingTerm.asc(t.date)]);
  return query.watch();
});

class WeightTab extends ConsumerWidget {
  const WeightTab({super.key, required this.petId});

  final int petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightsAsync = ref.watch(weightsProvider(petId));

    return weightsAsync.when(
      data: (list) {
        return Scaffold(
          body: list.isEmpty
              ? const Center(child: Text('Registra el peso de tu mascota.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (list.length >= 2) ...[
                      SizedBox(height: 200, child: _chart(list)),
                      const SizedBox(height: 16),
                    ],
                    for (final w in list.reversed)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${w.kg.toStringAsFixed(2)} kg'),
                        subtitle: Text(fmtDate(w.date)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(ref, w.id),
                        ),
                      ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addWeight(context, ref),
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _chart(List<Weight> list) {
    final first = list.first.date;
    final spots = [
      for (final w in list)
        FlSpot(w.date.difference(first).inDays.toDouble(), w.kg),
    ];
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Future<void> _addWeight(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final kg = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar peso'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Peso (kg)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final value =
                  double.tryParse(controller.text.trim().replaceAll(',', '.'));
              Navigator.pop(ctx, value);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (kg == null || kg <= 0) return;

    final db = ref.read(databaseProvider);
    await db.into(db.weights).insert(
          WeightsCompanion.insert(
            petId: petId,
            date: DateTime.now(),
            kg: kg,
          ),
        );
  }

  Future<void> _delete(WidgetRef ref, int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.weights)..where((t) => t.id.equals(id))).go();
  }
}
