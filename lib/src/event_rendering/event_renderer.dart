import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/enums/enums.dart'; // Ensure enums are imported for ResizeHandle

// Define ResizeHandleHit class locally
class ResizeHandleHit {
  final EventLayoutInfo event;
  final ResizeHandle handle; // Use ResizeHandle from enums.dart

  ResizeHandleHit(this.event, this.handle);
}

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

  /// Event being resized (for visual feedback) - Restored
  final String? resizedEventId;

  /// Resize handle being dragged (top or bottom) - Restored
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
    this.resizedEventId, // Restored
    this.activeResizeHandle, // Restored
    this.timeFormat,
    this.scrollOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final eventLayout in events) {
      // Apply scroll offset to the event's position
      final calculatedRect =
          eventLayout.finalRect; // Rect relative to content area (0,0)
      // Scroll offset only applies vertically for now
      final topAdjust =
          eventLayout.orientation == Axis.vertical ? scrollOffset : 0.0;
      final leftAdjust = 0.0; // Assuming no horizontal scroll for now

      final rect = Rect.fromLTWH(
        calculatedRect.left - leftAdjust,
        calculatedRect.top - topAdjust,
        calculatedRect.width,
        calculatedRect.height,
      );

      // Determine if this event is selected, being dragged, or being resized
      final isSelected = selectedEventId == eventLayout.event.id;
      final isDragged = draggedEventId == eventLayout.event.id;
      final isResized = resizedEventId == eventLayout.event.id; // Restored

      // Draw the event with the adjusted rect
      _drawEvent(
        canvas,
        eventLayout,
        isSelected: isSelected,
        isDragged: isDragged,
        isResized: isResized, // Restored
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
    bool isResized = false, // Restored
    required Rect rect, // Use the adjusted rect passed from paint method
  }) {
    final event = layout.event;
    final color = style.getColorForEvent(event);
    final backgroundPaint = Paint()
      ..color = isDragged ? color.withOpacity(0.7) : color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white // Consider making border color configurable
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Consider making border width configurable

    // Draw the event background (potentially adjusted for vertical indicator)
    Rect backgroundRect = rect;
    if (layout.orientation == Axis.vertical &&
        style.verticalIndicatorWidth > 0) {
      backgroundRect = Rect.fromLTWH(
        rect.left + style.verticalIndicatorWidth,
        rect.top,
        rect.width - style.verticalIndicatorWidth,
        rect.height,
      );
      final indicatorPaint = Paint()
        ..color = style.verticalIndicatorColor ?? color
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(
            rect.left, rect.top, style.verticalIndicatorWidth, rect.height),
        indicatorPaint,
      );
    }

    final rrect = RRect.fromRectAndRadius(
      backgroundRect,
      Radius.circular(style.cornerRadius),
    );
    canvas.drawRRect(rrect, backgroundPaint);

    if (isSelected) {
      canvas.drawRRect(rrect, borderPaint);
    }

    _drawEventContent(canvas, layout, backgroundRect); // Pass backgroundRect

    // Draw resize handles if this event is selected or being resized - Restored condition
    if ((isSelected || isResized) && !event.isAllDay) {
      _drawResizeHandles(
          canvas, layout.orientation, rect, isResized); // Pass orientation
    }
  }

  /// Draw the content of an event (title, time, location)
  void _drawEventContent(
    Canvas canvas,
    EventLayoutInfo layout,
    Rect rect, // Represents backgroundRect if indicator is present
  ) {
    final event = layout.event;
    // Use specific all-day padding if provided and orientation is horizontal
    final EdgeInsets paddingToUse = layout.orientation == Axis.horizontal &&
            style.allDayContentPadding != null
        ? style.allDayContentPadding!
        : style.contentPadding;

    // Deflate the backgroundRect using the chosen padding
    final contentRect = paddingToUse.deflateRect(rect);

    // Calculate content top based on the potentially padded contentRect
    final contentTop = contentRect.top;
    final contentLeft = contentRect.left;

    // Create text painters for title and time
    final titleTextSpan = TextSpan(
      text: event.title,
      style: style.titleStyle,
    );

    final titlePainter = TextPainter(
      text: titleTextSpan,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1, // Consider allowing multiple lines based on height?
      ellipsis: '...',
    );

    titlePainter.layout(maxWidth: contentRect.width);
    titlePainter.paint(
        canvas, Offset(contentLeft, contentTop)); // Use contentLeft/Top

    // Draw time if there's enough space and enabled in style
    if (contentRect.height > (titlePainter.height + 4) && style.showTime) {
      // Check available space
      final DateFormat timeFormatToUse = timeFormat ?? DateFormat.jm();
      final startTime = timeFormatToUse.format(event.start.toLocal());
      final endTime = timeFormatToUse.format(event.end.toLocal());
      final timeText = event.isAllDay ? 'All Day' : '$startTime - $endTime';

      final timeTextSpan = TextSpan(
        text: timeText,
        style: style.timeStyle,
      );

      final timePainter = TextPainter(
        text: timeTextSpan,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );

      timePainter.layout(maxWidth: contentRect.width);
      // Position time below title
      timePainter.paint(
          canvas, Offset(contentLeft, contentTop + titlePainter.height + 2));
    }
    // TODO: Add location drawing if style.showLocation is true
  }

  /// Draw resize handles for an event based on orientation - Restored full method
  void _drawResizeHandles(
      Canvas canvas, Axis orientation, Rect rect, bool isResizing) {
    final handlePaint = Paint()
      ..color = style.resizeHandleColor
      ..style = PaintingStyle.fill;
    final handleSize = style.resizeHandleSize;

    if (orientation == Axis.vertical) {
      // TEMPORARY DEBUG: Confirm vertical block execution
      debugPrint("DEBUG: Drawing VERTICAL handles (Top/Bottom) for event ${rect}");
      // Draw Top handle
      final topHandleRect = Rect.fromLTWH(
        rect.left + (rect.width - handleSize) / 2,
        rect.top,
        handleSize,
        handleSize,
      );
      // Draw Bottom handle
      final bottomHandleRect = Rect.fromLTWH(
        rect.left + (rect.width - handleSize) / 2,
        rect.bottom - handleSize,
        handleSize,
        handleSize,
      );

      // Highlight active handle during resize
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
        // Draw both normally when just selected
        canvas.drawRect(topHandleRect, handlePaint);
        canvas.drawRect(bottomHandleRect, handlePaint);
      }
    } else {
      // TEMPORARY DEBUG: Confirm horizontal block execution
      debugPrint("DEBUG: Drawing HORIZONTAL handles (Left/Right) for event ${rect}");
      // Horizontal orientation
      // Draw Left handle
      final leftHandleRect = Rect.fromLTWH(
        rect.left,
        rect.top + (rect.height - handleSize) / 2,
        handleSize,
        handleSize,
      );
      // Draw Right handle
      final rightHandleRect = Rect.fromLTWH(
        rect.right - handleSize,
        rect.top + (rect.height - handleSize) / 2,
        handleSize,
        handleSize,
      );

      // Highlight active handle during resize
      if (isResizing && activeResizeHandle == ResizeHandle.left) {
        canvas.drawRect(leftHandleRect, handlePaint);
        final fadedPaint = Paint()
          ..color = style.resizeHandleColor.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rightHandleRect, fadedPaint);
      } else if (isResizing && activeResizeHandle == ResizeHandle.right) {
        final fadedPaint = Paint()
          ..color = style.resizeHandleColor.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawRect(leftHandleRect, fadedPaint);
        canvas.drawRect(rightHandleRect, handlePaint);
      } else {
        // Draw both normally when just selected
        canvas.drawRect(leftHandleRect, handlePaint);
        canvas.drawRect(rightHandleRect, handlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant EventRenderer oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.style != style ||
        oldDelegate.selectedEventId != selectedEventId ||
        oldDelegate.draggedEventId != draggedEventId ||
        oldDelegate.resizedEventId != resizedEventId || // Restored
        oldDelegate.activeResizeHandle != activeResizeHandle || // Restored
        oldDelegate.scrollOffset != scrollOffset;
  }

  /// Find the event at a specific position
  EventLayoutInfo? findEventAt(Offset position) {
    for (final event in events.reversed) {
      // Adjust position based on scroll offset before checking bounds
      final Offset adjustedPosition;
      if (event.orientation == Axis.vertical) {
        adjustedPosition = Offset(position.dx, position.dy + scrollOffset);
      } else {
        // Horizontal
        adjustedPosition = Offset(position.dx + scrollOffset,
            position.dy); // Assuming horizontal scroll
      }

      if (event.finalRect.contains(adjustedPosition)) {
        return event;
      }
    }
    return null;
  }

  /// Find the resize handle at a specific position - Restored method
  ResizeHandleHit? findResizeHandleAt(Offset position) {
    final handleSize = style.resizeHandleSize;
    final handleArea = handleSize * 2; // Increase tappable area slightly

    for (final eventLayout in events.reversed) {
      if (eventLayout.event.isAllDay) continue;

      // Adjust position based on scroll offset before checking bounds
      final Offset adjustedPosition;
      if (eventLayout.orientation == Axis.vertical) {
        adjustedPosition = Offset(position.dx, position.dy + scrollOffset);
      } else {
        // Horizontal
        adjustedPosition = Offset(position.dx + scrollOffset, position.dy);
      }

      final rect = eventLayout.finalRect; // Use finalRect (relative to 0,0)

      if (eventLayout.orientation == Axis.vertical) {
        // Top handle (larger tappable area)
        final topHandleTapRect = Rect.fromLTWH(
          rect.left, // Check full width
          rect.top -
              (handleArea / 2) +
              (handleSize / 2), // Center tappable area vertically
          rect.width,
          handleArea,
        );
        // Bottom handle (larger tappable area)
        final bottomHandleTapRect = Rect.fromLTWH(
          rect.left,
          rect.bottom - (handleArea / 2) - (handleSize / 2),
          rect.width,
          handleArea,
        );

        if (topHandleTapRect.contains(adjustedPosition)) {
          return ResizeHandleHit(eventLayout, ResizeHandle.top);
        }
        if (bottomHandleTapRect.contains(adjustedPosition)) {
          return ResizeHandleHit(eventLayout, ResizeHandle.bottom);
        }
      } else {
        // Horizontal orientation
        // Left handle (larger tappable area)
        final leftHandleTapRect = Rect.fromLTWH(
          rect.left -
              (handleArea / 2) +
              (handleSize / 2), // Center tappable area horizontally
          rect.top, // Check full height
          handleArea,
          rect.height,
        );
        // Right handle (larger tappable area)
        final rightHandleTapRect = Rect.fromLTWH(
          rect.right - (handleArea / 2) - (handleSize / 2),
          rect.top,
          handleArea,
          rect.height,
        );

        if (leftHandleTapRect.contains(adjustedPosition)) {
          return ResizeHandleHit(eventLayout, ResizeHandle.left);
        }
        if (rightHandleTapRect.contains(adjustedPosition)) {
          return ResizeHandleHit(eventLayout, ResizeHandle.right);
        }
      }
    }
    return null;
  }
}
