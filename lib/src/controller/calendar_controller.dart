import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/persistence/calendar_persistence.dart';
import 'package:jazmine_calendar/src/persistence/in_memory_persistence.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/services/calendar_view_service.dart';
import 'package:jazmine_calendar/src/services/navigation_service.dart';
import 'package:jazmine_calendar/src/services/time_service.dart';
import 'package:jazmine_calendar/src/utils/date_helper.dart';

typedef EventCallback = Future<void> Function(CalendarEvent event);
typedef EventPositionCallback = Future<void> Function(
    CalendarEvent event, Offset position);
typedef EventTimeCallback = Future<void> Function(
    CalendarEvent event, DateTime newStart, DateTime newEnd);

class CalendarController extends ChangeNotifier {
  /// Flag to indicate if events have changed
  bool _eventsChanged = false;
  bool get eventsChanged => _eventsChanged;

  final NavigationService _navigationService;
  final TimeService _timeService;
  Timer? _timer;

  final List<String> _visibleTimeZones;
  bool _showFloatingActionButton; // Changed to non-final to allow modification
  final bool _scrollToCurrentTimeOnLoad;
  bool _animateTimeScroll; // Changed to non-final to allow modification
  EventCallback? _onEventCreated; // Changed to non-final to allow modification
  EventCallback? _onEventTap; // Callback for event tap
  EventCallback? _onEventDoubleTap; // Callback for event double tap
  EventPositionCallback? _onEventLongPress; // Callback for event long press
  EventTimeCallback?
      _onEventRescheduled; // Changed to non-final to allow modification
  EventTimeCallback?
      _onEventResized; // Changed to non-final to allow modification
  int? _targetHour;
  final Map<CalendarViewType, double> _scrollPositions = {};
  bool _hasInitialScroll = false; // Add missing field
  final int firstDayOfWeek;

  late final CalendarPersistence _persistence;
  List<CalendarEvent>? _cachedEvents;
  bool _isLoading = false;
  bool _batchNotifications = false;
  final ValueNotifier<List<CalendarEvent>> _eventsNotifier =
      ValueNotifier<List<CalendarEvent>>([]);

  ValueNotifier<CalendarViewType> get _currentViewNotifier =>
      _navigationService.currentViewNotifier;

  // Expose necessary notifiers
  ValueNotifier<CalendarViewType> get currentViewNotifier =>
      _navigationService.currentViewNotifier;
  ValueNotifier<DateTime> get selectedDateNotifier =>
      _navigationService.selectedDateNotifier;
  ValueNotifier<DateTime> get startDateNotifier =>
      _navigationService.startDateNotifier;
  ValueNotifier<DateTime> get currentTimeNotifier =>
      _timeService.currentTimeNotifier;
  ValueNotifier<Duration> get intervalNotifier => _timeService.intervalNotifier;

  // Factory constructor to replace the removed create method
  /// Helper method to determine the first day of week based on locale
  static int getFirstDayOfWeekForLocale(String? languageCode) {
    // Default to Monday if no locale is provided
    if (languageCode == null) return DateTime.monday;

    // For most locales, the week starts on Monday (1)
    // For English (en) and a few others, the week starts on Sunday (7)
    switch (languageCode) {
      case 'en':
        return DateTime.sunday;
      case 'hi':
        // For Hindi, the week traditionally starts on Sunday
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
    // If firstDayOfWeek is not explicitly set, determine it based on locale
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

    // Initialize visible date range
    final dateRange = CalendarViewService()
        .dateRangeOfView(initialView, initialDate ?? DateTime.now());
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);

    _startTimer();
  }

  void _startTimer() {
    // Update immediately
    _timeService.currentTimeNotifier.value = DateTime.now();

    // Calculate delay to next minute
    final now = DateTime.now();
    final nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final delay = nextMinute.difference(now);

    // Initial timer to sync with minute boundary
    Timer(delay, () {
      _timeService.currentTimeNotifier.value = DateTime.now();

      // Then start periodic timer
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
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

  void _notifyIfNeeded() {
    if (!_batchNotifications) {
      notifyListeners();
    }
  }

  Future<void> _batchUpdate(Future<void> Function() updates) async {
    _batchNotifications = true;
    try {
      await updates();
    } finally {
      _batchNotifications = false;
      notifyListeners();
    }
  }

  get visibleDateRange => CalendarViewService().visibleDateRange;

  void setShowFloatingActionButton(bool show) {
    if (_showFloatingActionButton == show) return;
    _showFloatingActionButton = show;
    _notifyIfNeeded();
  }

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
    _cachedEvents = null;
    _notifyIfNeeded();
  }

  void changeView(CalendarViewType view) {
    final currentView = _navigationService.currentViewNotifier.value;

    // Only change if it's actually a different view
    if (currentView != view) {
      _navigationService.changeView(view);

      // Update visible date range for the new view
      final dateRange = CalendarViewService().dateRangeOfView(view, startDate);
      CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);

      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    _navigationService.selectDate(date);

    // Update visible date range for day view (since selectDate switches to day view)
    final dateRange =
        CalendarViewService().dateRangeOfView(CalendarViewType.day, date);
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);
  }

  void navigateToDate(DateTime date) {
    _navigationService.navigateToDate(date);

    // Update visible date range for the current view
    final dateRange = CalendarViewService().dateRangeOfView(currentView, date);
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);

    notifyListeners();
  }

