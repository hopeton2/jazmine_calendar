import 'package:dart_date/dart_date.dart';
import 'package:jazmine_calendar/src/constants/strings.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/views/configurations.dart';

class CalendarViewService {
  // Singleton instance
  static final CalendarViewService _instance = CalendarViewService._internal();
  final Set<String> _initialScrollApplied = {};

  factory CalendarViewService() {
    return _instance;
  }

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

  String getViewLabel(CalendarViewType view) {
    return switch (view) {
      CalendarViewType.day => CalendarStrings.dayViewLabel,
      CalendarViewType.workWeek => CalendarStrings.workWeekViewLabel,
      CalendarViewType.week => CalendarStrings.weekViewLabel,
      CalendarViewType.month => CalendarStrings.monthViewLabel,
      CalendarViewType.timeline => CalendarStrings.timelineViewLabel,
      CalendarViewType.agenda => CalendarStrings.agendaViewLabel,
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
    final firstDayOfWeek = configuration.firstDayOfWeek;
    final firstDay = date.firstDayOfMonth;
    final lastDayOfMonth = date.lastDayOfMonth;
    final startDate = firstDay.getWeekStartDate(firstDayOfWeek);
    //final weekCount = startDate.weeksBetween(lastDayOfMonth);
    final endDate = lastDayOfMonth.endOfWeek;

    return [startDate, endDate];
  }
}
