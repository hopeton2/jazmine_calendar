import 'package:flutter/foundation.dart';
import 'package:jazmine_calendar/src/models/event.dart';
import 'package:jazmine_calendar/src/persistence/calendar_persistence.dart';

class EventService {
  final CalendarPersistence _persistence;
  List<Event>? _cachedEvents;
  bool _isLoading = false;
  final ValueNotifier<List<Event>> eventsNotifier = ValueNotifier<List<Event>>([]);

  EventService(this._persistence);

  bool get isLoading => _isLoading;

  Future<void> addEvent(Event event) async {
    _isLoading = true;
    await _persistence.addEvent(event);
    _invalidateCache();
    _isLoading = false;
  }

  Future<void> updateEvent(Event event) async {
    _isLoading = true;
    await _persistence.updateEvent(event);
    _invalidateCache();
    _isLoading = false;
  }

  Future<void> deleteEvent(Event event) async {
    _isLoading = true;
    await _persistence.deleteEvent(event);
    _invalidateCache();
    _isLoading = false;
  }

  Future<List<Event>> getAllEvents() async {
    if (_cachedEvents != null) {
      return List.from(_cachedEvents!);
    }

    _isLoading = true;
    _cachedEvents = await _persistence.loadEvents();
    eventsNotifier.value = List.from(_cachedEvents!);
    _isLoading = false;
    return List.from(_cachedEvents!);
  }

  Future<void> clearEvents() async {
    _isLoading = true;
    await _persistence.clearEvents();
    _invalidateCache();
    _isLoading = false;
  }

  void _invalidateCache() {
    _cachedEvents = null;
  }
}