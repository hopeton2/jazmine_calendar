import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';

void main() {
  // --- Existing tests (keep them) ---
  group('GridLayoutInfo Initialization and Basic Getters', () {
    test('should store and provide grid layout information', () {
      final broker = GridLayoutInfo();
      broker.reset();

      // Check initial null state via getters throwing StateError
      expect(() => broker.viewStart, throwsStateError);
      expect(() => broker.viewEnd, throwsStateError);
      expect(() => broker.origin, throwsStateError);
      expect(() => broker.availableSpace, throwsStateError);
      expect(() => broker.orientation, throwsStateError);
      expect(() => broker.divisions, throwsStateError);
      expect(() => broker.cellWidth, throwsStateError);
      expect(() => broker.cellHeight, throwsStateError);


      // Update with test data
      final now = DateTime.now();
      broker.updateGridLayout(
        viewStart: now,
        viewEnd: now.add(const Duration(days: 1)),
        origin: const Offset(60, 40),
        availableSpace: const Size(300, 500),
        orientation: Axis.vertical,
        divisions: 1,
        cellWidth: 300,
        cellHeight: 20, // cellHeight might be less relevant for vertical time axis
        intervalDuration: const Duration(minutes: 30), // Add interval duration
      );

      // Check that getters now work after update
      expect(broker.viewStart, now);
      expect(broker.viewEnd, now.add(const Duration(days: 1)));
      expect(broker.origin, const Offset(60, 40));
      expect(broker.availableSpace, const Size(300, 500));
      expect(broker.orientation, Axis.vertical);
      expect(broker.divisions, 1);
      expect(broker.intervalDuration, const Duration(minutes: 30)); // Check interval duration
      expect(broker.cellWidth, 300);
      expect(broker.cellHeight, 20);
    });

     test('reset should clear all values', () {
      final broker = GridLayoutInfo();
      final now = DateTime.now();
      broker.updateGridLayout(
        viewStart: now,
        viewEnd: now.add(const Duration(days: 1)),
        origin: const Offset(60, 40),
        availableSpace: const Size(300, 500),
        orientation: Axis.vertical,
        divisions: 1,
        cellWidth: 300,
        cellHeight: 20,
        intervalDuration: const Duration(minutes: 30), // Add interval duration
      );

      broker.reset();

      // Check that getters throw again after reset
      expect(() => broker.viewStart, throwsStateError);
      expect(() => broker.viewEnd, throwsStateError);
      expect(() => broker.intervalDuration, throwsStateError); // Check interval duration reset
      // ... check other getters ...
    });
  });

  // --- New Test Group for Time/Position Conversions ---
  group('GridLayoutInfo Time/Position Conversions (Vertical)', () {
    late GridLayoutInfo broker;
    final viewStart = DateTime(2024, 4, 6, 0, 0, 0); // Start at midnight for simplicity
    final viewEnd = viewStart.add(const Duration(days: 3)); // 3-day view
    const origin = Offset(50, 100); // Left 50, Top 100
    const availableSpace = Size(600, 800); // Width 600, Height 800
    const divisions = 3; // 3 days
    final cellWidth = availableSpace.width / divisions; // 200
    const cellHeight = 30.0; // Less relevant for vertical time axis

    setUp(() {
      broker = GridLayoutInfo();
      broker.updateGridLayout(
        viewStart: viewStart,
        viewEnd: viewEnd,
        origin: origin,
        availableSpace: availableSpace,
        orientation: Axis.vertical,
        divisions: divisions,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        intervalDuration: const Duration(minutes: 30), // Add interval duration
      );
    });

    // --- Tests for getPositionForDateTime ---
    test('getPositionForDateTime - Vertical - Start of view', () {
      final position = broker.getPositionForDateTime(viewStart, 0);
      expect(position.dx, closeTo(origin.dx, 0.1)); // First division starts at origin.dx
      expect(position.dy, closeTo(origin.dy, 0.1)); // Start time (midnight) is at origin.dy
    });

    test('getPositionForDateTime - Vertical - Middle of first day', () {
      final middleTime = viewStart.add(const Duration(hours: 12));
      final position = broker.getPositionForDateTime(middleTime, 0);
      expect(position.dx, closeTo(origin.dx, 0.1)); // First division
      expect(position.dy, closeTo(origin.dy + availableSpace.height * 0.5, 0.1)); // 12 hours = 50% of height
    });

     test('getPositionForDateTime - Vertical - Start of second day', () {
      final startTime = viewStart.add(const Duration(days: 1)); // Midnight of second day
      final position = broker.getPositionForDateTime(startTime, 1); // Division 1
      expect(position.dx, closeTo(origin.dx + cellWidth, 0.1)); // Second division starts at origin.dx + cellWidth
      expect(position.dy, closeTo(origin.dy, 0.1)); // Start time (midnight) is at origin.dy
    });

    test('getPositionForDateTime - Vertical - Middle of second day', () {
      final middleTime = viewStart.add(const Duration(days: 1, hours: 6)); // 6 AM on second day
      final position = broker.getPositionForDateTime(middleTime, 1); // Division 1
      expect(position.dx, closeTo(origin.dx + cellWidth, 0.1)); // Second division
      expect(position.dy, closeTo(origin.dy + availableSpace.height * 0.25, 0.1)); // 6 hours = 25% of height
    });

     test('getPositionForDateTime - Vertical - End of last day (almost)', () {
      // Use a time slightly before viewEnd to avoid potential floating point issues at the exact boundary
      final endTime = viewEnd.subtract(const Duration(minutes: 1));
      final position = broker.getPositionForDateTime(endTime, 2); // Division 2 (last)
      expect(position.dx, closeTo(origin.dx + cellWidth * 2, 0.1)); // Third division
      // Expect Y to be close to the bottom edge
      expect(position.dy, closeTo(origin.dy + availableSpace.height, 1.0)); // Allow slightly larger delta
    });

     test('getPositionForDateTime - Vertical - Clamps time before viewStart', () {
      final beforeTime = viewStart.subtract(const Duration(hours: 1));
      final position = broker.getPositionForDateTime(beforeTime, 0);
      expect(position.dx, closeTo(origin.dx, 0.1));
      expect(position.dy, closeTo(origin.dy, 0.1)); // Should clamp to viewStart time (origin.dy)
    });

     test('getPositionForDateTime - Vertical - Clamps time after viewEnd', () {
      final afterTime = viewEnd.add(const Duration(hours: 1));
      final position = broker.getPositionForDateTime(afterTime, 2);
      expect(position.dx, closeTo(origin.dx + cellWidth * 2, 0.1));
      // Should clamp to viewEnd time (bottom edge)
      expect(position.dy, closeTo(origin.dy + availableSpace.height, 1.0));
    });

     test('getPositionForDateTime - Vertical - Clamps division index', () {
      final middleTime = viewStart.add(const Duration(hours: 12));
      // Test division < 0
      var position = broker.getPositionForDateTime(middleTime, -1);
      expect(position.dx, closeTo(origin.dx, 0.1)); // Clamps to division 0
      expect(position.dy, closeTo(origin.dy + availableSpace.height * 0.5, 0.1));
      // Test division >= divisions
      position = broker.getPositionForDateTime(middleTime, divisions); // divisions = 3, so index 3 is out of bounds
      expect(position.dx, closeTo(origin.dx + cellWidth * 2, 0.1)); // Clamps to division 2 (last valid index)
      expect(position.dy, closeTo(origin.dy + availableSpace.height * 0.5, 0.1));
    });


    // --- Tests for getDateTimeForPosition ---
    test('getDateTimeForPosition - Vertical - Origin', () {
      final dateTime = broker.getDateTimeForPosition(origin);
      expect(dateTime, viewStart); // Origin corresponds to viewStart in division 0
    });

    test('getDateTimeForPosition - Vertical - Middle of first day column', () {
      final position = Offset(origin.dx + cellWidth * 0.5, origin.dy + availableSpace.height * 0.5); // Center of first column, halfway down
      final dateTime = broker.getDateTimeForPosition(position);
      final expectedTime = viewStart.add(const Duration(hours: 12)); // 12 hours into the first day
      expect(dateTime, expectedTime);
    });

    test('getDateTimeForPosition - Vertical - Top of second day column', () {
      final position = Offset(origin.dx + cellWidth * 1.5, origin.dy); // Middle of second column, top edge
      final dateTime = broker.getDateTimeForPosition(position);
      final expectedTime = viewStart.add(const Duration(days: 1)); // Start of the second day
      expect(dateTime, expectedTime);
    });

     test('getDateTimeForPosition - Vertical - 6 AM of second day column', () {
      final position = Offset(origin.dx + cellWidth * 1.5, origin.dy + availableSpace.height * 0.25); // Middle of second column, 25% down
      final dateTime = broker.getDateTimeForPosition(position);
      final expectedTime = viewStart.add(const Duration(days: 1, hours: 6)); // 6 AM on the second day
      expect(dateTime, expectedTime);
    });

     test('getDateTimeForPosition - Vertical - Bottom of last day column (almost)', () {
      final position = Offset(origin.dx + cellWidth * 2.5, origin.dy + availableSpace.height - 1); // Middle of last column, near bottom
      final dateTime = broker.getDateTimeForPosition(position);
      // Expect time close to the end of the last day (which is viewEnd)
      // Allow some tolerance due to rounding
      expect(dateTime!.difference(viewEnd).inMinutes.abs(), lessThan(2));
    });

     test('getDateTimeForPosition - Vertical - Clamps position left of origin.dx', () {
      final position = Offset(origin.dx - 10, origin.dy + availableSpace.height * 0.5);
      final dateTime = broker.getDateTimeForPosition(position);
      final expectedTime = viewStart.add(const Duration(hours: 12)); // Should clamp to division 0
      expect(dateTime, expectedTime);
    });

     test('getDateTimeForPosition - Vertical - Clamps position right of grid', () {
      final position = Offset(origin.dx + availableSpace.width + 10, origin.dy + availableSpace.height * 0.5);
      final dateTime = broker.getDateTimeForPosition(position);
      final expectedTime = viewStart.add(const Duration(days: 2, hours: 12)); // Should clamp to last division (2)
      expect(dateTime, expectedTime);
    });

     test('getDateTimeForPosition - Vertical - Clamps position above origin.dy', () {
      final position = Offset(origin.dx + cellWidth * 1.5, origin.dy - 10); // Second column
      final dateTime = broker.getDateTimeForPosition(position);
      final expectedTime = viewStart.add(const Duration(days: 1)); // Should clamp to start of day 1
      expect(dateTime, expectedTime);
    });

     test('getDateTimeForPosition - Vertical - Clamps position below grid', () {
      final position = Offset(origin.dx + cellWidth * 1.5, origin.dy + availableSpace.height + 10); // Second column
      final dateTime = broker.getDateTimeForPosition(position);
      // Should clamp to end of day 1 (start of day 2)
      // Note: The current logic calculates based on 24h duration, so clamping to bottom edge effectively means the start of the *next* day if viewEnd aligns perfectly.
      // Let's expect it to be very close to the start of day 2.
      final expectedEndTimeOfDay1 = viewStart.add(const Duration(days: 2));
      expect(dateTime!.difference(expectedEndTimeOfDay1).inSeconds.abs(), lessThan(1));
    });

    // --- Test UTC Handling (Example) ---
     test('getDateTimeForPosition - Vertical - UTC', () {
        final utcViewStart = DateTime.utc(2024, 4, 6, 0, 0, 0);
        final utcViewEnd = utcViewStart.add(const Duration(days: 1));
        broker.updateGridLayout(
          viewStart: utcViewStart,
          viewEnd: utcViewEnd,
          origin: origin,
          availableSpace: availableSpace,
          orientation: Axis.vertical,
          divisions: 1, // Single day
          cellWidth: availableSpace.width,
          cellHeight: cellHeight,
          intervalDuration: const Duration(minutes: 30), // Add interval duration
        );

        final position = Offset(origin.dx + availableSpace.width * 0.5, origin.dy + availableSpace.height * 0.5); // Middle
        final dateTime = broker.getDateTimeForPosition(position);
        final expectedTime = utcViewStart.add(const Duration(hours: 12));

        expect(dateTime, expectedTime);
        expect(dateTime!.isUtc, isTrue); // Verify it's UTC
    });

  });

  // --- TODO: Add similar group for Horizontal Orientation ---

  // --- Existing test (keep it, maybe enhance) ---
  group('GridLayoutBroker Manual Update', () { // Renamed group
    test('GridLayoutBroker can be manually updated', () {
      // Reset broker
      final broker = GridLayoutInfo(); // Renamed class
      broker.reset();

      // Check that getters throw again after reset
      expect(() => broker.viewStart, throwsStateError);

      // Manually update the broker - Use a fixed start time for deterministic results
      final fixedViewStart = DateTime(2024, 1, 1, 0, 0, 0); // Start at midnight
      broker.updateGridLayout(
        viewStart: fixedViewStart,
        viewEnd: fixedViewStart.add(const Duration(days: 1)), // 1-day view for simplicity here
        origin: const Offset(60, 40),
        availableSpace: const Size(400, 600), // Width 400, Height 600
        orientation: Axis.vertical,
        divisions: 3, // 3 columns (days)
        cellWidth: 400 / 3, // Use calculation
        cellHeight: 25,
        intervalDuration: const Duration(minutes: 30), // Add interval duration
      );

      // Verify broker was updated
      expect(broker.origin, const Offset(60, 40));
      expect(broker.orientation, Axis.vertical);
      expect(broker.divisions, 3);
      expect(broker.cellWidth, closeTo(133.33, 0.01));

      // Test position calculation for middle of second column (using updated logic)
      // Use fixedViewStart for calculating middleTime
      final middleTime = fixedViewStart.add(const Duration(hours: 12));
      final position = broker.getPositionForDateTime(middleTime, 1); // Division 1 (second column)
      expect(position.dx, closeTo(60 + (400 / 3), 0.1)); // origin.dx + cellWidth
      expect(position.dy, closeTo(40 + (600 * 0.5), 0.1)); // origin.dy + (0.5 * availableSpace.height)
    });
  });
}
