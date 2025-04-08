import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_service.dart';
import 'package:jazmine_calendar/src/event_rendering/event_packing_service.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart'; // Renamed import
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart'; // Added import
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // Import for date extensions

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
      );

      // Simulate packing results
      layoutInfo.secondaryStart = 0.2; // Relative position (20% from left)
      layoutInfo.secondarySize = 0.8; // Relative width (80% of cell width)
      layoutInfo.columnSpan = 1;
      layoutInfo.laneIndex = 0;

      expect(layoutInfo.top, 100); // Primary start
      expect(layoutInfo.left, 20.0); // secondaryStart * cellWidth
      expect(layoutInfo.width, 80.0); // secondarySize * cellWidth
      expect(layoutInfo.height, 60); // Primary size
      expect(layoutInfo.finalRect, Rect.fromLTWH(20.0, 100, 80.0, 60));
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
        division: 0, // Starting division
        start: 100, // Primary start (left pixel offset)
        primarySize: 60, // Primary size (width in pixels) - This is now ignored for width calculation
        cellWidth: 100.0, // Width of one division/day column
        cellHeight: 50.0, // Height of the all-day area
      );

      // Simulate packing results for horizontal
      layoutInfo.secondaryStart = 10.0; // Top pixel offset
      layoutInfo.secondarySize = 25.0; // Fixed pixel height
      layoutInfo.columnSpan = 3; // Spans 3 columns
      layoutInfo.laneIndex = 0;

      expect(layoutInfo.top, 10.0); // Secondary start (pixel value)
      expect(layoutInfo.left, 0.0); // division * cellWidth = 0 * 100.0
      expect(layoutInfo.width, 300.0); // columnSpan * cellWidth = 3 * 100.0
      expect(layoutInfo.height, 25.0); // Secondary size (pixel value)
      expect(layoutInfo.finalRect, Rect.fromLTWH(0.0, 10.0, 300.0, 25.0));
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
        start: 100, // Represents time position
        primarySize: 120, // Represents duration
        cellWidth: 100.0,
        cellHeight: 50.0,
      );

      final layout2 = EventLayoutInfo(
        event: event2,
        orientation: Axis.vertical,
        division: 0,
        start: 160,
        primarySize: 120,
        cellWidth: 100.0,
        cellHeight: 50.0,
      );

      final layout3 = EventLayoutInfo(
        event: event3,
        orientation: Axis.vertical,
        division: 0,
        start: 250,
        primarySize: 60,
        cellWidth: 100.0,
        cellHeight: 50.0,
      );

      final layout4 = EventLayoutInfo(
        event: event2, // Same event as layout2
        orientation: Axis.vertical,
        division: 1, // Different division
        start: 160,
        primarySize: 120,
        cellWidth: 100.0,
        cellHeight: 50.0,
      );

      // Overlap checks are based on primary axis (time) within the same division
      expect(layout1.overlapsWith(layout2), true);
      expect(layout2.overlapsWith(layout1), true);
      expect(layout1.overlapsWith(layout3), false); // 1 ends at 220, 3 starts at 250
      expect(layout2.overlapsWith(layout3), true); // 2 ends at 280, 3 starts at 250
      expect(layout1.overlapsWith(layout4), false); // Different division
    });
  });

  group('EventLayoutService', () {
    test('should measure events correctly for vertical orientation', () {
      final now = DateTime(2023, 1, 1);
      // Initialize directly using the constructor
      final broker = GridLayoutInfo(
        viewStart: now.toUtc(), // Use UTC
        viewEnd: now.add(const Duration(days: 1)).toUtc(),
        origin: const Offset(60, 40),
        availableSpace: const Size(300, 1200), // Example space
        orientation: Axis.vertical,
        divisions: 1,
        cellWidth: 300,
        cellHeight: 1200, // Height for the full day
        intervalDuration: const Duration(minutes: 30),
      );
      // Removed updateGridLayout call

      final events = [
        CalendarEvent(
          id: '1',
          title: 'Morning Event',
          start: now.add(const Duration(hours: 9)), // Local time
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
        gridInfo: broker,
        minEventSize: 20,
      );

      expect(layoutInfos.length, 2);

      // Morning event (9-10 AM)
      expect(layoutInfos[0].event.id, '1');
      expect(layoutInfos[0].orientation, Axis.vertical);
      expect(layoutInfos[0].division, 0);
      // Position = (startHour * 60 / totalMinutesInDay) * totalPixelHeight
      expect(layoutInfos[0].start, closeTo((9 * 60) / (24 * 60) * 1200, 1)); // ~450
      // Size = (durationMinutes / totalMinutesInDay) * totalPixelHeight
      expect(layoutInfos[0].primarySize, closeTo(60 / (24 * 60) * 1200, 1)); // ~50

      // Afternoon event (1-3 PM)
      expect(layoutInfos[1].event.id, '2');
      expect(layoutInfos[1].orientation, Axis.vertical);
      expect(layoutInfos[1].division, 0);
      expect(layoutInfos[1].start, closeTo((13 * 60) / (24 * 60) * 1200, 1)); // ~650
      expect(layoutInfos[1].primarySize, closeTo(120 / (24 * 60) * 1200, 1)); // ~100
    });

    test('should measure events correctly for horizontal orientation', () {
      final now = DateTime(2023, 1, 1);
      // Initialize directly using the constructor
      final broker = GridLayoutInfo(
        viewStart: now.toUtc(),
        viewEnd: now.add(const Duration(days: 3)).toUtc(), // 3 day view
        origin: const Offset(0, 0), // Simpler origin
        availableSpace: const Size(600, 80), // Example space
        orientation: Axis.horizontal,
        divisions: 3, // 3 days
        cellWidth: 200, // 600 / 3
        cellHeight: 80,
        intervalDuration: const Duration(minutes: 30),
      );
      // Removed updateGridLayout call

      final events = [
        // Event fully within day 1
        CalendarEvent(
          id: '1', title: 'Day 1 Event', isAllDay: true,
          start: now.add(const Duration(hours: 9)),
          end: now.add(const Duration(hours: 10)), // Ends same day
        ),
        // Event spanning day 1 and 2
        CalendarEvent(
          id: '2', title: 'Multi-day Event', isAllDay: true,
          start: now.add(const Duration(hours: 13)),
          end: now.add(const Duration(days: 1, hours: 15)), // Ends day 2
        ),
         // Event starting day 2 ending day 3
         CalendarEvent(
          id: '3', title: 'Another Multi-day', isAllDay: true,
          start: now.add(const Duration(days: 1, hours: 8)),
          end: now.add(const Duration(days: 2, hours: 12)),
        ),
      ];

      final service = EventLayoutService();
      final layoutInfos = service.measureEvents(
        events: events,
        gridInfo: broker,
        minEventSize: 20, // Min width for horizontal
      );

      // Expect segments for each day the event spans within the view
      expect(layoutInfos.length, 5); // 1 segment for event 1, 2 for event 2, 2 for event 3

      // Event 1 (Day 1 only)
      final layout1 = layoutInfos.firstWhere((l) => l.event.id == '1');
      expect(layout1.division, 0);
      expect(layout1.orientation, Axis.horizontal);
      expect(layout1.start, 0); // Starts at beginning of division
      expect(layout1.primarySize, 200); // Spans full width of division

      // Event 2 (Day 1 segment)
      final layout2_d0 = layoutInfos.firstWhere((l) => l.event.id == '2' && l.division == 0);
      expect(layout2_d0.division, 0);
      expect(layout2_d0.orientation, Axis.horizontal);
      expect(layout2_d0.start, closeTo((13 * 60) / (24*60) * 200, 1)); // Starts partway
      expect(layout2_d0.primarySize, closeTo((11 * 60) / (24*60) * 200, 1)); // Remaining width

       // Event 2 (Day 2 segment)
      final layout2_d1 = layoutInfos.firstWhere((l) => l.event.id == '2' && l.division == 1);
      expect(layout2_d1.division, 1);
      expect(layout2_d1.orientation, Axis.horizontal);
      expect(layout2_d1.start, 0); // Starts at beginning of division
      expect(layout2_d1.primarySize, closeTo((15 * 60) / (24*60) * 200, 1)); // Width until end time

       // Event 3 (Day 2 segment)
      final layout3_d1 = layoutInfos.firstWhere((l) => l.event.id == '3' && l.division == 1);
      expect(layout3_d1.division, 1);
      expect(layout3_d1.orientation, Axis.horizontal);
      expect(layout3_d1.start, closeTo((8 * 60) / (24*60) * 200, 1)); // Starts partway
      expect(layout3_d1.primarySize, closeTo((16 * 60) / (24*60) * 200, 1)); // Remaining width

       // Event 3 (Day 3 segment)
      final layout3_d2 = layoutInfos.firstWhere((l) => l.event.id == '3' && l.division == 2);
      expect(layout3_d2.division, 2);
      expect(layout3_d2.orientation, Axis.horizontal);
      expect(layout3_d2.start, 0); // Starts at beginning of division
      expect(layout3_d2.primarySize, closeTo((12 * 60) / (24*60) * 200, 1)); // Width until end time

    });
  });

  group('EventPackingService', () {
    // Helper to create basic EventLayoutInfo for testing packing
    EventLayoutInfo _createLayout(String id, int division, double start, double size, {Axis orientation = Axis.vertical, double cellWidth = 100.0, double cellHeight = 50.0}) {
       return EventLayoutInfo(
         event: CalendarEvent(id: id, title: 'Event $id', start: DateTime.now(), end: DateTime.now()), // Dummy event data
         orientation: orientation,
         division: division,
         start: start,
         primarySize: size,
         cellWidth: cellWidth,
         cellHeight: cellHeight,
       );
    }

    test('should pack overlapping vertical events into separate lanes', () {
      final layoutInfos = [
        _createLayout('1', 0, 100, 120), // Event 1: 100 - 220
        _createLayout('2', 0, 160, 120), // Event 2: 160 - 280 (overlaps 1)
        _createLayout('3', 0, 300, 120), // Event 3: 300 - 420 (no overlap with 1 or 2)
      ];

      final service = EventPackingService();
      final packedEvents = service.packEvents(
        events: layoutInfos,
        minSecondarySize: 20,
        style: const EventRenderStyle(horizontalSpacing: 0, rightMargin: 0), // Simplify style for test
        visibleDates: [], // Not used in vertical packing logic directly
        maxVisibleAllDayEvents: null, // Pass null for test
      );

      expect(packedEvents.length, 3);
      final event1 = packedEvents.firstWhere((e) => e.event.id == '1');
      final event2 = packedEvents.firstWhere((e) => e.event.id == '2');
      final event3 = packedEvents.firstWhere((e) => e.event.id == '3');

      // Event 1 and 2 overlap, should be in different lanes (lane indices 0 and 1)
      expect(event1.laneIndex, isNot(equals(event2.laneIndex)));
      expect([0, 1].contains(event1.laneIndex), isTrue);
      expect([0, 1].contains(event2.laneIndex), isTrue);

      // Event 3 doesn't overlap 1 or 2 initially, could be in lane 0
      expect(event3.laneIndex, 0);

      // Check relative positions/sizes (assuming 2 lanes means 50% width each)
      expect(event1.secondaryStart, isIn([0.0, 0.5]));
      expect(event1.secondarySize, 0.5);
      expect(event2.secondaryStart, isIn([0.0, 0.5]));
      expect(event2.secondarySize, 0.5);
      expect(event3.secondaryStart, 0.0); // Should be placed in the first available lane
      expect(event3.secondarySize, 0.5); // Takes width of its lane
    });

    test('should pack non-overlapping vertical events into the same lane', () {
       final layoutInfos = [
        _createLayout('1', 0, 100, 60), // Event 1: 100 - 160
        _createLayout('2', 0, 200, 60), // Event 2: 200 - 260
        _createLayout('3', 0, 300, 60), // Event 3: 300 - 360
      ];

      final service = EventPackingService();
      final packedEvents = service.packEvents(
        events: layoutInfos,
        minSecondarySize: 20,
        style: const EventRenderStyle(horizontalSpacing: 0, rightMargin: 0),
        visibleDates: [],
        maxVisibleAllDayEvents: null, // Pass null for test
      );

      expect(packedEvents.length, 3);
      // All should be in the same lane (index 0)
      expect(packedEvents.every((e) => e.laneIndex == 0), isTrue);
      // All should have full width (relative size 1.0)
      expect(packedEvents.every((e) => e.secondarySize == 1.0), isTrue);
      expect(packedEvents.every((e) => e.secondaryStart == 0.0), isTrue);
    });

    test('should handle events spanning multiple divisions correctly (horizontal)', () {
       final layoutInfos = [
         // Event A: Day 0 only
         _createLayout('A', 0, 0, 100, orientation: Axis.horizontal, cellHeight: 80, cellWidth: 100),
         // Event B: Day 0 to Day 1
         _createLayout('B', 0, 0, 100, orientation: Axis.horizontal, cellHeight: 80, cellWidth: 100),
         _createLayout('B', 1, 0, 100, orientation: Axis.horizontal, cellHeight: 80, cellWidth: 100),
         // Event C: Day 1 to Day 2
         _createLayout('C', 1, 0, 100, orientation: Axis.horizontal, cellHeight: 80, cellWidth: 100),
         _createLayout('C', 2, 0, 100, orientation: Axis.horizontal, cellHeight: 80, cellWidth: 100),
         // Event D: Day 2 only
         _createLayout('D', 2, 0, 100, orientation: Axis.horizontal, cellHeight: 80, cellWidth: 100),
       ];
       final visibleDates = [DateTime(2023), DateTime(2023, 1, 2), DateTime(2023, 1, 3)];

       final service = EventPackingService();
       final packedEvents = service.packEvents(
         events: layoutInfos,
         minSecondarySize: 20,
         style: const EventRenderStyle(horizontalSpacing: 2), // Use default spacing
         visibleDates: visibleDates,
         maxVisibleAllDayEvents: null, // Pass null for test
       );

       // Should return primary layout info for each unique event (A, B, C, D)
       expect(packedEvents.length, 4);

       final eventA = packedEvents.firstWhere((e) => e.event.id == 'A');
       final eventB = packedEvents.firstWhere((e) => e.event.id == 'B');
       final eventC = packedEvents.firstWhere((e) => e.event.id == 'C');
       final eventD = packedEvents.firstWhere((e) => e.event.id == 'D');

       // Check spans
       expect(eventA.columnSpan, 1);
       expect(eventB.columnSpan, 2); // Spans Day 0 and Day 1
       expect(eventC.columnSpan, 2); // Spans Day 1 and Day 2
       expect(eventD.columnSpan, 1);

       // Check starting divisions
       expect(eventA.division, 0);
       expect(eventB.division, 0);
       expect(eventC.division, 1);
       expect(eventD.division, 2);

       // Check lane assignments (vertical stacking)
       // Day 0: A and B overlap -> different lanes
       // Day 1: B and C overlap -> different lanes
       // Day 2: C and D overlap -> different lanes
       // Expectation: A=0, B=1, C=0, D=1 (or vice versa for lanes 0/1)
       expect(eventA.laneIndex, isNot(equals(eventB.laneIndex)));
       expect(eventB.laneIndex, isNot(equals(eventC.laneIndex)));
       expect(eventC.laneIndex, isNot(equals(eventD.laneIndex)));
       expect([0, 1].contains(eventA.laneIndex), isTrue);
       expect([0, 1].contains(eventB.laneIndex), isTrue);
       expect([0, 1].contains(eventC.laneIndex), isTrue);
       expect([0, 1].contains(eventD.laneIndex), isTrue);

       // Check pixel positions/sizes (height=25, spacing=2)
       expect(eventA.secondarySize, 25.0);
       expect(eventB.secondarySize, 25.0);
       expect(eventC.secondarySize, 25.0);
       expect(eventD.secondarySize, 25.0);

       expect(eventA.secondaryStart, isIn([0.0, 27.0])); // laneIndex * (25+2)
       expect(eventB.secondaryStart, isIn([0.0, 27.0]));
       expect(eventC.secondaryStart, isIn([0.0, 27.0]));
       expect(eventD.secondaryStart, isIn([0.0, 27.0]));

       // Check indicator flags (assuming cellHeight=80, reserved=30 -> usable=50)
       // maxLanes = floor((50+2)/(25+2)) = floor(52/27) = 1
       // Last visible lane index = 0. Events in lane 1 should trigger indicator on lane 0 events.
       final lane0Events = packedEvents.where((e) => e.laneIndex == 0).toList();
       final lane1Events = packedEvents.where((e) => e.laneIndex == 1).toList();

       expect(lane0Events.any((e) => e.hasMoreIndicator), isTrue); // At least one event in lane 0 should have indicator
       expect(lane1Events.every((e) => !e.hasMoreIndicator), isTrue); // Events in lane 1 should not

       // Verify counts (can be tricky with spans)
       // Event A (Div 0): Should have indicator triggered by Event B (Div 0)
       // Event C (Div 1): Should have indicator triggered by Event B (Div 1) and Event D (Div 2 is irrelevant)
       // Event C (Div 2): Should have indicator triggered by Event D (Div 2)
       // The current logic sums counts for all divisions spanned by the visible event.
       expect(eventA.hasMoreIndicator, isTrue);
       expect(eventA.hiddenEventCount, 1); // Event B hidden below in Div 0

       expect(eventC.hasMoreIndicator, isTrue);
       // Event C spans Div 1 & 2. Hidden below Div 1 is Event B. Hidden below Div 2 is Event D.
       expect(eventC.hiddenEventCount, 2); // 1 (B) + 1 (D)

    });

  });
}
