import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

/// Utility class for adding sample events to the calendar
class SampleEvents {
  /// Add sample events to the calendar
  static Future<void> addSampleEvents(CalendarController controller) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Morning event
    await controller.addEvent(
      CalendarEvent(
        id: '1',
        title: 'Morning Meeting',
        start: today.add(const Duration(hours: 9)),
        end: today.add(const Duration(hours: 10)),
        color: Colors.blue,
      ),
    );
    
    // Afternoon event
    await controller.addEvent(
      CalendarEvent(
        id: '2',
        title: 'Lunch with Client',
        start: today.add(const Duration(hours: 12)),
        end: today.add(const Duration(hours: 13, minutes: 30)),
        color: Colors.green,
      ),
    );
    
    // All-day event
    await controller.addEvent(
      CalendarEvent(
        id: '3',
        title: 'Conference Day',
        start: today,
        end: today.add(const Duration(days: 1)),
        isAllDay: true,
        color: Colors.orange,
      ),
    );
    
    print('SampleEvents: Added sample events');
  }
}
