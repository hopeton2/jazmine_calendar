import 'package:flutter/foundation.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  
  final ValueNotifier<DateTime> selectedDateNotifier;
  final ValueNotifier<DateTime> displayDateNotifier;
  final ValueNotifier<CalendarView> currentViewNotifier;
  final Map<String, double> _scrollPositions = {};


  factory NavigationService({
    DateTime? initialDate,
    CalendarView initialView = CalendarView.week,
  }) {
    _instance._initialize(initialDate, initialView);
    return _instance;
  }

  NavigationService._internal()
      : selectedDateNotifier = ValueNotifier(DateTime.now()),
        displayDateNotifier = ValueNotifier(DateTime.now()),
        currentViewNotifier = ValueNotifier(CalendarView.week);

  void _initialize(DateTime? initialDate, CalendarView initialView) {
    final date = initialDate ?? DateTime.now();
    selectedDateNotifier.value = date;
    displayDateNotifier.value = date;
    currentViewNotifier.value = initialView;
  }

  static NavigationService get instance => _instance;

  void changeView(CalendarView view) {
    currentViewNotifier.value = view;
  }

  void selectDate(DateTime date) {
    selectedDateNotifier.value = date;
    displayDateNotifier.value = date;  // Also update display date when selecting a date
    if (currentViewNotifier.value != CalendarView.day) {
      changeView(CalendarView.day);
    }
  }

  void navigateToDate(DateTime date) {
    if (currentViewNotifier.value == CalendarView.day) {
      selectedDateNotifier.value = date;  // Update selected date for day view
    }
    displayDateNotifier.value = date;
  }


  void navigateToNextPage() {
    _navigatePage(forward: true);
  }

  void navigateToPreviousPage() {
    _navigatePage(forward: false);
  }

  void _navigatePage({required bool forward}) {
    final date = currentViewNotifier.value == CalendarView.day 
        ? selectedDateNotifier.value 
        : displayDateNotifier.value;
        
    final newDate = switch (currentViewNotifier.value) {
      CalendarView.day => date.add(Duration(days: forward ? 1 : -1)),
      CalendarView.workWeek => date.add(Duration(days: forward ? 5 : -5)),
      CalendarView.week => date.add(Duration(days: forward ? 7 : -7)),
      CalendarView.month => DateTime(date.year, date.month + (forward ? 1 : -1), 1),
      CalendarView.timeline => date.add(Duration(days: forward ? 1 : -1)),
      CalendarView.agenda => date.add(Duration(days: forward ? 1 : -1)),
    };

    if (currentViewNotifier.value == CalendarView.day) {
      selectedDateNotifier.value = newDate;
    }
    displayDateNotifier.value = newDate;
  }
}
