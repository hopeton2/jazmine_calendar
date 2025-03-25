import 'package:jazmine_calendar/src/persistence/calendar_persistence.dart';
import 'package:jazmine_calendar/src/models/event.dart';

class InMemoryPersistence implements CalendarPersistence {
  final List<Event> _events = [];

  @override
  Future<void> addEvent(Event event) async {
    _events.add(event);
  }

  @override
  Future<void> updateEvent(Event event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
  }

  @override
  Future<void> deleteEvent(Event event) async {
    _events.removeWhere((e) => e.id == event.id);
  }

  @override
  Future<List<Event>> loadEvents() async {
    return List.from(_events);
  }

  @override
  Future<void> clearEvents() async {
    _events.clear();
  }

  @override
  Future<void> saveEvents(List<Event> events) async {
    _events.clear();
    _events.addAll(events);
  }
}
