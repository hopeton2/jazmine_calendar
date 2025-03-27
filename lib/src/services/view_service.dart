import 'package:jazmine_calendar/src/constants/strings.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';

class ViewService {
  // Singleton instance
  static final ViewService _instance = ViewService._internal();

  // Factory constructor to return the same instance
  factory ViewService() {
    return _instance;
  }

  // Private constructor
  ViewService._internal();

  String getViewLabel(CalendarView view) {
    return switch (view) {
      CalendarView.day => CalendarStrings.dayViewLabel,
      CalendarView.workWeek => CalendarStrings.workWeekViewLabel,
      CalendarView.week => CalendarStrings.weekViewLabel,
      CalendarView.month => CalendarStrings.monthViewLabel,
      CalendarView.timeline => CalendarStrings.timelineViewLabel,
      CalendarView.agenda => CalendarStrings.agendaViewLabel,
    };
  }
}