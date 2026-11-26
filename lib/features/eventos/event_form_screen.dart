import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/event_types.dart';
import '../../domain/formatting.dart';
import '../../domain/heat_calendar.dart';
import '../../notifications/notification_service.dart';
import '../pets/pets_providers.dart';
import 'events_providers.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, required this.petId, required this.types});

  final int petId;
  final Set<String> types;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _notesController = TextEditingController();
  String? _type;
  DateTime _date = dayOnly(DateTime.now());
  TimeOfDay _time = TimeOfDay.now();
  bool _hasNext = false;
  DateTime? _nextDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.types.isEmpty ? null : widget.types.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _allowsNext => _type != null && typesWithNextDate.contains(_type);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => _date = dayOnly(picked));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickNext() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate ?? _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => _nextDate = dayOnly(picked));
  }

  Future<void> _save() async {
    final type = _type;
    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige un tipo de evento')),
      );
      return;
    }
    if (_hasNext && _nextDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige la próxima fecha')),
      );
      return;
    }

    final when = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final notes = _notesController.text.trim();

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    await addEvent(
      db,
      petId: widget.petId,
      type: type,
      date: when,
      notes: notes.isEmpty ? null : notes,
      nextDate: _allowsNext && _hasNext ? _nextDate : null,
    );
    await syncReminders(db);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo registro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: [
              for (final t in widget.types)
                DropdownMenuItem(value: t, child: Text(eventTypeLabels[t] ?? t)),
            ],
            onChanged: (v) => setState(() {
              _type = v;
              if (!_allowsNext) _hasNext = false;
            }),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha'),
            subtitle: Text(fmtDate(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hora'),
            subtitle: Text(_time.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: _pickTime,
          ),
          if (_allowsNext) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tiene próxima fecha (recordatorio)'),
              value: _hasNext,
              onChanged: (v) => setState(() {
                _hasNext = v;
                if (v && _nextDate == null) _nextDate = _date;
              }),
            ),
            if (_hasNext)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Próxima fecha'),
                subtitle: Text(fmtDate(_nextDate ?? _date)),
                trailing: const Icon(Icons.event),
                onTap: _pickNext,
              ),
          ],
          const SizedBox(height: 8),
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
