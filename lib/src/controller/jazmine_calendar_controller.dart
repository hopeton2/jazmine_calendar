import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jazmine_calendar/src/services/calendar_view_service.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/services/navigation_service.dart';
import 'package:jazmine_calendar/src/services/time_service.dart';
import '../models/event.dart';
import '../persistence/calendar_persistence.dart';
import '../persistence/shared_preferences_persistence.dart';

typedef EventCallback = Future<void> Function(Event event);
typedef EventTimeCallback = Future<void> Function(Event event, DateTime newStart, DateTime newEnd);

class JazmineCalendarController extends ChangeNotifier {
  final NavigationService _navigationService;
  final TimeService _timeService;
  Timer? _timer;
  
  final List<String> _visibleTimeZones;
  bool _showFloatingActionButton;
  EventCallback? _onEventCreated;
  EventTimeCallback? _onEventRescheduled;
  EventTimeCallback? _onEventResized;
  int? _targetHour;
  final Map<CalendarView, double> _scrollPositions = {};  // Changed from String to CalendarView
  
  // Add missing fields
  late CalendarPersistence _persistence;
  List<Event>? _cachedEvents;
  bool _isLoading = false;
  bool _batchNotifications = false;
  final ValueNotifier<List<Event>> _eventsNotifier = ValueNotifier<List<Event>>([]);

  // Fix currentViewNotifier reference
  ValueNotifier<CalendarView> get _currentViewNotifier => _navigationService.currentViewNotifier;

  // Expose necessary notifiers
  ValueNotifier<CalendarView> get currentViewNotifier => _navigationService.currentViewNotifier;
  ValueNotifier<DateTime> get selectedDateNotifier => _navigationService.selectedDateNotifier;
  ValueNotifier<DateTime> get displayDateNotifier => _navigationService.displayDateNotifier;
  ValueNotifier<DateTime> get currentTimeNotifier => _timeService.currentTimeNotifier;
  ValueNotifier<Duration> get intervalNotifier => _timeService.intervalNotifier;

  static Future<JazmineCalendarController> create({
    CalendarPersistence? persistence,
    CalendarView initialView = CalendarView.week,
    DateTime? initialDate,
    List<String> visibleTimeZones = const ['UTC'],
    bool showFloatingActionButton = true,
    EventCallback? onEventCreated,
    EventTimeCallback? onEventRescheduled,
    EventTimeCallback? onEventResized,
    Duration interval = const Duration(minutes: 30),
  }) async {
    final date = initialDate ?? DateTime.now();
    return JazmineCalendarController._(
      persistence: persistence ?? await SharedPreferencesPersistence.create(),
      initialView: initialView,
      initialDate: date,
      displayDate: date,
      visibleTimeZones: visibleTimeZones,
      showFloatingActionButton: showFloatingActionButton,
      onEventCreated: onEventCreated,
      onEventRescheduled: onEventRescheduled,
      onEventResized: onEventResized,
      interval: interval,
    );
  }

  JazmineCalendarController._({
    required CalendarPersistence persistence,
    required CalendarView initialView,
    required DateTime initialDate,
    required DateTime displayDate,
    List<String> visibleTimeZones = const ['UTC'],
    bool showFloatingActionButton = true,
    EventCallback? onEventCreated,
    EventTimeCallback? onEventRescheduled,
    EventTimeCallback? onEventResized,
    Duration interval = const Duration(minutes: 30),
  }) : _navigationService = NavigationService(
         initialDate: initialDate,
         initialView: initialView,
       ),
       _timeService = TimeService(interval: interval),
       _visibleTimeZones = List.from(visibleTimeZones),
       _showFloatingActionButton = showFloatingActionButton,
       _onEventCreated = onEventCreated,
       _onEventRescheduled = onEventRescheduled,
       _onEventResized = onEventResized {
    _persistence = persistence;
    _startTimer();
  }

  void _startTimer() {
    // Update immediately
    _timeService.currentTimeNotifier.value = DateTime.now();
    
    // Calculate delay to next minute
    final now = DateTime.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
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
  CalendarView get currentView => _currentViewNotifier.value;
  DateTime get selectedDate => selectedDateNotifier.value;
  DateTime get displayDate => displayDateNotifier.value;
  List<String> get visibleTimeZones => List.unmodifiable(_visibleTimeZones);
  bool get showFloatingActionButton => _showFloatingActionButton;
  EventCallback? get onEventCreated => _onEventCreated;
  EventTimeCallback? get onEventRescheduled => _onEventRescheduled;
  EventTimeCallback? get onEventResized => _onEventResized;
  int? get targetHour => _targetHour;
  bool get isLoading => _isLoading;

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

  // UI State Setters
  void setShowFloatingActionButton(bool show) {
    if (_showFloatingActionButton == show) return;
    _showFloatingActionButton = show;
    _notifyIfNeeded();
  }

  void setOnEventCreated(EventCallback? callback) {
    _onEventCreated = callback;
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

  void changeView(CalendarView view) {
    // Store current scroll position for current view
    final currentView = _navigationService.currentViewNotifier.value;
    
    // Only change if it's actually a different view
    if (currentView != view) {
      _navigationService.changeView(view);
      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    _navigationService.selectDate(date);
  }

  void navigateToDate(DateTime date) {
    _navigationService.navigateToDate(date);
    notifyListeners();
  }

  void navigateToNextPage() {
    _navigationService.navigateToNextPage();
    notifyListeners();
  }

  void navigateToPreviousPage() {
    _navigationService.navigateToPreviousPage();
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

  // Event Management
  Future<void> addEvent(Event event) async {
    await _batchUpdate(() async {
      _isLoading = true;
      await _persistence.addEvent(event);
      _cachedEvents = null;
      
      if (_onEventCreated != null) {
        await _onEventCreated!(event);
      }
      _isLoading = false;
    });
  }

  Future<void> updateEvent(Event event) async {
    await _batchUpdate(() async {
      _isLoading = true;
      await _persistence.updateEvent(event);
      _cachedEvents = null;
      _isLoading = false;
    });
  }

  Future<void> deleteEvent(Event event) async {
    await _batchUpdate(() async {
      _isLoading = true;
      await _persistence.deleteEvent(event);
      _cachedEvents = null;
      _isLoading = false;
    });
  }

  Future<List<Event>> getAllEvents() async {
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

  Future<void> rescheduleEvent(Event event, DateTime newStart, DateTime newEnd) async {
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

  double? getScrollPosition(CalendarView view) {
    return _scrollPositions[view];
  }

  void setScrollPosition(CalendarView view, double position) {
    if (position != _scrollPositions[view]) {
      _scrollPositions[view] = position;
      // No need to notify here as this is just storing state
    }
  }

  // Add missing getter
  ValueNotifier<List<Event>> get eventsNotifier => _eventsNotifier;

  @override
  void dispose() {
    _timer?.cancel();
    _eventsNotifier.dispose();
    super.dispose();
  }
}
