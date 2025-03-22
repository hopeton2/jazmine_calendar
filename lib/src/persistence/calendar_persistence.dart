import '../models/event.dart';

abstract class CalendarPersistence {
  Future<List<Event>> loadEvents();
  Future<void> saveEvents(List<Event> events);
  Future<void> clearEvents();
  Future<void> addEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> deleteEvent(Event event);
}