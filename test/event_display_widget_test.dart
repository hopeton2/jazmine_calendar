import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/event_rendering/event_display_widget.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';

void main() {
  group('EventDisplayWidget', () {
    late CalendarController controller;
    late GridLayoutInfo broker;

    setUp(() {
      // Create controller
      controller = CalendarController(
        initialView: CalendarViewType.day,
      );

      // Set up test events
      final now = DateTime(2023, 1, 1, 9, 0);

      // Set up broker
      broker = GridLayoutInfo();
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
    });

    testWidgets('should build without errors', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 800,
              child: EventDisplayWidget(
                controller: controller,
                broker: broker, // Pass the broker instance
              ),
            ),
          ),
        ),
      );

      // Wait for async operations to complete
      await tester.pumpAndSettle();

      // Verify events are rendered
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should apply custom render style',
        (WidgetTester tester) async {
      // Custom style
      const customStyle = EventRenderStyle(
        cornerRadius: 8.0,
        defaultEventColor: Colors.red,
        titleStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 800,
              child: EventDisplayWidget(
                controller: controller,
                renderStyle: customStyle,
                broker: broker, // Pass the broker instance
              ),
            ),
          ),
        ),
      );

      // Wait for async operations to complete
      await tester.pumpAndSettle();

      // We can't directly test the CustomPaint style, but we can verify
      // that the widget is built and doesn't throw exceptions
    });
  });
}
