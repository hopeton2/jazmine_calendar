import 'package:flutter/widgets.dart';

import '../../jazmine_calendar.dart';

class BaseDayViewModel extends ChangeNotifier {
  final CalendarController controller;

  BaseDayViewModel(this.controller);

  List<CalendarEvent> getAllDayEventsForDate(
      List<CalendarEvent> events, DateTime date) {
    return events.where((event) {
      if (!event.isAllDay) return false;
      final eventStart =
          DateTime(event.start.year, event.start.month, event.start.day);
      final eventEnd = DateTime(event.end.year, event.end.month, event.end.day);
      return date.isAfter(eventStart.subtract(const Duration(days: 1))) &&
          date.isBefore(eventEnd.add(const Duration(days: 1)));
    }).toList();
  }

  List<CalendarEvent> getEventsForDate(
      List<CalendarEvent> events, DateTime date) {
    return events.where((event) {
      if (event.isAllDay) return false;
      final eventStart =
          DateTime(event.start.year, event.start.month, event.start.day);
      return date.year == eventStart.year &&
          date.month == eventStart.month &&
          date.day == eventStart.day;
    }).toList();
  }

  List<CalendarEvent> getEventsForDateRange(
      List<CalendarEvent> events, DateTime startDate, DateTime endDate) {
    return events.where((event) {
      final eventStart =
          DateTime(event.start.year, event.start.month, event.start.day);
      return eventStart.isAfter(startDate.subtract(const Duration(days: 1))) &&
          eventStart.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  bool isFirstDayOfEvent(CalendarEvent event, DateTime date) {
    return event.start.year == date.year &&
        event.start.month == date.month &&
        event.start.day == date.day;
  }

  bool isLastDayOfEvent(CalendarEvent event, DateTime date) {
    return event.end.year == date.year &&
        event.end.month == date.month &&
        event.end.day == date.day;
  }
}
