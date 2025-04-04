import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math'; // Import for min function
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
  // Add parameters for filtering
  final bool isCollapsed;
  final double? collapsedContentHeight;

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
    // Add to constructor
    this.isCollapsed = false,
    this.collapsedContentHeight,
  });

  // --- Drawing Helper Methods ---

  /// Draw the "+N more" indicator
  void _drawMoreIndicator(Canvas canvas, EventLayoutInfo layout, Rect eventRect) {
    // Ensure we have a positive count to display
    if (layout.hiddenEventCount <= 0) return;

    final text = "+${layout.hiddenEventCount}";
    // Use a slightly smaller font size than the event time style
    final textStyle = style.timeStyle.copyWith(
      fontSize: 10, // Font size for indicator
      color: style.timeStyle.color?.withOpacity(0.9) ?? Colors.white70,
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    );

    textPainter.layout();

    // Position at bottom-right, slightly inset
    final double hPadding = 4.0; // Horizontal padding inside capsule
    final double vPadding = 1.0; // Vertical padding inside capsule
    final indicatorWidth = textPainter.width + hPadding * 2;
    final indicatorHeight = textPainter.height + vPadding * 2;
    final double margin = 2.0; // Margin from event edges

    // Ensure indicator doesn't exceed event bounds (especially for narrow events)
    final double availableWidth = eventRect.width - margin * 2;
    final double finalIndicatorWidth = min(indicatorWidth, availableWidth);
    final double availableHeight = eventRect.height - margin * 2;
    final double finalIndicatorHeight = min(indicatorHeight, availableHeight);

    // Don't draw if calculated size is non-positive
    if (finalIndicatorWidth <= 0 || finalIndicatorHeight <= 0) return;

    final indicatorRect = Rect.fromLTWH(
      eventRect.right - finalIndicatorWidth - margin, // Position from right edge
      eventRect.bottom - finalIndicatorHeight - margin, // Position from bottom edge
      finalIndicatorWidth,
      finalIndicatorHeight,
    );

    // Draw background capsule
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5) // Slightly darker background
      ..style = PaintingStyle.fill;
    // Use radius proportional to height for a nice capsule shape
    final rrect = RRect.fromRectAndRadius(indicatorRect, Radius.circular(finalIndicatorHeight / 2));
    canvas.drawRRect(rrect, backgroundPaint);

    // Draw text centered within the capsule
    textPainter.paint(
      canvas,
      Offset(
        indicatorRect.left + (finalIndicatorWidth - textPainter.width) / 2,
        indicatorRect.top + (finalIndicatorHeight - textPainter.height) / 2,
      ),
    );
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
    // Skip drawing events that were hidden by the packer (if packer sets size to 0)
    // Note: Current packer assigns full height, relying on clipping.
    // If packer logic changes to set size=0, this check becomes relevant.
    // if (layout.secondarySize <= 0) return;

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

    // Determine the border radius based on whether the event extends beyond the view
    Radius cornerRadius = Radius.circular(style.cornerRadius);
    BorderRadius borderRadius = BorderRadius.all(cornerRadius);

    if (layout.orientation == Axis.horizontal) { // Only adjust for horizontal (all-day) events
      if (layout.startsBeforeView && layout.endsAfterView) {
        // Flat on both sides
        borderRadius = BorderRadius.zero;
      } else if (layout.startsBeforeView) {
        // Flat on left side
        borderRadius = BorderRadius.only(
          topRight: cornerRadius,
          bottomRight: cornerRadius,
        );
      } else if (layout.endsAfterView) {
        // Flat on right side
        borderRadius = BorderRadius.only(
          topLeft: cornerRadius,
          bottomLeft: cornerRadius,
        );
      }
      // else: fully within view, use default full borderRadius
    }

    final rrect = RRect.fromRectAndCorners(
      backgroundRect,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );
    canvas.drawRRect(rrect, backgroundPaint);

    if (isSelected) {
      // Use the same potentially adjusted borderRadius for the border
      canvas.drawRRect(rrect, borderPaint);
    }

    _drawEventContent(canvas, layout, backgroundRect); // Pass backgroundRect

    // Draw "+N more" indicator if needed (only for horizontal events)
    if (layout.orientation == Axis.horizontal && layout.hasMoreIndicator) {
      _drawMoreIndicator(canvas, layout, rect); // Call the helper method
    }

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

    // Calculate vertical offset to center the text block
    final double verticalOffset = (contentRect.height - _calculateTextHeight(layout, contentRect.width)) / 2;
    final double textTop = contentRect.top + verticalOffset;
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
    // Paint title centered vertically
    titlePainter.paint(canvas, Offset(contentLeft, textTop));


    // Draw time if there's enough space and enabled in style
    TextPainter? timePainter = _getTimePainter(layout, contentRect.width);
    if (timePainter != null) {
       // Paint time below title, also centered vertically within the block
       timePainter.paint(
           canvas, Offset(contentLeft, textTop + titlePainter.height + 2)); // Add spacing
    }
    // TODO: Add location drawing if style.showLocation is true and adjust centering
  }

  // Helper to calculate total text height for centering
  double _calculateTextHeight(EventLayoutInfo layout, double maxWidth) {
      final event = layout.event;
      final titleTextSpan = TextSpan(text: event.title, style: style.titleStyle);
      final titlePainter = TextPainter(text: titleTextSpan, textDirection: ui.TextDirection.ltr, maxLines: 1, ellipsis: '...');
      titlePainter.layout(maxWidth: maxWidth);
      double totalHeight = titlePainter.height;

      TextPainter? timePainter = _getTimePainter(layout, maxWidth);
      if (timePainter != null) {
          totalHeight += timePainter.height + 2; // Add spacing
      }
      // Add location height if implemented
      return totalHeight;
  }

  // Helper to create time painter (avoids duplication)
  TextPainter? _getTimePainter(EventLayoutInfo layout, double maxWidth) {
      final event = layout.event;
      // Return null immediately if it's an all-day event or time shouldn't be shown
      if (!style.showTime || event.isAllDay) return null;

      // Only format time if it's not an all-day event
      final DateFormat timeFormatToUse = timeFormat ?? DateFormat.jm();
      final startTime = timeFormatToUse.format(event.start.toLocal());
      final endTime = timeFormatToUse.format(event.end.toLocal());
      final timeText = '$startTime - $endTime'; // Removed the 'All Day' condition
      final timeTextSpan = TextSpan(text: timeText, style: style.timeStyle);
      final timePainter = TextPainter(
        text: timeTextSpan,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      timePainter.layout(maxWidth: maxWidth);
      return timePainter;
  }


  /// Draw resize handles for an event based on orientation - Restored full method
  void _drawResizeHandles(
      Canvas canvas, Axis orientation, Rect rect, bool isResizing) {
    final handlePaint = Paint()
      ..color = style.resizeHandleColor
      ..style = PaintingStyle.fill;
    final handleSize = style.resizeHandleSize;

    if (orientation == Axis.vertical) {
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

  // --- Overrides & Hit Testing ---

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

      Rect rect = Rect.fromLTWH(
        calculatedRect.left - leftAdjust,
        calculatedRect.top - topAdjust,
        calculatedRect.width,
        calculatedRect.height,
      );

      // Add horizontal margin for horizontal events
      if (eventLayout.orientation == Axis.horizontal) {
        const double horizontalMargin = 2.0; // 2 pixel margin
        // Ensure width doesn't become negative
        if (rect.width > horizontalMargin * 2) {
          rect = Rect.fromLTWH(
            rect.left + horizontalMargin,
            rect.top,
            rect.width - (horizontalMargin * 2),
            rect.height,
          );
        }
      }

      // Skip drawing if height or width is zero or negative
      if (rect.width <= 0 || rect.height <= 0) continue;

      // --- Filtering logic for collapsed all-day events ---
      if (eventLayout.orientation == Axis.horizontal && // Check if it's an all-day event
          isCollapsed &&                             // Check if the grid is collapsed
          collapsedContentHeight != null) {            // Check if we have a height limit
          // Calculate the event's bottom edge relative to the start of the content area
          final eventBottom = eventLayout.secondaryStart + eventLayout.secondarySize;
          // If the event's bottom edge exceeds the allowed content height, skip drawing
          if (eventBottom > collapsedContentHeight!) {
             continue; // Skip this event
          }
      }
      // --- End filtering logic ---

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

  @override
  bool shouldRepaint(covariant EventRenderer oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.style != style ||
        oldDelegate.selectedEventId != selectedEventId ||
        oldDelegate.draggedEventId != draggedEventId ||
        oldDelegate.resizedEventId != resizedEventId || // Restored
        oldDelegate.activeResizeHandle != activeResizeHandle || // Restored
        oldDelegate.scrollOffset != scrollOffset ||
        // Add new fields to shouldRepaint check
        oldDelegate.isCollapsed != isCollapsed ||
        oldDelegate.collapsedContentHeight != collapsedContentHeight;
  }

  /// Find the event at a specific position
  EventLayoutInfo? findEventAt(Offset position) {
    for (final event in events.reversed) {
       // Skip events with no size (hidden by packer)
       if (event.secondarySize <= 0) continue;

      // Adjust position based on scroll offset before checking bounds
      final Offset adjustedPosition;
      if (event.orientation == Axis.vertical) {
        adjustedPosition = Offset(position.dx, position.dy + scrollOffset);
      } else {
        // Horizontal
        adjustedPosition = Offset(position.dx + scrollOffset,
            position.dy); // Assuming horizontal scroll for now
      }

      // Use the calculated finalRect for hit testing
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
      // Skip events with no size (hidden by packer)
      if (eventLayout.secondarySize <= 0) continue;

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
          rect.top - (handleArea / 2) + (handleSize / 2), // Center tappable area vertically
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
          rect.left - (handleArea / 2) + (handleSize / 2), // Center tappable area horizontally
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

  // Removed findMoreIndicatorHitbox method

} // Closing brace for EventRenderer class
