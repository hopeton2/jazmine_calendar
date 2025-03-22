import 'package:flutter/material.dart';
import '../../models/event.dart';

typedef EventEditorBuilder = Widget Function(
  BuildContext context,
  Event? event,
  ValueChanged<Event> onSave,
  VoidCallback onCancel,
);

class EventEditor extends StatelessWidget {
  final Event? event;
  final ValueChanged<Event> onSave;
  final VoidCallback onCancel;
  final EventEditorBuilder? builder;

  const EventEditor({
    super.key,
    this.event,
    required this.onSave,
    required this.onCancel,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (builder != null) {
      return builder!(context, event, onSave, onCancel);
    }
    return DefaultEventEditor(
      event: event,
      onSave: onSave,
      onCancel: onCancel,
    );
  }
}

class DefaultEventEditor extends StatefulWidget {
  final Event? event;
  final ValueChanged<Event> onSave;
  final VoidCallback onCancel;

  const DefaultEventEditor({
    super.key,
    this.event,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<DefaultEventEditor> createState() => _DefaultEventEditorState();
}

class _DefaultEventEditorState extends State<DefaultEventEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late DateTime _startTime;
  late DateTime _endTime;
  String _timeZone = 'UTC';

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _startTime = event?.start ?? DateTime.now();
    _endTime = event?.end ?? DateTime.now().add(const Duration(hours: 1));
    _timeZone = event?.timeZone ?? 'UTC';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start'),
                      const SizedBox(height: 8),
                      _buildDateTimePicker(
                        initialDate: _startTime,
                        onChanged: (date) => setState(() => _startTime = date),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End'),
                      const SizedBox(height: 8),
                      _buildDateTimePicker(
                        initialDate: _endTime,
                        onChanged: (date) => setState(() => _endTime = date),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _timeZone,
              decoration: const InputDecoration(
                labelText: 'Time Zone',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                DropdownMenuItem(value: 'America/New_York', child: Text('Eastern Time')),
                DropdownMenuItem(value: 'America/Chicago', child: Text('Central Time')),
                DropdownMenuItem(value: 'America/Denver', child: Text('Mountain Time')),
                DropdownMenuItem(value: 'America/Los_Angeles', child: Text('Pacific Time')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _timeZone = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _titleController.text.isEmpty ? null : _handleSave,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required DateTime initialDate,
    required ValueChanged<DateTime> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                onChanged(DateTime(
                  date.year,
                  date.month,
                  date.day,
                  initialDate.hour,
                  initialDate.minute,
                ));
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              '${initialDate.year}-${initialDate.month.toString().padLeft(2, '0')}-${initialDate.day.toString().padLeft(2, '0')}',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton.icon(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(initialDate),
              );
              if (time != null) {
                onChanged(DateTime(
                  initialDate.year,
                  initialDate.month,
                  initialDate.day,
                  time.hour,
                  time.minute,
                ));
              }
            },
            icon: const Icon(Icons.access_time),
            label: Text(
              '${initialDate.hour.toString().padLeft(2, '0')}:${initialDate.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ),
      ],
    );
  }

  void _handleSave() {
    widget.onSave(
      Event(
        id: widget.event!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        start: _startTime,
        end: _endTime,
        timeZone: _timeZone,
      ),
    );
  }
}