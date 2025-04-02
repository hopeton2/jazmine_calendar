import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';

/// Custom painter for rendering calendar events
class EventRenderer extends CustomPainter {
  /// List of events to render
  final List<EventLayoutInfo> events;

  /// Style configuration
  final EventRenderStyle style;

  /// Currently selected event (for highlighting)
  final String? selectedEventId;

  /// Event being dragged (for visual feedback)
  final String? draggedEventId;

  /// Event being resized (for visual feedback)
  final String? resizedEventId;

  /// Resize handle being dragged (top or bottom)
  final ResizeHandle? activeResizeHandle;

  /// Time format for displaying event times
  final DateFormat? timeFormat;

  /// Scroll offset for vertical scrolling
  final double scrollOffset;

  /// Creates a new EventRenderer
  EventRenderer({
    required this.events,
    this.style = const EventRenderStyle(),
    this.selectedEventId,
    this.draggedEventId,
    this.resizedEventId,
    this.activeResizeHandle,
    this.timeFormat,
    this.scrollOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final eventLayout in events) {
      // Apply scroll offset to the event's position
      // For vertical scrolling, we need to adjust the top position
      final calculatedRect =
          eventLayout.finalRect; // Rect relative to content area (0,0)
      final rect = Rect.fromLTWH(
        calculatedRect.left,
        calculatedRect.top -
            scrollOffset, // Apply scroll offset for viewport positioning
        calculatedRect.width,
        calculatedRect.height,
      );
      // Removed debug print

      // Determine if this event is selected, being dragged, or being resized
      final isSelected = selectedEventId == eventLayout.event.id;
      final isDragged = draggedEventId == eventLayout.event.id;
      final isResized = resizedEventId == eventLayout.event.id;

      // Draw the event with the adjusted rect
      _drawEvent(
        canvas,
        eventLayout,
        isSelected: isSelected,
        isDragged: isDragged,
        isResized: isResized,
        rect: rect, // Pass the adjusted rect
      );
    }
  }

  /// Draw a single event
  void _drawEvent(
    Canvas canvas,
    EventLayoutInfo layout, {
    bool isSelected = false,
    bool isDragged = false,
    bool isResized = false,
    required Rect rect, // Use the adjusted rect passed from paint method
  }) {
    final event = layout.event;

    // Get the event color
    final color = style.getColorForEvent(event);

    // Create the background paint
    final backgroundPaint = Paint()
      ..color = isDragged ? color.withOpacity(0.7) : color
      ..style = PaintingStyle.fill;

    // Create the border paint (for selected events)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw the event background
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(style.cornerRadius),
    );
    canvas.drawRRect(rrect, backgroundPaint);

    // Draw border for selected events
    if (isSelected) {
      canvas.drawRRect(rrect, borderPaint);
    }

    // Draw event content
    _drawEventContent(canvas, layout, rect);

