import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../persistence/calendar_persistence.dart';
import '../persistence/shared_preferences_persistence.dart';

enum CalendarView {
  day,
  workWeek,
  week,
  month,
  agenda,
  timeline,
}

typedef EventCallback = Future<void> Function(Event event);
typedef EventTimeCallback = Future<void> Function(Event event, DateTime newStart, DateTime newEnd);

class JazmineCalendarController extends ChangeNotifier {
  CalendarPersistence _persistence;
  late final ValueNotifier<CalendarView> _currentViewNotifier;
  final ValueNotifier<DateTime> selectedDateNotifier;
  final ValueNotifier<DateTime> displayDateNotifier;
  final List<String> _visibleTimeZones;
  bool _showFloatingActionButton;
  EventCallback? _onEventCreated;
  EventTimeCallback? _onEventRescheduled;
  EventTimeCallback? _onEventResized;
  int? _targetHour;
  List<Event>? _cachedEvents;
  bool _isLoading = false;
  bool _batchNotifications = false;

  final ValueNotifier<List<Event>> _eventsNotifier = ValueNotifier<List<Event>>([]);
  ValueNotifier<CalendarView> get currentViewNotifier => _currentViewNotifier;
  
  static Future<JazmineCalendarController> create({
    CalendarPersistence? persistence,
    CalendarView initialView = CalendarView.week,
    DateTime? initialDate,
    List<String> visibleTimeZones = const ['UTC'],
    bool showFloatingActionButton = true,
    EventCallback? onEventCreated,
    EventTimeCallback? onEventRescheduled,
    EventTimeCallback? onEventResized,
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
  })  : _persistence = persistence,
        _currentViewNotifier = ValueNotifier<CalendarView>(initialView),
        selectedDateNotifier = ValueNotifier<DateTime>(initialDate),
        displayDateNotifier = ValueNotifier<DateTime>(displayDate),
        _visibleTimeZones = List.from(visibleTimeZones),
        _showFloatingActionButton = showFloatingActionButton,
        _onEventCreated = onEventCreated,
        _onEventRescheduled = onEventRescheduled,
        _onEventResized = onEventResized {
    // Initialize the notifier with the initial view
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
    _currentViewNotifier.value = view;
  }

  void selectDate(DateTime date) {
    selectedDateNotifier.value = date;
    if (currentView != CalendarView.day) {
      changeView(CalendarView.day);
    }
    notifyListeners();
  }

  void navigateToDate(DateTime date) {
    displayDateNotifier.value = date;
    notifyListeners();
  }

  void navigateToNextPage() {
    switch (currentView) {
      case CalendarView.day:
        displayDateNotifier.value = displayDateNotifier.value.add(const Duration(days: 1));
        break;
      case CalendarView.workWeek:
        displayDateNotifier.value = displayDateNotifier.value.add(const Duration(days: 5));
        break;
      case CalendarView.week:
        displayDateNotifier.value = displayDateNotifier.value.add(const Duration(days: 7));
        break;
      case CalendarView.month:
        // Fix: Properly handle month navigation
        final nextMonth = DateTime(displayDateNotifier.value.year, displayDateNotifier.value.month + 1, 1);
        displayDateNotifier.value = nextMonth;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void navigateToPreviousPage() {
    switch (currentView) {
      case CalendarView.day:
        displayDateNotifier.value = displayDateNotifier.value.subtract(const Duration(days: 1));
        break;
      case CalendarView.workWeek:
        displayDateNotifier.value = displayDateNotifier.value.subtract(const Duration(days: 5));
        break;
      case CalendarView.week:
        displayDateNotifier.value = displayDateNotifier.value.subtract(const Duration(days: 7));
        break;
      case CalendarView.month:
        // Fix: Properly handle month navigation
        final prevMonth = DateTime(displayDateNotifier.value.year, displayDateNotifier.value.month - 1, 1);
        displayDateNotifier.value = prevMonth;
        break;
      default:
        break;
    }
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

  Future<void> resizeEvent(Event event, DateTime newStart, DateTime newEnd) async {
    await _batchUpdate(() async {
      _isLoading = true;
      final updatedEvent = event.copyWith(
        start: newStart,
        end: newEnd,
      );

      await updateEvent(updatedEvent);

      if (_onEventResized != null) {
        await _onEventResized!(event, newStart, newEnd);
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

  @override
  void dispose() {
    _cachedEvents = null;
    super.dispose();
  }
}
