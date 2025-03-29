import 'package:flutter/foundation.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  final ValueNotifier<DateTime> selectedDateNotifier;
  final ValueNotifier<DateTime> startDateNotifier;
  final ValueNotifier<CalendarViewType> currentViewNotifier;

  factory NavigationService({
    DateTime? initialDate,
    CalendarViewType initialView = CalendarViewType.week,
  }) {
    _instance._initialize(initialDate, initialView);
    return _instance;
  }

  NavigationService._internal()
      : selectedDateNotifier = ValueNotifier(DateTime.now()),
        startDateNotifier = ValueNotifier(DateTime.now()),
        currentViewNotifier = ValueNotifier(CalendarViewType.week);

  void _initialize(DateTime? initialDate, CalendarViewType initialView) {
    final date = initialDate ?? DateTime.now();
    selectedDateNotifier.value = date;
    startDateNotifier.value = date;
    currentViewNotifier.value = initialView;
  }

  static NavigationService get instance => _instance;

  void changeView(CalendarViewType view) {
    currentViewNotifier.value = view;
  }

  void selectDate(DateTime date) {
    selectedDateNotifier.value = date;
    startDateNotifier.value =
        date; // Also update display date when selecting a date
    if (currentViewNotifier.value != CalendarViewType.day) {
      changeView(CalendarViewType.day);
    }
  }

  void navigateToDate(DateTime date) {
    if (currentViewNotifier.value == CalendarViewType.day) {
      selectedDateNotifier.value = date; // Update selected date for day view
    }
    startDateNotifier.value = date;
  }

  void navigateToNextPage() {
    _navigatePage(forward: true);
  }

  void navigateToPreviousPage() {
    _navigatePage(forward: false);
  }

  void _navigatePage({required bool forward}) {
    final date = currentViewNotifier.value == CalendarViewType.day
        ? selectedDateNotifier.value
        : startDateNotifier.value;

    final newDate = switch (currentViewNotifier.value) {
      CalendarViewType.day => date.add(Duration(days: forward ? 1 : -1)),
      CalendarViewType.workWeek => date.add(Duration(days: forward ? 5 : -5)),
      CalendarViewType.week => date.add(Duration(days: forward ? 7 : -7)),
      CalendarViewType.month =>
        DateTime(date.year, date.month + (forward ? 1 : -1), 1),
      CalendarViewType.timeline => date.add(Duration(days: forward ? 1 : -1)),
      CalendarViewType.agenda => date.add(Duration(days: forward ? 1 : -1)),
    };

    if (currentViewNotifier.value == CalendarViewType.day) {
      selectedDateNotifier.value = newDate;
    }
    startDateNotifier.value = newDate;
  }
}
