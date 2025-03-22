import 'package:flutter/widgets.dart';

import '../../jazmine_calendar.dart';

class BaseDayViewModel extends ChangeNotifier {
  final JazmineCalendarController controller;
  
  BaseDayViewModel(this.controller);

  List<Event> getAllDayEventsForDate(List<Event> events, DateTime date) {
    return events.where((event) {
      if (!event.isAllDay) return false;
      final eventStart = DateTime(event.start.year, event.start.month, event.start.day);
      final eventEnd = DateTime(event.end.year, event.end.month, event.end.day);
      return date.isAfter(eventStart.subtract(const Duration(days: 1))) && 
             date.isBefore(eventEnd.add(const Duration(days: 1)));
    }).toList();
  }

  List<Event> getEventsForDate(List<Event> events, DateTime date) {
    return events.where((event) {
      if (event.isAllDay) return false;
      final eventStart = DateTime(event.start.year, event.start.month, event.start.day);
      return date.year == eventStart.year && 
             date.month == eventStart.month && 
             date.day == eventStart.day;
    }).toList();
  }

  bool isFirstDayOfEvent(Event event, DateTime date) {
    return event.start.year == date.year && 
           event.start.month == date.month && 
           event.start.day == date.day;
  }

  bool isLastDayOfEvent(Event event, DateTime date) {
    return event.end.year == date.year && 
           event.end.month == date.month && 
           event.end.day == date.day;
  }
}