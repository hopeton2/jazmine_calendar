import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/persistence/calendar_persistence.dart';
import 'package:jazmine_calendar/src/persistence/in_memory_persistence.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:collection/collection.dart'; // For ListEquality if needed later
import 'package:jazmine_calendar/src/services/calendar_view_service.dart';
import 'package:jazmine_calendar/src/services/navigation_service.dart';
import 'package:jazmine_calendar/src/services/time_service.dart';
import 'package:jazmine_calendar/src/utils/date_helper.dart';
import 'package:rrule/rrule.dart'; // Import rrule package
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // For dayStarts/dayEnds

typedef EventCallback = Future<void> Function(CalendarEvent event);
typedef EventPositionCallback = Future<void> Function(
    CalendarEvent event, Offset position);
typedef EventTimeCallback = Future<void> Function(
    CalendarEvent event, DateTime newStart, DateTime newEnd);

// Enum is defined outside the class
enum CalendarChangeType {
  dateOrView,
  eventData,
  timeZone,
  setting,
  other,
}

class CalendarController extends ChangeNotifier {
  // --- Specific Notifiers ---
  final ValueNotifier<int> _eventDataChangeCounter = ValueNotifier<int>(0);

  /// Notifies listeners when event data (add, update, delete, clear, persistence change, cache invalidation) changes.
  /// Listeners can use the integer value changing as the signal.
  ValueNotifier<int> get eventDataChangeNotifier => _eventDataChangeCounter;

  final ValueNotifier<int> _settingsChangeCounter = ValueNotifier<int>(0);

  /// Notifies listeners when calendar settings (FAB, scroll animation, target hour, time zones, default start times) change.
  ValueNotifier<int> get settingsChangeNotifier => _settingsChangeCounter;
  // --- End Specific Notifiers ---

  bool _eventsChanged = false; // Used within batch updates
  bool get eventsChanged => _eventsChanged; // Keep for internal logic?

  final NavigationService _navigationService;
  final TimeService _timeService;
  Timer? _timer;

  final List<String> _visibleTimeZones;
  bool _showFloatingActionButton;
  final bool _scrollToCurrentTimeOnLoad;
  bool _animateTimeScroll;
  EventCallback? _onEventCreated;
  EventCallback? _onEventTap;
  EventCallback? _onEventDoubleTap;
  EventPositionCallback? _onEventLongPress;
  EventTimeCallback? _onEventRescheduled;
  EventTimeCallback? _onEventResized;
  int? _targetHour;
  final Map<CalendarViewType, double> _scrollPositions = {};
  bool _hasInitialScroll = false;
  final int firstDayOfWeek;

  late final CalendarPersistence _persistence;
  List<CalendarEvent>? _baseEvents; // Cache for events loaded from persistence
  bool _isLoading = false;
  bool _batchNotifications = false;
  // Remove _cachedEvents and _eventsNotifier - expansion is dynamic

  ValueNotifier<CalendarViewType> get _currentViewNotifier =>
      _navigationService.currentViewNotifier;

  // Expose necessary notifiers (Existing ones + New ones)
  ValueNotifier<CalendarViewType> get currentViewNotifier =>
      _navigationService.currentViewNotifier;
  ValueNotifier<DateTime> get selectedDateNotifier =>
      _navigationService.selectedDateNotifier;
  ValueNotifier<DateTime> get startDateNotifier =>
      _navigationService.startDateNotifier;
  ValueNotifier<DateTime> get currentTimeNotifier =>
      _timeService.currentTimeNotifier;
  ValueNotifier<Duration> get intervalNotifier => _timeService.intervalNotifier;
  // Remove eventsNotifier getter

  static int getFirstDayOfWeekForLocale(String? languageCode) {
    if (languageCode == null) return DateTime.monday;
    switch (languageCode) {
      case 'en':
        return DateTime.sunday;
      case 'hi':
        return DateTime.sunday;
      case 'zh':
      case 'fr':
      case 'de':
      case 'es':
      default:
        return DateTime.monday;
    }
  }

