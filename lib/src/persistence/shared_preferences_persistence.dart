import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import 'calendar_persistence.dart';

class SharedPreferencesPersistence implements CalendarPersistence {
  static const String _eventsKey = 'jazmine_calendar_events';
  final SharedPreferences _prefs;
  List<Event>? _cachedEvents;

  SharedPreferencesPersistence(this._prefs);

  static Future<SharedPreferencesPersistence> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesPersistence(prefs);
  }

  @override
  Future<List<Event>> loadEvents() async {
    try {
      if (_cachedEvents != null) return List.from(_cachedEvents!);

      final jsonString = _prefs.getString(_eventsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedEvents = jsonList
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return List.from(_cachedEvents!);
    } catch (e) {
      print('Error loading events: $e');
      return [];
    }
  }

  @override
  Future<void> saveEvents(List<Event> events) async {
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
  Future<void> addEvent(Event event) async {
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
  Future<void> updateEvent(Event event) async {
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
  Future<void> deleteEvent(Event event) async {
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
}