    // Draw resize handles if this event is selected or being resized
    if ((isSelected || isResized) && !event.isAllDay) {
      _drawResizeHandles(canvas, rect, isResized);
    }
  }

  /// Draw the content of an event (title, time, location)
  void _drawEventContent(
    Canvas canvas,
    EventLayoutInfo layout,
    Rect rect,
  ) {
    final event = layout.event;
    final contentRect = rect.deflate(style.contentPadding.left);

    // Determine the correct top starting point based on orientation
    final contentTop = layout.orientation == Axis.vertical
        ? rect.top + 5
        : contentRect.top + 5;

    // Create text painters for title and time
    final titleTextSpan = TextSpan(
      text: event.title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    final titlePainter = TextPainter(
      text: titleTextSpan,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );

    titlePainter.layout(maxWidth: contentRect.width);
    titlePainter.paint(canvas, Offset(contentRect.left + 5, contentTop));

    // Draw time if there's enough space
    if (contentRect.height > 30) {
      // Format the time
      final startTime =
          '${event.start.hour}:${event.start.minute.toString().padLeft(2, '0')}';
      final endTime =
          '${event.end.hour}:${event.end.minute.toString().padLeft(2, '0')}';
      final timeText = event.isAllDay ? 'All Day' : '$startTime - $endTime';

      final timeTextSpan = TextSpan(
        text: timeText,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 10,
        ),
      );

      final timePainter = TextPainter(
        text: timeTextSpan,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );

      timePainter.layout(maxWidth: contentRect.width);
      timePainter.paint(canvas, Offset(contentRect.left + 5, contentTop + 18));
    }
  }

  /// Draw resize handles for an event
  void _drawResizeHandles(Canvas canvas, Rect rect, bool isResizing) {
    final handlePaint = Paint()
      ..color = style.resizeHandleColor
      ..style = PaintingStyle.fill;

    final handleSize = style.resizeHandleSize;

    // Top handle
    final topHandleRect = Rect.fromLTWH(
      rect.left + (rect.width - handleSize) / 2,
      rect.top,
      handleSize,
      handleSize,
    );

    // Bottom handle
    final bottomHandleRect = Rect.fromLTWH(
      rect.left + (rect.width - handleSize) / 2,
      rect.bottom - handleSize,
      handleSize,
      handleSize,
    );

    // Draw handles with different opacity based on resize state
    if (isResizing && activeResizeHandle == ResizeHandle.top) {
      canvas.drawRect(topHandleRect, handlePaint);

      final fadedPaint = Paint()
        ..color = style.resizeHandleColor.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRect(bottomHandleRect, fadedPaint);
    } else if (isResizing && activeResizeHandle == ResizeHandle.bottom) {
      final fadedPaint = Paint()
        ..color = style.resizeHandleColor.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRect(topHandleRect, fadedPaint);

      canvas.drawRect(bottomHandleRect, handlePaint);
    } else {
      canvas.drawRect(topHandleRect, handlePaint);
      canvas.drawRect(bottomHandleRect, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant EventRenderer oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.style != style ||
        oldDelegate.selectedEventId != selectedEventId ||
        oldDelegate.draggedEventId != draggedEventId ||
        oldDelegate.resizedEventId != resizedEventId ||
        oldDelegate.activeResizeHandle != activeResizeHandle ||
        oldDelegate.scrollOffset != scrollOffset;
  }

  /// Find the event at a specific position
  EventLayoutInfo? findEventAt(Offset position) {
    for (final event in events.reversed) {
      // Apply scroll offset to the event's position
      // Use the same logic as paint method for hit testing
      final calculatedRect = event.finalRect;
      final rect = Rect.fromLTWH(
        calculatedRect.left,
        calculatedRect.top - scrollOffset,
        calculatedRect.width,
        calculatedRect.height,
      );

      if (rect.contains(position)) {
        return event;
      }
    }
    return null;
  }

  /// Find the resize handle at a specific position
  ResizeHandleHit? findResizeHandleAt(Offset position) {
    final handleSize = style.resizeHandleSize;

    for (final event in events.reversed) {
      if (event.event.isAllDay) continue; // All-day events can't be resized

      // Apply scroll offset to the event's position
      // Use the same logic as paint method for hit testing
      final calculatedRect = event.finalRect;
      final rect = Rect.fromLTWH(
        calculatedRect.left,
        calculatedRect.top - scrollOffset,
        calculatedRect.width,
        calculatedRect.height,
      );

      // Top handle
      final topHandleRect = Rect.fromLTWH(
        rect.left + (rect.width - handleSize) / 2,
        rect.top,
        handleSize,
        handleSize,
      );

      // Bottom handle
      final bottomHandleRect = Rect.fromLTWH(
        rect.left + (rect.width - handleSize) / 2,
        rect.bottom - handleSize,
        handleSize,
        handleSize,
      );

      if (topHandleRect.contains(position)) {
        return ResizeHandleHit(event, ResizeHandle.top);
      }

      if (bottomHandleRect.contains(position)) {
        return ResizeHandleHit(event, ResizeHandle.bottom);
      }
    }

    return null;
  }
}

/// Enum for resize handles
enum ResizeHandle {
  top,
  bottom,
}

/// Class for resize handle hit detection
class ResizeHandleHit {
  final EventLayoutInfo event;
  final ResizeHandle handle;

  ResizeHandleHit(this.event, this.handle);
}
