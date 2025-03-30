import '../models/calendar_event.dart';

abstract class CalendarPersistence {
  Future<List<CalendarEvent>> loadEvents();
  Future<void> saveEvents(List<CalendarEvent> events);
  Future<void> clearEvents();
  Future<void> addEvent(CalendarEvent event);
  Future<void> updateEvent(CalendarEvent event);
  Future<void> deleteEvent(CalendarEvent event);
}
