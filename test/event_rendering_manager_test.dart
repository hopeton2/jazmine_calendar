import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jazmine_calendar/src/event_rendering/event_rendering_manager.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

void main() {
  group('EventRenderingManager', () {
    // Removed setUp and test for 'gridInfo not ready' as constructor enforces initialization

    test('should process events correctly', () {
      final now = DateTime(2023, 1, 1);
      // Initialize gridInfo directly
      final gridInfo = GridLayoutInfo(
        viewStart: now,
        viewEnd: now.add(const Duration(days: 1)),
        origin: const Offset(60, 40),
        availableSpace: const Size(300, 600),
        orientation: Axis.vertical,
        divisions: 1,
        cellWidth: 300,
        cellHeight: 25,
        intervalDuration: const Duration(minutes: 30),
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

      final manager = EventRenderingManager();
      final layoutInfos = manager.processEvents(
        events: events,
        minEventSize: 20,
        minSecondarySize: 20,
        gridInfo: gridInfo, // Pass gridInfo instance
      );

      expect(layoutInfos.length, 2);

      // Find events by ID
      final event1 = layoutInfos.firstWhere((e) => e.event.id == '1');
      final event2 = layoutInfos.firstWhere((e) => e.event.id == '2');

      // Check primary dimensions (from measurement)
      expect(event1.orientation, Axis.vertical);
      expect(event1.division, 0);
      expect(event1.start, closeTo(40 + (9 / 24) * 600, 1));
      expect(event1.primarySize, closeTo((1 / 24) * 600, 1));

      expect(event2.orientation, Axis.vertical);
      expect(event2.division, 0);
      expect(event2.start, closeTo(40 + (13 / 24) * 600, 1));
      expect(event2.primarySize, closeTo((2 / 24) * 600, 1));

      // Check secondary dimensions (from packing)
      expect(event1.secondaryStart, 0);
      expect(event1.secondarySize, 1.0);

      expect(event2.secondaryStart, 0);
      expect(event2.secondarySize, 1.0);
    });

    test('should use cache for repeated calls with same parameters', () {
      final now = DateTime(2023, 1, 1);
      // Initialize gridInfo directly
      final gridInfo = GridLayoutInfo(
        viewStart: now,
        viewEnd: now.add(const Duration(days: 1)),
        origin: const Offset(60, 40),
        availableSpace: const Size(300, 600),
        orientation: Axis.vertical,
        divisions: 1,
        cellWidth: 300,
        cellHeight: 25,
        intervalDuration: const Duration(minutes: 30),
      );

      final events = [
        CalendarEvent(
          id: '1',
          title: 'Test Event',
          start: now.add(const Duration(hours: 9)),
          end: now.add(const Duration(hours: 10)),
        ),
      ];

      final manager = EventRenderingManager();

      // First call should process events
      final firstResult = manager.processEvents(
        events: events,
        minEventSize: 20,
        minSecondarySize: 20,
        gridInfo: gridInfo, // Pass gridInfo instance
      );

      // Modify the result to check if the second call returns the same instance
      firstResult[0].secondaryStart = 0.5;

      // Second call with same parameters should return cached result
      final secondResult = manager.processEvents(
        events: events,
        minEventSize: 20,
        minSecondarySize: 20,
        gridInfo: gridInfo, // Pass gridInfo instance
      );

      // Should be the same instance
      expect(identical(firstResult, secondResult), true);
      expect(secondResult[0].secondaryStart, 0.5);

      // Clear cache
      manager.clearCache();

      // Third call should process events again
      final thirdResult = manager.processEvents(
        events: events,
        minEventSize: 20,
        minSecondarySize: 20,
        gridInfo: gridInfo, // Pass gridInfo instance
      );

      // Should be a different instance
      expect(identical(firstResult, thirdResult), false);
      expect(thirdResult[0].secondaryStart, 0);
    });

    test('should handle overlapping events', () {
      final now = DateTime(2023, 1, 1);
      // Initialize gridInfo directly
      final gridInfo = GridLayoutInfo(
        viewStart: now,
        viewEnd: now.add(const Duration(days: 1)),
        origin: const Offset(60, 40),
        availableSpace: const Size(300, 600),
        orientation: Axis.vertical,
        divisions: 1,
        cellWidth: 300,
        cellHeight: 25,
        intervalDuration: const Duration(minutes: 30),
      );

      final events = [
        CalendarEvent(
          id: '1',
          title: 'Event 1',
          start: now.add(const Duration(hours: 9)),
          end: now.add(const Duration(hours: 11)),
        ),
        CalendarEvent(
          id: '2',
          title: 'Event 2',
          start: now.add(const Duration(hours: 10)),
          end: now.add(const Duration(hours: 12)),
        ),
        CalendarEvent(
          id: '3',
          title: 'Event 3',
          start: now.add(const Duration(hours: 13)),
          end: now.add(const Duration(hours: 15)),
        ),
      ];

      final manager = EventRenderingManager();
      final layoutInfos = manager.processEvents(
        events: events,
        minEventSize: 20,
        minSecondarySize: 20,
        gridInfo: gridInfo, // Pass gridInfo instance
      );

      expect(layoutInfos.length, 3);

      // Find events by ID
      final event1 = layoutInfos.firstWhere((e) => e.event.id == '1');
      final event2 = layoutInfos.firstWhere((e) => e.event.id == '2');
      final event3 = layoutInfos.firstWhere((e) => e.event.id == '3');

      // Event 1 and Event 2 overlap, so they should be in different lanes
      expect(event1.secondaryStart, 0);
      expect(event1.secondarySize, 0.5);

      expect(event2.secondaryStart, 0.5);
      expect(event2.secondarySize, 0.5);

      // Event 3 doesn't overlap with others, but the packing algorithm
      // might still assign it a lane size based on the total number of lanes
      expect(event3.secondaryStart, 0);
      expect(event3.secondarySize, 0.5);
    });
  });
}
