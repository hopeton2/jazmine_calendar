import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/event_rendering/single_event_painter.dart'; // Import the painter

/// Widget that uses a CustomPainter to draw a single calendar event.
class CalendarEventWidget extends StatelessWidget {
  final EventLayoutInfo eventLayoutInfo;
  final EventRenderStyle style;
  final bool isSelected;
  final bool isResizing;
  final ResizeHandle? activeResizeHandle;
  final bool enableResize; // Flag to control if handles are drawn

  const CalendarEventWidget({
    super.key,
    required this.eventLayoutInfo,
    required this.style,
    required this.isSelected,
    required this.isResizing,
    this.activeResizeHandle,
    required this.enableResize,
  });

  @override
  Widget build(BuildContext context) {
    // Determine default color from theme if not provided in style or event
    final defaultColor = Theme.of(context).primaryColor;

    return CustomPaint(
      painter: SingleEventPainter(
        eventLayoutInfo: eventLayoutInfo,
        style: style,
        isSelected: isSelected,
        isResizing: isResizing,
        activeResizeHandle: activeResizeHandle,
        enableResize: enableResize, // Pass flag to painter
        defaultColor: defaultColor,
      ),
      // Provide the size for the painter based on the calculated finalRect
      size: eventLayoutInfo.finalRect.size,
    );
  }
}