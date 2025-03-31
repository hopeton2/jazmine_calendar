import 'package:dart_date/dart_date.dart';
import 'package:flutter/widgets.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/constants/strings.dart';

class CalendarViewService {
  // Singleton instance
  static final CalendarViewService _instance = CalendarViewService._internal();
  final Set<String> _initialScrollApplied = {};

  factory CalendarViewService() {
    return _instance;
  }

  static CalendarController? controller;
  // We don't need to store the month configuration here
  // The DateHelper.calendarDaysForMonth method will get it from the configuration parameter

  CalendarViewService._internal();

  static const configuration = MonthViewConfiguration();

  bool isDayView(CalendarViewType view) {
    return view == CalendarViewType.day ||
        view == CalendarViewType.week ||
        view == CalendarViewType.workWeek;
  }

  String getScrollStorageKey(CalendarViewType view) {
    if (isDayView(view)) {
      return 'day_view_scroll';
    }
    return '${view.toString()}_scroll';
  }

  void markInitialScrollApplied(CalendarViewType view) {
    _initialScrollApplied.add(getScrollStorageKey(view));
  }

  bool hasInitialScrollBeenApplied(CalendarViewType view) {
    return _initialScrollApplied.contains(getScrollStorageKey(view));
  }

  final List<DateTime> _visibleDateRange = [];
  get visibleDateRange => _visibleDateRange;

  setVisibleDateRange(DateTime startDate, DateTime endDate) {
    _visibleDateRange
      ..clear()
      ..addAll([startDate, endDate]);
  }

  String getViewLabel(CalendarViewType view, [BuildContext? context]) {
    // If context is provided, use localized strings
    if (context != null) {
      return switch (view) {
        CalendarViewType.day => CalendarStrings.dayViewLabel(context),
        CalendarViewType.workWeek => CalendarStrings.workWeekViewLabel(context),
        CalendarViewType.week => CalendarStrings.weekViewLabel(context),
        CalendarViewType.month => CalendarStrings.monthViewLabel(context),
        CalendarViewType.timeline => CalendarStrings.timelineViewLabel(context),
        CalendarViewType.agenda => CalendarStrings.agendaViewLabel(context),
      };
    }

    // Fallback to default English strings for backward compatibility
    return switch (view) {
      CalendarViewType.day => 'Day',
      CalendarViewType.workWeek => 'Work Week',
      CalendarViewType.week => 'Week',
      CalendarViewType.month => 'Month',
      CalendarViewType.timeline => 'Timeline',
      CalendarViewType.agenda => 'Agenda',
    };
  }

  List<DateTime> dateRangeOfView(CalendarViewType view, DateTime date) {
    if (view == CalendarViewType.month) {
      return monthViewDateRange(date);
    }

    final startDate = switch (view) {
      CalendarViewType.day => date,
      CalendarViewType.workWeek =>
        date.subtract(Duration(days: date.weekday - 1)),
      CalendarViewType.week => date.subtract(Duration(days: date.weekday - 1)),
      CalendarViewType.month => DateTime(date.year, date.month, 1),
      CalendarViewType.timeline => date,
      CalendarViewType.agenda => date,
    };

    final endDate = switch (view) {
      CalendarViewType.day => date,
      CalendarViewType.workWeek => startDate.add(const Duration(days: 4)),
      CalendarViewType.week => startDate.add(const Duration(days: 6)),
      CalendarViewType.month => DateTime(date.year, date.month + 1, 0),
      CalendarViewType.timeline => date,
      CalendarViewType.agenda => date,
    };

    return [startDate, endDate];
  }

  List<DateTime> monthViewDateRange(DateTime date) {
    // Ensure we're using the first day of the selected month
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);

    // For the end date, we need to include all days that should be visible
    // We use the extension method to get the end of the week containing the last day
    final endDate = lastDayOfMonth.endOfWeek;

    return [
      firstDay,
      endDate
    ]; // Return the first day of the month as the start date
  }
}
