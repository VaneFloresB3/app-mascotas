import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/heat_calendar.dart';
import '../../notifications/notification_service.dart';
import '../pets/pets_providers.dart';
import 'celo_providers.dart';

class HeatFormScreen extends ConsumerStatefulWidget {
  const HeatFormScreen({super.key, required this.petId});

  final int petId;

  @override
  ConsumerState<HeatFormScreen> createState() => _HeatFormScreenState();
}

class _HeatFormScreenState extends ConsumerState<HeatFormScreen> {
  final _notesController = TextEditingController();
  DateTime _start = dayOnly(DateTime.now());
  DateTime? _end;
  bool _ended = false;
  String? _intensity;
  String? _flow;
  String? _contact; // 'no' | 'si' | 'nosabe'
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : (_end ?? _start),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = dayOnly(picked);
      } else {
        _end = dayOnly(picked);
      }
    });
  }

  Future<void> _save() async {
    if (_ended && _end != null && _end!.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de fin no puede ser antes del inicio')),
      );
      return;
    }

    final notes = _notesController.text.trim();
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    await addHeatCycle(
      db,
      petId: widget.petId,
      start: _start,
      end: _ended ? _end : null,
      intensity: _intensity,
      flowColor: _flow,
      maleContact: _contact == null || _contact == 'nosabe'
          ? null
          : _contact == 'si',
      notes: notes.isEmpty ? null : notes,
    );
    await syncReminders(db);
    if (mounted) Navigator.of(context).pop();
  }

  String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar celo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Inicio'),
            subtitle: Text(_fmt(_start)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(isStart: true),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ya terminó'),
            value: _ended,
            onChanged: (v) => setState(() {
              _ended = v;
              if (v && _end == null) _end = _start;
            }),
          ),
          if (_ended)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fin'),
              subtitle: Text(_fmt(_end ?? _start)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: false),
            ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _intensity,
            decoration: const InputDecoration(labelText: 'Intensidad'),
            items: const [
              DropdownMenuItem(value: 'leve', child: Text('Leve')),
              DropdownMenuItem(value: 'moderada', child: Text('Moderada')),
              DropdownMenuItem(value: 'alta', child: Text('Alta')),
            ],
            onChanged: (v) => setState(() => _intensity = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _flow,
            decoration: const InputDecoration(labelText: 'Color del flujo'),
            items: const [
              DropdownMenuItem(value: 'rosado', child: Text('Rosado')),
              DropdownMenuItem(value: 'rojo', child: Text('Rojo')),
              DropdownMenuItem(value: 'ambar', child: Text('Ámbar')),
            ],
            onChanged: (v) => setState(() => _flow = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _contact,
            decoration: const InputDecoration(labelText: 'Contacto con machos'),
            items: const [
              DropdownMenuItem(value: 'no', child: Text('No')),
              DropdownMenuItem(value: 'si', child: Text('Sí')),
              DropdownMenuItem(value: 'nosabe', child: Text('No sé')),
            ],
            onChanged: (v) => setState(() => _contact = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notas'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