  void navigateToNextPage() {
    _navigationService.navigateToNextPage();

    // Update visible date range after navigation
    final dateRange =
        CalendarViewService().dateRangeOfView(currentView, startDate);
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);

    notifyListeners();
  }

  void navigateToPreviousPage() {
    _navigationService.navigateToPreviousPage();

    // Update visible date range after navigation
    final dateRange =
        CalendarViewService().dateRangeOfView(currentView, startDate);
    CalendarViewService().setVisibleDateRange(dateRange[0], dateRange[1]);

    notifyListeners();
  }

  void setTargetHour(int? hour) {
    if (hour != null && (hour < 0 || hour > 23)) {
      throw ArgumentError('Hour must be between 0 and 23');
    }
    if (_targetHour == hour) return;
    _targetHour = hour;
    _notifyIfNeeded();
  }

  void setInterval(Duration interval) {
    intervalNotifier.value = interval;
  }

  get currentDateRange {
    return CalendarViewService().dateRangeOfView(currentView, startDate);
  }

  // Event Management
  Future<void> addEvent(CalendarEvent event) async {
    await _batchUpdate(() async {
      _isLoading = true;
      await _persistence.addEvent(event);
      _cachedEvents = null;
      _eventsChanged = true;

      if (_onEventCreated != null) {
        await _onEventCreated!(event);
      }
      _isLoading = false;
    });

    notifyListeners();
    _eventsChanged = false; // Reset flag after notification
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _batchUpdate(() async {
      _isLoading = true;
      await _persistence.updateEvent(event);
      _cachedEvents = null;
      _eventsChanged = true;
      _isLoading = false;
    });
    notifyListeners();
    _eventsChanged = false;
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    await _batchUpdate(() async {
      _isLoading = true;
      await _persistence.deleteEvent(event);
      _cachedEvents = null;
      _isLoading = false;
    });
  }

  Future<List<CalendarEvent>> getAllEvents() async {
    if (_cachedEvents != null) {
      return List.from(_cachedEvents!);
    }

    try {
      _isLoading = true;
      _cachedEvents = await _persistence.loadEvents();
      _eventsNotifier.value = List.from(_cachedEvents!);
      return List.from(_cachedEvents!);
    } finally {
      _isLoading = false;
    }
  }

  /// Adds multiple events efficiently.
  Future<void> addEvents(List<CalendarEvent> events) async {
    await _batchUpdate(() async {
      _isLoading = true;
      for (final event in events) {
        // Consider adding checks or specific logic per event if needed
        await _persistence.addEvent(event);
        if (_onEventCreated != null) {
          // Note: Calling onEventCreated for each might be slow for large batches
           await _onEventCreated!(event);
        }
      }
      _cachedEvents = null; // Invalidate cache
      _eventsChanged = true;
      _isLoading = false;
    });
    // Single notification after batch update
    notifyListeners();
    _eventsChanged = false;
  }

  Future<void> clearEvents() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _persistence.clearEvents();
      _cachedEvents = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rescheduleEvent(
      CalendarEvent event, DateTime newStart, DateTime newEnd) async {
    await _batchUpdate(() async {
      _isLoading = true;
      final updatedEvent = event.copyWith(
        start: newStart,
        end: newEnd,
      );

      await updateEvent(updatedEvent);

      if (_onEventRescheduled != null) {
        await _onEventRescheduled!(event, newStart, newEnd);
      }
      _isLoading = false;
    });
  }

  // TimeZone Management
  void addTimeZone(String timeZone) {
    if (!_visibleTimeZones.contains(timeZone)) {
      _visibleTimeZones.add(timeZone);
      notifyListeners();
    }
  }

  void removeTimeZone(String timeZone) {
    if (_visibleTimeZones.length > 1 && _visibleTimeZones.contains(timeZone)) {
      _visibleTimeZones.remove(timeZone);
      notifyListeners();
    }
  }

  // Cache Management
  void invalidateCache() {
    _cachedEvents = null;
    notifyListeners();
  }

  double? getScrollPosition(CalendarViewType view) {
    return _scrollPositions[view];
  }

  void setScrollPosition(CalendarViewType view, double position) {
    if (position != _scrollPositions[view]) {
      _scrollPositions[view] = position;
      // No need to notify here as this is just storing state
    }
  }

  // Add missing getter
  ValueNotifier<List<CalendarEvent>> get eventsNotifier => _eventsNotifier;

  bool get scrollToCurrentTimeOnLoad => _scrollToCurrentTimeOnLoad;

  bool get animateTimeScroll => _animateTimeScroll;

  void setAnimateTimeScroll(bool value) {
    if (_animateTimeScroll != value) {
      _animateTimeScroll = value;
      notifyListeners();
    }
  }

  // Define default start times for each day of the week
  final List<TimeOfDay> _startTimes = List.generate(
    7,
    (_) =>
        const TimeOfDay(hour: 8, minute: 0), // Default to 8:00 AM for all days
  );

  // Expose unmodifiable start times list

  /// Get events for a specific date range
  Future<List<CalendarEvent>> getEventsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final events = await _persistence.getEventsInRange(start, end);
    return events;
  }

  List<TimeOfDay> get defaultStartTimes => List.unmodifiable(_startTimes);

  // Get start time for a specific day
  TimeOfDay getStartTimeForDay(DateTime date) {
    final dayIndex = date.weekday - 1; // Convert 1-7 to 0-6
    return _startTimes[dayIndex];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _eventsNotifier.dispose();
    super.dispose();
  }
}