  static Future<CalendarController> create({
    CalendarViewType initialView = CalendarViewType.day,
    DateTime? initialDate,
    List<String> visibleTimeZones = const ['UTC'],
    bool showFloatingActionButton = true,
    bool scrollToCurrentTimeOnLoad = true,
    bool animateTimeScroll = true,
    EventCallback? onEventCreated,
    EventCallback? onEventTap,
    EventCallback? onEventDoubleTap,
    EventPositionCallback? onEventLongPress,
    EventTimeCallback? onEventRescheduled,
    EventTimeCallback? onEventResized,
    Duration interval = const Duration(minutes: 30),
    CalendarPersistence? persistence,
    int? firstDayOfWeek,
    Locale? locale,
  }) async {
    int effectiveFirstDayOfWeek =
        firstDayOfWeek ?? getFirstDayOfWeekForLocale(locale?.languageCode);
    return CalendarController(
      initialView: initialView,
      initialDate: initialDate,
      visibleTimeZones: visibleTimeZones,
      showFloatingActionButton: showFloatingActionButton,
      scrollToCurrentTimeOnLoad: scrollToCurrentTimeOnLoad,
      animateTimeScroll: animateTimeScroll,
      onEventCreated: onEventCreated,
      onEventTap: onEventTap,
      onEventDoubleTap: onEventDoubleTap,
      onEventLongPress: onEventLongPress,
      onEventRescheduled: onEventRescheduled,
      onEventResized: onEventResized,
      interval: interval,
      persistence: persistence,
      firstDayOfWeek: effectiveFirstDayOfWeek,
    );
  }

