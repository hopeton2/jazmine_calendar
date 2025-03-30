import 'package:jazmine_calendar/src/persistence/calendar_persistence.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

class InMemoryPersistence implements CalendarPersistence {
  final List<CalendarEvent> _events = [];

  @override
  Future<void> addEvent(CalendarEvent event) async {
    _events.add(event);
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
  }

  @override
  Future<void> deleteEvent(CalendarEvent event) async {
    _events.removeWhere((e) => e.id == event.id);
  }

  @override
  Future<List<CalendarEvent>> loadEvents() async {
    return List.from(_events);
  }

  @override
  Future<void> clearEvents() async {
    _events.clear();
  }

  @override
  Future<void> saveEvents(List<CalendarEvent> events) async {
    _events.clear();
    _events.addAll(events);
  }
}
