import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_service.dart';
import 'package:jazmine_calendar/src/event_rendering/event_packing_service.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart'; // Renamed import
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart'; // Added import

void main() {
  group('EventLayoutInfo', () {
    test(
        'should calculate convenience getters correctly for vertical orientation',
        () {
      final event = CalendarEvent(
        id: '1',
        title: 'Test Event',
        start: DateTime(2023, 1, 1, 10),
        end: DateTime(2023, 1, 1, 11),
      );

      final layoutInfo = EventLayoutInfo(
        event: event,
        orientation: Axis.vertical,
        division: 0,
        start: 100,
        primarySize: 60,
        cellWidth: 100.0,
        cellHeight: 50.0,
        // Removed origin argument
        // Removed availableSpace parameter
      );

      layoutInfo.secondaryStart = 20;
      layoutInfo.secondarySize = 80;

      expect(layoutInfo.top, 100);
      expect(layoutInfo.left, 20);
      expect(layoutInfo.width, 80);
      expect(layoutInfo.height, 60);
      expect(layoutInfo.finalRect, Rect.fromLTWH(20, 100, 80, 60));
    });

    test(
        'should calculate convenience getters correctly for horizontal orientation',
        () {
      final event = CalendarEvent(
        id: '1',
        title: 'Test Event',
        start: DateTime(2023, 1, 1, 10),
        end: DateTime(2023, 1, 1, 11),
      );

      final layoutInfo = EventLayoutInfo(
        event: event,
        orientation: Axis.horizontal,
        division: 0,
        start: 100,
        primarySize: 60,
        cellWidth: 100.0,
        cellHeight: 50.0,
        // Removed origin argument
        // Removed availableSpace parameter
      );

      layoutInfo.secondaryStart = 20;
      layoutInfo.secondarySize = 80;

      expect(layoutInfo.top, 20);
      expect(layoutInfo.left, 100);
      expect(layoutInfo.width, 60);
      expect(layoutInfo.height, 80);
      expect(layoutInfo.finalRect, Rect.fromLTWH(100, 20, 60, 80));
    });

    test('should detect overlaps correctly', () {
      final event1 = CalendarEvent(
        id: '1',
        title: 'Event 1',
        start: DateTime(2023, 1, 1, 10),
        end: DateTime(2023, 1, 1, 12),
      );

      final event2 = CalendarEvent(
        id: '2',
        title: 'Event 2',
        start: DateTime(2023, 1, 1, 11),
        end: DateTime(2023, 1, 1, 13),
      );

      final event3 = CalendarEvent(
        id: '3',
        title: 'Event 3',
        start: DateTime(2023, 1, 1, 13),
        end: DateTime(2023, 1, 1, 14),
      );

      final layout1 = EventLayoutInfo(
        event: event1,
        orientation: Axis.vertical,
        division: 0,
        start: 100,
        primarySize: 120,
        cellWidth: 100.0,
        cellHeight: 50.0,
        // Removed origin argument
        // Removed availableSpace parameter
      );

      final layout2 = EventLayoutInfo(
        event: event2,
        orientation: Axis.vertical,
        division: 0,
        start: 160,
        primarySize: 120,
        cellWidth: 100.0,
        cellHeight: 50.0,
        // Removed origin argument
        // Removed availableSpace parameter
      );

      final layout3 = EventLayoutInfo(
        event: event3,
        orientation: Axis.vertical,
        division: 0,
        start: 250,
        primarySize: 60,
        cellWidth: 100.0,
        cellHeight: 50.0,
        // Removed origin argument
        // Removed availableSpace parameter
      );

      final layout4 = EventLayoutInfo(
        event: event2,
        orientation: Axis.vertical,
        division: 1, // Different division
        start: 160,
        primarySize: 120,
        cellWidth: 100.0,
        cellHeight: 50.0,
        // Removed origin argument
        // Removed availableSpace parameter
      );

      expect(layout1.overlapsWith(layout2), true);
      expect(layout2.overlapsWith(layout1), true);
      expect(layout1.overlapsWith(layout3), false);
      expect(layout2.overlapsWith(layout3), true); // They overlap at 13:00
      expect(layout1.overlapsWith(layout4), false); // Different division
    });
  });

  group('EventLayoutService', () {
    test('should measure events correctly for vertical orientation', () {
      final broker = GridLayoutInfo(); // Renamed class
      final now = DateTime(2023, 1, 1);

      broker.updateGridLayout(
        viewStart: now,
        viewEnd: now.add(const Duration(days: 1)),
        origin: const Offset(60, 40),
        availableSpace: const Size(300, 600),
        orientation: Axis.vertical,
        divisions: 1,
        cellWidth: 300,
        cellHeight: 25,
      );

      final events = [
        CalendarEvent(
          id: '1',
          title: 'Morning Event',
          start: now.add(const Duration(hours: 9)),
          end: now.add(const Duration(hours: 10)),
        ),
        CalendarEvent(
          id: '2',
          title: 'Afternoon Event',
          start: now.add(const Duration(hours: 13)),
          end: now.add(const Duration(hours: 15)),
        ),
      ];

      final service = EventLayoutService();
      final layoutInfos = service.measureEvents(
        events: events,
        gridInfo: broker, // Pass broker instance
        minEventSize: 20,
      );

      expect(layoutInfos.length, 2);

      // Morning event (9-10 AM)
      expect(layoutInfos[0].event.id, '1');
      expect(layoutInfos[0].orientation, Axis.vertical);
      expect(layoutInfos[0].division, 0);
      // Expect position relative to content area (0,0) based on local time interval calculation
      expect(
          layoutInfos[0].start,
          closeTo(225,
              1)); // (9 * 60 mins / 60 min_interval) * 25 pixels_per_interval
      expect(
          layoutInfos[0].primarySize,
          closeTo(25,
              1)); // (60 min_duration / 60 min_interval) * 25 pixels_per_interval

      // Afternoon event (1-3 PM)
      expect(layoutInfos[1].event.id, '2');
      expect(layoutInfos[1].orientation, Axis.vertical);
      expect(layoutInfos[1].division, 0);
      // Expect position relative to content area (0,0) based on local time interval calculation
      expect(
          layoutInfos[1].start,
          closeTo(325,
              1)); // (13 * 60 mins / 60 min_interval) * 25 pixels_per_interval
      expect(
          layoutInfos[1].primarySize,
          closeTo(50,
              1)); // (120 min_duration / 60 min_interval) * 25 pixels_per_interval
    });

    test('should measure events correctly for horizontal orientation', () {
      final broker = GridLayoutInfo(); // Renamed class (Already updated)
      final now = DateTime(2023, 1, 1);

      broker.updateGridLayout(
        viewStart: now,
        viewEnd: now.add(const Duration(days: 1)),
        origin: const Offset(60, 40),
        availableSpace: const Size(600, 300),
        orientation: Axis.horizontal,
        divisions: 1,
        cellWidth: 25,
        cellHeight: 300,
      );

      final events = [
        CalendarEvent(
          id: '1',
          title: 'Morning Event',
          start: now.add(const Duration(hours: 9)),
          end: now.add(const Duration(hours: 10)),
        ),
        CalendarEvent(
          id: '2',
          title: 'Afternoon Event',
          start: now.add(const Duration(hours: 13)),
          end: now.add(const Duration(hours: 15)),
        ),
      ];

      final service = EventLayoutService();
      final layoutInfos = service.measureEvents(
        events: events,
        gridInfo: broker, // Pass broker instance
        minEventSize: 20,
      );

      expect(layoutInfos.length, 2);

      // Morning event (9-10 AM)
      expect(layoutInfos[0].event.id, '1');
      expect(layoutInfos[0].orientation, Axis.horizontal);
      expect(layoutInfos[0].division, 0);
      // Expect position relative to content area (0,0) based on local time interval calculation
      expect(
          layoutInfos[0].start,
          closeTo(225,
              1)); // (9 * 60 mins / 60 min_interval) * 25 pixels_per_interval
      expect(
          layoutInfos[0].primarySize,
          closeTo(25,
              1)); // (60 min_duration / 60 min_interval) * 25 pixels_per_interval

      // Afternoon event (1-3 PM)
      expect(layoutInfos[1].event.id, '2');
      expect(layoutInfos[1].orientation, Axis.horizontal);
      expect(layoutInfos[1].division, 0);
      // Expect position relative to content area (0,0) based on local time interval calculation
      expect(
          layoutInfos[1].start,
          closeTo(325,
              1)); // (13 * 60 mins / 60 min_interval) * 25 pixels_per_interval
      expect(
          layoutInfos[1].primarySize,
          closeTo(50,
              1)); // (120 min_duration / 60 min_interval) * 25 pixels_per_interval
    });
  });

  group('EventPackingService', () {
    test('should pack events correctly for vertical orientation', () {
      final events = [
        CalendarEvent(
          id: '1',
          title: 'Event 1',
          start: DateTime(2023, 1, 1, 9),
          end: DateTime(2023, 1, 1, 11),
        ),
        CalendarEvent(
          id: '2',
          title: 'Event 2',
          start: DateTime(2023, 1, 1, 10),
          end: DateTime(2023, 1, 1, 12),
        ),
        CalendarEvent(
          id: '3',
          title: 'Event 3',
          start: DateTime(2023, 1, 1, 13),
          end: DateTime(2023, 1, 1, 15),
        ),
      ];

      final layoutInfos = [
        EventLayoutInfo(
          event: events[0],
          orientation: Axis.vertical,
          division: 0,
          start: 100,
          primarySize: 120,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
        EventLayoutInfo(
          event: events[1],
          orientation: Axis.vertical,
          division: 0,
          start: 160,
          primarySize: 120,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
        EventLayoutInfo(
          event: events[2],
          orientation: Axis.vertical,
          division: 0,
          start: 300,
          primarySize: 120,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
      ];

      final service = EventPackingService();
      final packedEvents = service.packEvents(
        events: layoutInfos,
        minSecondarySize: 20,
        style: const EventRenderStyle(), // Added default style
        visibleDates: [], // Pass empty list for test
      );

      expect(packedEvents.length, 3);

      // Find events by ID
      final event1 = packedEvents.firstWhere((e) => e.event.id == '1');
      final event2 = packedEvents.firstWhere((e) => e.event.id == '2');
      final event3 = packedEvents.firstWhere((e) => e.event.id == '3');

      // Event 1 and Event 3 should be in different lanes
      expect(event1.secondaryStart, 0);
      expect(event1.secondarySize, 0.5);

      expect(event3.secondaryStart, 0);
      expect(event3.secondarySize, 0.5);

      // Event 2 should be in a different lane from Event 1
      expect(event2.secondaryStart, 0.5);
      expect(event2.secondarySize, 0.5);
    });

    test('should pack events correctly for horizontal orientation', () {
      final events = [
        CalendarEvent(
          id: '1',
          title: 'Event 1',
          start: DateTime(2023, 1, 1, 9),
          end: DateTime(2023, 1, 1, 11),
        ),
        CalendarEvent(
          id: '2',
          title: 'Event 2',
          start: DateTime(2023, 1, 1, 10),
          end: DateTime(2023, 1, 1, 12),
        ),
        CalendarEvent(
          id: '3',
          title: 'Event 3',
          start: DateTime(2023, 1, 1, 13),
          end: DateTime(2023, 1, 1, 15),
        ),
      ];

      final layoutInfos = [
        EventLayoutInfo(
          event: events[0],
          orientation: Axis.horizontal,
          division: 0,
          start: 100,
          primarySize: 120,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
        EventLayoutInfo(
          event: events[1],
          orientation: Axis.horizontal,
          division: 0,
          start: 160,
          primarySize: 120,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
        EventLayoutInfo(
          event: events[2],
          orientation: Axis.horizontal,
          division: 0,
          start: 300,
          primarySize: 120,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
      ];

      final service = EventPackingService();
      final packedEvents = service.packEvents(
        events: layoutInfos,
        minSecondarySize: 20,
        style: const EventRenderStyle(), // Added default style
        visibleDates: [], // Pass empty list for test
      );

      expect(packedEvents.length, 3);

      // Find events by ID
      final event1 = packedEvents.firstWhere((e) => e.event.id == '1');
      final event2 = packedEvents.firstWhere((e) => e.event.id == '2');
      final event3 = packedEvents.firstWhere((e) => e.event.id == '3');

      // Event 1 and Event 3 should be in different lanes
      expect(event1.secondaryStart, 0);
      expect(event1.secondarySize, 0.5);

      expect(event3.secondaryStart, 0);
      expect(event3.secondarySize, 0.5);

      // Event 2 should be in a different lane from Event 1
      expect(event2.secondaryStart, 0.5);
      expect(event2.secondarySize, 0.5);
    });

    test('should handle events in different divisions', () {
      final events = [
        CalendarEvent(
          id: '1',
          title: 'Event 1 (Division 0)',
          start: DateTime(2023, 1, 1, 9),
          end: DateTime(2023, 1, 1, 11),
        ),
        CalendarEvent(
          id: '2',
          title: 'Event 2 (Division 0)',
          start: DateTime(2023, 1, 1, 10),
          end: DateTime(2023, 1, 1, 12),
        ),
        CalendarEvent(
          id: '3',
          title: 'Event 3 (Division 1)',
          start: DateTime(2023, 1, 1, 9),
          end: DateTime(2023, 1, 1, 11),
        ),
      ];

      final layoutInfos = [
        EventLayoutInfo(
          event: events[0],
          orientation: Axis.vertical,
          division: 0,
          start: 100,
          primarySize: 120,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
        EventLayoutInfo(
          event: events[1],
          orientation: Axis.vertical,
          division: 0,
          start: 160,
          primarySize: 120,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
        EventLayoutInfo(
          event: events[2],
          orientation: Axis.vertical,
          division: 1,
          start: 100,
          primarySize: 120,
          cellWidth: 100.0,
          cellHeight: 50.0,
          // Removed origin argument
          // Removed availableSpace parameter
        ),
      ];

      final service = EventPackingService();
      final packedEvents = service.packEvents(
        events: layoutInfos,
        minSecondarySize: 20,
        style: const EventRenderStyle(), // Added default style
        visibleDates: [], // Pass empty list for test
      );

      expect(packedEvents.length, 3);

      // Find events by ID and division
      final event1 = packedEvents.firstWhere((e) => e.event.id == '1');
      final event2 = packedEvents.firstWhere((e) => e.event.id == '2');
      final event3 = packedEvents.firstWhere((e) => e.event.id == '3');

      // Division 0: Event 1 and Event 2 should be in separate lanes
      expect(event1.division, 0);
      expect(event1.secondaryStart, 0);
      expect(event1.secondarySize, 0.5);

      expect(event2.division, 0);
      expect(event2.secondaryStart, 0.5);
      expect(event2.secondarySize, 0.5);

      // Division 1: Event 3 should be in its own lane
      expect(event3.division, 1);
      expect(event3.secondaryStart, 0);
      expect(event3.secondarySize, 1.0);
    });
  });
}