  CalendarController({
    required CalendarViewType initialView,
    DateTime? initialDate,
    List<String> visibleTimeZones = const ['UTC'],
    bool showFloatingActionButton = true,
    bool scrollToCurrentTimeOnLoad = true,
    bool animateTimeScroll = true,
    EventCallback? onEventCreated,
    EventCallback? onEventTap,
    EventCallback? onEventDoubleTap,
    EventPositionCallback? onEventLongPress,
    EventTimeCallback? onEventRescheduled,
    EventTimeCallback? onEventResized,
    Duration interval = const Duration(minutes: 30),
    CalendarPersistence? persistence,
    this.firstDayOfWeek = DateTime.monday,
  })  : _navigationService = NavigationService(
            initialDate: initialDate, initialView: initialView),
        _timeService = TimeService(interval: interval),
        _visibleTimeZones = List.from(visibleTimeZones),
        _showFloatingActionButton = showFloatingActionButton,
        _scrollToCurrentTimeOnLoad = scrollToCurrentTimeOnLoad,
        _animateTimeScroll = animateTimeScroll,
        _onEventCreated = onEventCreated,
        _onEventTap = onEventTap,
        _onEventDoubleTap = onEventDoubleTap,
        _onEventLongPress = onEventLongPress,
        _onEventRescheduled = onEventRescheduled,
        _onEventResized = onEventResized,
        _persistence = persistence ?? InMemoryPersistence() {
    DateHelper.controller = this;
    CalendarViewService.controller = this;

    final dateRange = CalendarViewService()
        .dateRangeOfView(initialView, initialDate ?? DateTime.now());
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _eventDataChangeCounter.dispose();
    _settingsChangeCounter.dispose();
    // Dispose other notifiers if they were owned solely by this controller
    // _navigationService.dispose(); // Assuming these are managed elsewhere or stateless
    // _timeService.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timeService.currentTimeNotifier.value = DateTime.now();
    final now = DateTime.now();
    final nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final delay = nextMinute.difference(now);

    // Initial timer to sync with minute boundary
    _timer = Timer(delay, () {
      // Assign to _timer here too
      // Check if timer was cancelled before callback runs
      if (_timer == null || !_timer!.isActive) return;
      _timeService.currentTimeNotifier.value = DateTime.now();

      // Then start periodic timer
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        // Timer is passed, check its isActive status
        if (!timer.isActive) return;
        _timeService.currentTimeNotifier.value = DateTime.now();
      });
    });
  }

  // Getters
  CalendarViewType get currentView => _currentViewNotifier.value;
  DateTime get selectedDate => selectedDateNotifier.value;
  DateTime get startDate => startDateNotifier.value;
  List<String> get visibleTimeZones => List.unmodifiable(_visibleTimeZones);
  bool get showFloatingActionButton => _showFloatingActionButton;
  EventCallback? get onEventCreated => _onEventCreated;
  EventCallback? get onEventTap => _onEventTap;
  EventCallback? get onEventDoubleTap => _onEventDoubleTap;
  EventPositionCallback? get onEventLongPress => _onEventLongPress;
  EventTimeCallback? get onEventRescheduled => _onEventRescheduled;
  EventTimeCallback? get onEventResized => _onEventResized;
  int? get targetHour => _targetHour;
  bool get isLoading => _isLoading;
  bool get hasInitialScroll => _hasInitialScroll;

  void setInitialScrollComplete() {
    _hasInitialScroll = true;
  }

  // Removed _notifyIfNeeded

  Future<void> _batchUpdate(Future<void> Function() updates) async {
    _batchNotifications = true;
    try {
      await updates();
    } finally {
      _batchNotifications = false;
      if (_eventsChanged) {
        _eventDataChangeCounter.value++;
      }
    }
  }

  List<DateTime> get visibleDateRange => CalendarViewService().visibleDateRange;

  void setShowFloatingActionButton(bool show) {
    if (_showFloatingActionButton == show) return;
    _showFloatingActionButton = show;
    _settingsChangeCounter.value++;
  }

  // Setters for callbacks (no notification needed)
  void setOnEventCreated(EventCallback? callback) {
    _onEventCreated = callback;
  }

  void setOnEventTap(EventCallback? callback) {
    _onEventTap = callback;
  }

  void setOnEventDoubleTap(EventCallback? callback) {
    _onEventDoubleTap = callback;
  }

  void setOnEventLongPress(EventPositionCallback? callback) {
    _onEventLongPress = callback;
  }

  void setOnEventRescheduled(EventTimeCallback? callback) {
    _onEventRescheduled = callback;
  }

  void setOnEventResized(EventTimeCallback? callback) {
    _onEventResized = callback;
  }

  void setPersistence(CalendarPersistence persistence) {
    _persistence = persistence;
    _baseEvents = null; // Invalidate base event cache
    _eventDataChangeCounter.value++;
  }

  // --- Navigation Methods ---
  void changeView(CalendarViewType view) {
    final currentView = _navigationService.currentViewNotifier.value;
    if (currentView != view) {
      _navigationService.changeView(view);
      final dateRange = CalendarViewService().dateRangeOfView(view, startDate);
      CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);
    }
  }

  void selectDate(DateTime date) {
    _navigationService.selectDate(date);
    final dateRange =
        CalendarViewService().dateRangeOfView(CalendarViewType.day, date);
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);
  }

  void navigateToDate(DateTime date) {
    _navigationService.navigateToDate(date);
    final dateRange = CalendarViewService().dateRangeOfView(currentView, date);
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);
  }

  void navigateToNextPage() {
    _navigationService.navigateToNextPage();
    final dateRange =
        CalendarViewService().dateRangeOfView(currentView, startDate);
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);
  }

  void navigateToPreviousPage() {
    _navigationService.navigateToPreviousPage();
    final dateRange =
        CalendarViewService().dateRangeOfView(currentView, startDate);
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);
  }
  // --- End Navigation Methods ---

  void setTargetHour(int? hour) {
    if (hour != null && (hour < 0 || hour > 23)) {
      throw ArgumentError('Hour must be between 0 and 23');
    }
    if (_targetHour == hour) return;
    _targetHour = hour;
    _settingsChangeCounter.value++;
  }

  void setInterval(Duration interval) {
    if (intervalNotifier.value != interval) {
      intervalNotifier.value = interval;
      _settingsChangeCounter.value++;
    }
  }

  List<DateTime> get currentDateRange {
    return CalendarViewService().dateRangeOfView(currentView, startDate);
  }

  // --- Event Management ---
  Future<void> addEvent(CalendarEvent event) async {
    await _batchUpdate(() async {
      _isLoading = true;
      await _persistence.addEvent(event);
      _baseEvents = null; // Invalidate base event cache
      _eventsChanged = true;
      if (_onEventCreated != null) {
        await _onEventCreated!(event);
      }
      _isLoading = false;
    });
    _eventsChanged = false;
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _batchUpdate(() async {
      _isLoading = true;
      await _persistence.updateEvent(event);
      _baseEvents = null; // Invalidate base event cache
      _eventsChanged = true;
      _isLoading = false;
    });
    _eventsChanged = false;
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    await _batchUpdate(() async {
      _isLoading = true;
      await _persistence.deleteEvent(event);
      _baseEvents = null; // Invalidate base event cache
      _eventsChanged = true;
      _isLoading = false;
    });
    _eventsChanged = false;
  }

  // This method now only loads base events if needed, doesn't return them directly.
  Future<void> _loadBaseEventsIfNeeded() async {
    if (_baseEvents != null) return; // Already loaded
    if (_isLoading) return; // Already loading

    try {
      _isLoading = true;
      // Notify potentially? Or assume caller handles loading state
      _baseEvents = await _persistence.loadEvents();
    } catch (e) {
      // print("Error loading base events: $e"); // Removed print
      _baseEvents = []; // Set to empty on error to prevent repeated attempts
    } finally {
      _isLoading = false;
      // Notify that base data might have changed (e.g., after initial load)
      // This might trigger unnecessary rebuilds if called frequently.
      // Consider if notification is needed here or only on mutation.
      // _eventDataChangeCounter.value++;
    }
  }

  /// Updates the start and end times of an event.
  ///
  /// This method updates the event in the persistence layer, invalidates the cache,
  /// and notifies listeners of the data change. It does NOT fire user callbacks like
  /// onEventRescheduled or onEventResized; those should be called separately if needed
  /// after this method completes.
  Future<void> updateEventTimes(
      CalendarEvent event, DateTime newStart, DateTime newEnd) async {
    // Avoid redundant updates if times haven't changed
    if (event.start == newStart && event.end == newEnd) {
      // print( // Removed print
      //     "[Controller.updateEventTimes] No change detected for event ${event.id}. Skipping update.");
      return;
    }

    // print( // Removed print
    //     "[Controller.updateEventTimes] Updating event ${event.id} to $newStart - $newEnd");
    await _batchUpdate(() async {
      _isLoading = true;
      final updatedEvent = event.copyWith(start: newStart, end: newEnd);
      try {
        await _persistence.updateEvent(updatedEvent);
        // print( // Removed print
        //     "[Controller.updateEventTimes] Persistence update successful for ${event.id}.");
        _baseEvents = null; // Invalidate cache
        _eventsChanged = true; // Mark data as changed for notification
      } catch (e) {
        // print( // Removed print
        //     "[Controller.updateEventTimes] Error updating event ${event.id} in persistence: $e");
        // Decide if we should rethrow or just log
      } finally {
        _isLoading = false;
      }
    });
    // _batchUpdate handles notifying _eventDataChangeCounter if _eventsChanged is true
    _eventsChanged =
        false; // Reset flag after batch update potentially notified
    // print( // Removed print
    //     "[Controller.updateEventTimes] Update process complete for event ${event.id}. Notification (if change occurred) sent via batch update.");
  }

  Future<void> addEvents(List<CalendarEvent> events) async {
    await _batchUpdate(() async {
      _isLoading = true;
      for (final event in events) {
        await _persistence.addEvent(event);
        if (_onEventCreated != null) {
          await _onEventCreated!(event);
        }
      }
      _baseEvents = null; // Invalidate base event cache
      _eventsChanged = true;
      _isLoading = false;
    });
    _eventsChanged = false;
  }

  Future<void> clearEvents() async {
    try {
      _isLoading = true;
      await _persistence.clearEvents();
      _baseEvents = null; // Invalidate base event cache
      _eventsChanged = true;
    } finally {
      _isLoading = false;
      if (_eventsChanged) {
        _eventDataChangeCounter.value++;
      }
      _eventsChanged = false;
    }
  }

  Future<void> rescheduleEvent(CalendarEvent event, DateTime newStart,
      DateTime newEnd, bool isAllDay) async {
    await _batchUpdate(() async {
      _isLoading = true;
      if (event.isAllDay && !isAllDay) {
        newEnd = newStart.add(const Duration(hours: 1)); // if converting from all-day to timed, default to 1 hour
      }
      final updatedEvent =
          event.copyWith(start: newStart, end: newEnd, isAllDay: isAllDay);
      // print( // Removed print
      //     '[Controller.rescheduleEvent] Calling persistence update for ${updatedEvent.id}'); // Define once
      try {
        await _persistence.updateEvent(updatedEvent);
        // Update cache if loaded, otherwise invalidate
        if (_baseEvents != null) {
          final index = _baseEvents!.indexWhere((e) => e.id == event.id);
          if (index != -1) {
            _baseEvents![index] = updatedEvent;
          } else {
            _baseEvents = null; // Event wasn't in cache? Invalidate.
            // print( // Removed print
            //     '[Controller.rescheduleEvent] Event ${updatedEvent.id} not found in cache, invalidating.');
          }
        } else {
          _baseEvents = null; // Ensure it stays null if it was already null
          // print('[Controller.rescheduleEvent] Cache was null, invalidating.'); // Removed print
        }
        _eventsChanged = true; // Mark that data changed within the batch
        if (_onEventRescheduled != null) {
          // Call user callback *after* successful persistence and cache update
          await _onEventRescheduled!(event, newStart, newEnd);
        }
      } catch (e, s) {
        // print( // Removed print
        //     '[Controller.rescheduleEvent] Error during persistence update for ${updatedEvent.id}: $e\n$s');
        // Optionally rethrow or handle error appropriately
      } finally {
        _isLoading = false;
      }
    });
    // Notification happens here if _eventsChanged is true after _batchUpdate completes
    if (_eventsChanged) {
      // print( // Removed print
      //     '[Controller.rescheduleEvent] Notifying listeners about event change.');
    }
    _eventsChanged = false; // Reset flag after potential notification
  }

  Future<void> resizeEvent(
      CalendarEvent event, DateTime newStart, DateTime newEnd) async {
    // print( // Removed print
    //     '[Controller.resizeEvent] Received event ${event.id} with new times: $newStart - $newEnd');
    await _batchUpdate(() async {
      _isLoading = true;
      final updatedEvent = event.copyWith(start: newStart, end: newEnd);
      // print( // Removed print
      //     '[Controller.resizeEvent] Calling persistence update for ${updatedEvent.id}');
      try {
        await _persistence.updateEvent(updatedEvent);
        // print( // Removed print
        //     '[Controller.resizeEvent] Persistence update successful for ${updatedEvent.id}');
        // Update cache if loaded, otherwise invalidate
        if (_baseEvents != null) {
          final index = _baseEvents!.indexWhere((e) => e.id == event.id);
          if (index != -1) {
            _baseEvents![index] = updatedEvent;
            // print( // Removed print
            //     '[Controller.resizeEvent] Updated event ${updatedEvent.id} in cache.');
          } else {
            _baseEvents = null; // Event wasn't in cache? Invalidate.
            // print( // Removed print
            //     '[Controller.resizeEvent] Event ${updatedEvent.id} not found in cache, invalidating.');
          }
        } else {
          _baseEvents = null; // Ensure it stays null if it was already null
          // print('[Controller.resizeEvent] Cache was null, invalidating.'); // Removed print
        }
        _eventsChanged = true; // Mark that data changed within the batch
        if (_onEventResized != null) {
          // Call user callback *after* successful persistence and cache update
          await _onEventResized!(event, newStart, newEnd);
        }
      } catch (e, s) {
        // print( // Removed print
        //     '[Controller.resizeEvent] Error during persistence update for ${updatedEvent.id}: $e\n$s');
        // Optionally rethrow or handle error appropriately
      } finally {
        _isLoading = false;
      }
    });
    // Notification happens here if _eventsChanged is true after _batchUpdate completes
    if (_eventsChanged) {
      // print('[Controller.resizeEvent] Notifying listeners about event change.'); // Removed print
    }
    _eventsChanged = false; // Reset flag after potential notification
  }
  // --- End Event Management ---

  // --- TimeZone Management ---
  void addTimeZone(String timeZone) {
    if (!_visibleTimeZones.contains(timeZone)) {
      _visibleTimeZones.add(timeZone);
      _settingsChangeCounter.value++;
    }
  }

  void removeTimeZone(String timeZone) {
    if (_visibleTimeZones.length > 1 && _visibleTimeZones.contains(timeZone)) {
      _visibleTimeZones.remove(timeZone);
      _settingsChangeCounter.value++;
    }
  }
  // --- End TimeZone Management ---

  // --- Cache Management ---
  void invalidateCache() {
    _baseEvents = null; // Invalidate base event cache
    _eventDataChangeCounter.value++;
  }
  // --- End Cache Management ---

  double? getScrollPosition(CalendarViewType view) {
    return _scrollPositions[view];
  }

  void setScrollPosition(CalendarViewType view, double position) {
    if (position != _scrollPositions[view]) {
      _scrollPositions[view] = position;
    }
  }

  bool get scrollToCurrentTimeOnLoad => _scrollToCurrentTimeOnLoad;

  bool get animateTimeScroll => _animateTimeScroll;

  void setAnimateTimeScroll(bool value) {
    if (_animateTimeScroll != value) {
      _animateTimeScroll = value;
      _settingsChangeCounter.value++;
    }
  }

  final List<TimeOfDay> _startTimes = List.generate(
    7,
    (_) => const TimeOfDay(hour: 8, minute: 0),
  );

  List<TimeOfDay> get defaultStartTimes => List.unmodifiable(_startTimes);

  /// Gets all event occurrences (including expanded recurring events)
  /// that fall within the specified date range [start] (inclusive) and [end] (exclusive).
  Future<List<CalendarEvent>> getEventsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (start.isAfter(end)) return [];

    await _loadBaseEventsIfNeeded(); // Ensure base events are loaded

    if (_baseEvents == null) return []; // Return empty if loading failed

    final List<CalendarEvent> occurrencesInRange = [];
    // Define a slightly wider window for recurrence generation to catch events
    // starting just before the window but recurring into it.
    final recurrenceWindowStart = start.subtract(const Duration(days: 1));
    final recurrenceWindowEnd = end.add(const Duration(days: 1));

    for (final baseEvent in _baseEvents!) {
      if (baseEvent.recurrenceRule == null ||
          baseEvent.recurrenceRule!.isEmpty) {
        // --- Non-recurring event ---
        // Check if it overlaps the requested range [start, end)
        if (baseEvent.start.isBefore(end) && baseEvent.end.isAfter(start)) {
          occurrencesInRange.add(baseEvent);
        }
      } else {
        // --- Recurring event ---
        try {
          final rrule = RecurrenceRule.fromString(baseEvent.recurrenceRule!);
          final duration = baseEvent.end.difference(baseEvent.start);

          // Use the rrule instance to get occurrences within the wider window
          final instances = rrule.getInstances(
            start: baseEvent.start, // Important: DTSTART for the rule
            after: recurrenceWindowStart.subtract(const Duration(
                microseconds:
                    1)), // Ensure we get instances starting exactly at the window start
            before: recurrenceWindowEnd, // Exclusive end
          );

          for (final occurrenceStart in instances) {
            final occurrenceEnd = occurrenceStart.add(duration);

            // Check if this specific occurrence overlaps the *requested* range [start, end)
            if (occurrenceStart.isBefore(end) && occurrenceEnd.isAfter(start)) {
              // Create a new event instance for this occurrence
              // Create a new event instance for this occurrence
              occurrencesInRange.add(baseEvent.copyWith(
                // Keep original ID for now, use flags to identify
                start: occurrenceStart,
                end: occurrenceEnd,
                isOccurrence: true, // Mark as an occurrence
                originalEventId: baseEvent.id, // Store original ID
                recurrenceRule: null, // Occurrences don't have rules themselves
                recurrenceType: null,
              ));
            }
          }
        } catch (e) {
          // print( // Removed print
          //     "Error parsing RRULE for event ${baseEvent.id}: ${baseEvent.recurrenceRule} - $e");
          // Optionally include the base event itself if it falls in range, even if rule fails
          if (baseEvent.start.isBefore(end) && baseEvent.end.isAfter(start)) {
            occurrencesInRange.add(baseEvent.copyWith(
                recurrenceRule: null,
                recurrenceType: null)); // Treat as non-recurring on error
          }
        }
      }
    }
    return occurrencesInRange;
  }

  TimeOfDay getStartTimeForDay(DateTime date) {
    int weekdayIndex = (date.weekday - firstDayOfWeek + 7) % 7;
    return _startTimes[weekdayIndex];
  }

  void setStartTimeForDay(int weekday, TimeOfDay time) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError(
          'Weekday must be between DateTime.monday and DateTime.sunday');
    }
    int index = (weekday - firstDayOfWeek + 7) % 7;
    if (_startTimes[index] != time) {
      _startTimes[index] = time;
      _settingsChangeCounter.value++;
    }
  }
}
