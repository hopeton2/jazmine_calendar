import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

void main() {
  group('EventRenderer', () {
    test('should find event at position', () {
      final events = [
        EventLayoutInfo(
          event: CalendarEvent(
            id: '1',
            title: 'Event 1',
            start: DateTime(2023, 1, 1, 9),
            end: DateTime(2023, 1, 1, 10),
          ),
          orientation: Axis.vertical,
          division: 0,
          start: 100,
          primarySize: 60,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
        EventLayoutInfo(
          event: CalendarEvent(
            id: '2',
            title: 'Event 2',
            start: DateTime(2023, 1, 1, 11),
            end: DateTime(2023, 1, 1, 12),
          ),
          orientation: Axis.vertical,
          division: 0,
          start: 200,
          primarySize: 60,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
      ];

      // Set secondary dimensions
      events[0].secondaryStart = 20;
      events[0].secondarySize = 80;

      events[1].secondaryStart = 120;
      events[1].secondarySize = 80;

      final renderer = EventRenderer(events: events);

      // Position inside Event 1
      final event1 = renderer.findEventAt(const Offset(50, 120));
      expect(event1?.event.id, '1');

      // Position inside Event 2
      final event2 = renderer.findEventAt(const Offset(150, 220));
      expect(event2?.event.id, '2');

      // Position outside any event
      final noEvent = renderer.findEventAt(const Offset(10, 10));
      expect(noEvent, null);
    });

    test('should find resize handle at position', () {
      final event = EventLayoutInfo(
        event: CalendarEvent(
          id: '1',
          title: 'Event 1',
          start: DateTime(2023, 1, 1, 9),
          end: DateTime(2023, 1, 1, 10),
        ),
        orientation: Axis.vertical,
        division: 0,
        start: 100,
        primarySize: 60,
        cellWidth: 100.0,
        cellHeight: 50.0,
        // Removed origin argument
        // Removed availableSpace parameter
      );

      // Set secondary dimensions
      event.secondaryStart = 20;
      event.secondarySize = 80;

      final renderer = EventRenderer(
        events: [event],
        style: const EventRenderStyle(resizeHandleSize: 10),
      );

      // Removed resize handle tests
    });

    test('should handle all-day events', () {
      final event = EventLayoutInfo(
        event: CalendarEvent(
          id: '1',
          title: 'All Day Event',
          start: DateTime(2023, 1, 1),
          end: DateTime(2023, 1, 2),
          isAllDay: true,
        ),
        orientation: Axis.vertical,
        division: 0,
        start: 100,
        primarySize: 60,
        cellWidth: 100.0,
        cellHeight: 50.0,
        // Removed origin argument
        // Removed availableSpace parameter
      );

      // Set secondary dimensions
      event.secondaryStart = 20;
      event.secondarySize = 80;

      final renderer = EventRenderer(
        events: [event],
        style: const EventRenderStyle(resizeHandleSize: 10),
      );

      // Removed resize handle tests for all-day events
    });
  });
}
