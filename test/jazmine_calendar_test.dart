import 'package:flutter_test/flutter_test.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';

void main() {
  group('JazmineCalendarController', () {
    test('creates with default values', () async {
      final controller = await CalendarController.create();
      expect(controller.currentView, equals(CalendarViewType.day));
      expect(controller.visibleTimeZones, equals(['UTC']));
    });

    test('adds and retrieves events', () async {
      final controller = await CalendarController.create();
      final event = CalendarEvent(
        id: 'test-event-1',
        title: 'Test Event',
        start: DateTime(2024, 1, 1, 9),
        end: DateTime(2024, 1, 1, 10),
        timeZone: 'UTC',
      );

      await controller.addEvent(event);
      final events = await controller.getAllEvents();

      expect(events.length, equals(1));
      expect(events.first.title, equals('Test Event'));
    });
  });
}
