import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart'; // Renamed import

void main() {
  group('GridLayoutInfo', () { // Renamed group
    test('should store and provide grid layout information', () {
      final broker = GridLayoutInfo(); // Renamed class
      broker.reset(); // Start with a clean state

      // Check initial null state via getters throwing StateError
      expect(() => broker.viewStart, throwsStateError);

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
        cellHeight: 20,
      );

      // Check that getters now work after update
      expect(broker.viewStart, now); // Example check

      // Check stored values
      expect(broker.viewStart, now);
      expect(broker.viewEnd, now.add(const Duration(days: 1)));
      expect(broker.origin, const Offset(60, 40));
      expect(broker.availableSpace, const Size(300, 500));
      expect(broker.orientation, Axis.vertical);
      expect(broker.divisions, 1);
      expect(broker.cellWidth, 300);
      expect(broker.cellHeight, 20);

      // Test position calculation
      final middleTime = now.add(const Duration(hours: 12));
      final position = broker.getPositionForDateTime(middleTime, 0);
      expect(position.dx, 60); // origin.dx
      expect(position.dy,
          closeTo(290, 1)); // origin.dy + (0.5 * availableSpace.height)

      // Test size calculation
      final hourDuration = const Duration(hours: 1);
      final size = broker.getSizeForDuration(hourDuration);
      expect(size.width, 300); // cellWidth
      expect(
          size.height, closeTo(20.83, 0.1)); // (1/24) * availableSpace.height

      // Test container rect calculation
      final rect = broker.getContainerRectForDivision(0);
      expect(rect, Rect.fromLTWH(60, 40, 300, 500));
    });
  });

  test('GridLayoutBroker can be manually updated', () {
    // Reset broker
    final broker = GridLayoutInfo(); // Renamed class
    broker.reset();

    // Check that getters throw again after reset
    expect(() => broker.viewStart, throwsStateError);

    // Manually update the broker
    final now = DateTime.now();
    broker.updateGridLayout(
      viewStart: now,
      viewEnd: now.add(const Duration(days: 1)),
      origin: const Offset(60, 40),
      availableSpace: const Size(400, 600),
      orientation: Axis.vertical,
      divisions: 3,
      cellWidth: 133.33,
      cellHeight: 25,
    );

    // Verify broker was updated
    expect(broker.origin, const Offset(60, 40));
    expect(broker.orientation, Axis.vertical);
    expect(broker.divisions, 3);
    expect(broker.cellWidth, closeTo(133.33, 0.01));

    // Test position calculation for middle of second column
    final middleTime = now.add(const Duration(hours: 12));
    final position = broker.getPositionForDateTime(middleTime, 1);
    expect(position.dx, closeTo(193.33, 0.1)); // origin.dx + cellWidth
    expect(position.dy,
        closeTo(340, 1)); // origin.dy + (0.5 * availableSpace.height)
  });
}
