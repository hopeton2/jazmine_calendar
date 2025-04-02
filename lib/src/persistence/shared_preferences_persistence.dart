import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_event.dart';
import 'calendar_persistence.dart';

class SharedPreferencesPersistence implements CalendarPersistence {
  static const String _eventsKey = 'jazmine_calendar_events';
  final SharedPreferences _prefs;
  List<CalendarEvent>? _cachedEvents;

  SharedPreferencesPersistence(this._prefs);

  static Future<SharedPreferencesPersistence> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesPersistence(prefs);
  }

  @override
  Future<List<CalendarEvent>> loadEvents() async {
    try {
      if (_cachedEvents != null) return List.from(_cachedEvents!);

      final jsonString = _prefs.getString(_eventsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedEvents = jsonList
          .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
          .toList();

      return List.from(_cachedEvents!);
    } catch (e) {
      print('Error loading events: $e');
      return [];
    }
  }

  @override
  Future<void> saveEvents(List<CalendarEvent> events) async {
    try {
      final jsonString = json.encode(
        events.map((event) => event.toJson()).toList(),
      );
      await _prefs.setString(_eventsKey, jsonString);
      _cachedEvents = List.from(events);
    } catch (e) {
      print('Error saving events: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearEvents() async {
    try {
      await _prefs.remove(_eventsKey);
      _cachedEvents = null;
    } catch (e) {
      print('Error clearing events: $e');
      rethrow;
    }
  }

  @override
  Future<void> addEvent(CalendarEvent event) async {
    try {
      final events = await loadEvents();
      events.add(event);
      await saveEvents(events);
    } catch (e) {
      print('Error adding event: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    try {
      final events = await loadEvents();
      final index = events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        events[index] = event;
        await saveEvents(events);
      }
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEvent(CalendarEvent event) async {
    try {
      final events = await loadEvents();
      events.removeWhere((e) => e.id == event.id);
      await saveEvents(events);
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  /// Clears the in-memory cache, forcing next load to fetch from storage
  void invalidateCache() {
    _cachedEvents = null;
  }

  @override
  Future<List<CalendarEvent>> getEventsInRange(
      DateTime start, DateTime end) async {
    try {
      final events = await loadEvents();
      return events.where((event) {
        // Check if the event overlaps with the given range
        return (event.start.isBefore(end) && event.end.isAfter(start)) ||
            (event.start.isAtSameMomentAs(start)) ||
            (event.end.isAtSameMomentAs(end));
      }).toList();
    } catch (e) {
      print('Error getting events in range: $e');
      return [];
    }
  }
}
