import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings.dart';
import '../../domain/formatting.dart';
import '../../notifications/notification_service.dart';
import '../pets/pets_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _hour = 19;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hour = await getReminderHour();
    if (!mounted) return;
    setState(() {
      _hour = hour;
      _loaded = true;
    });
  }

  Future<void> _changeHour(int? hour) async {
    if (hour == null) return;
    setState(() => _hour = hour);
    await setReminderHour(hour);
    await syncReminders(ref.read(databaseProvider));
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar todos los datos'),
        content: const Text(
          'Se borrarán todas las mascotas, celos, eventos y pesos. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final db = ref.read(databaseProvider);
    await db.delete(db.events).go();
    await db.delete(db.weights).go();
    await db.delete(db.heatCycles).go();
    await db.delete(db.pets).go();
    await syncReminders(db);
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _hour,
                  decoration: const InputDecoration(
                    labelText: 'Hora de recordatorios',
                  ),
                  items: [
                    for (var h = 0; h < 24; h++)
                      DropdownMenuItem(value: h, child: Text('${two(h)}:00')),
                  ],
                  onChanged: _changeHour,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Los recordatorios de celo, vacunas y citas llegarán a esta hora.',
                ),
                const SizedBox(height: 32),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Borrar todos los datos',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Irreversible'),
                  onTap: _deleteAll,
                ),
              ],
            ),
    );
  }
}
