import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math'; // Import for min function
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/enums/enums.dart'; // Ensure enums are imported for ResizeHandle
import 'package:jazmine_calendar/src/models/calendar_event.dart'; // Import CalendarEvent
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

// Define ResizeHandleHit class locally
class ResizeHandleHit {
  final EventLayoutInfo event;
  final ResizeHandle handle; // Use ResizeHandle from enums.dart

  ResizeHandleHit(this.event, this.handle);
}

/// Custom painter for rendering calendar events
class EventRenderer extends CustomPainter {
  /// List of events to render (already laid out and packed)
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

  // Parameters for filtering collapsed all-day events
  final bool isCollapsed;
  final double? collapsedContentHeight;

  // --- New parameters for drawing dragged event ---
  /// The current position of the pointer during a drag operation (adjusted for scroll)
  final Offset? currentDragPosition;
  /// The offset from the top-left of the dragged event to the initial pan position
  final Offset? dragOffset;
  // --- End new parameters ---

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
    this.isCollapsed = false,
    this.collapsedContentHeight,
    this.currentDragPosition, // Add to constructor
    this.dragOffset,         // Add to constructor
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
    bool isResized = false,
    required Rect rect, // Use the adjusted rect passed from paint method
  }) {

    final event = layout.event;
    final color = style.getColorForEvent(event);
    final backgroundPaint = Paint()
      // Apply opacity if dragged
      ..color = isDragged ? color.withOpacity(0.7) : color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = style.resizeHandleColor // Use resize handle color as default border? Or white? Let's use white.
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Default selected border width

    // Draw the event background (potentially adjusted for vertical indicator)
    Rect backgroundRect = rect;
    if (layout.orientation == Axis.vertical &&
        style.verticalIndicatorWidth > 0) {
      backgroundRect = Rect.fromLTWH(
        rect.left + style.verticalIndicatorWidth,
        rect.top,
        max(0.0, rect.width - style.verticalIndicatorWidth), // Ensure non-negative width
        rect.height,
      );
      // Ensure indicator doesn't draw if backgroundRect width becomes non-positive
      if (backgroundRect.width > 0) {
          final indicatorPaint = Paint()
            ..color = style.verticalIndicatorColor ?? color
            ..style = PaintingStyle.fill;
          canvas.drawRect(
            Rect.fromLTWH(
                rect.left, rect.top, style.verticalIndicatorWidth, rect.height),
            indicatorPaint,
          );
      }
    }

    // Determine the border radius based on whether the event extends beyond the view
    Radius cornerRadius = Radius.circular(style.cornerRadius);
    BorderRadius borderRadius = BorderRadius.all(cornerRadius);

    if (layout.orientation == Axis.horizontal) { // Only adjust for horizontal (all-day) events
      if (layout.startsBeforeView && layout.endsAfterView) {
        borderRadius = BorderRadius.zero;
      } else if (layout.startsBeforeView) {
        borderRadius = BorderRadius.only(topRight: cornerRadius, bottomRight: cornerRadius);
      } else if (layout.endsAfterView) {
        borderRadius = BorderRadius.only(topLeft: cornerRadius, bottomLeft: cornerRadius);
      }
    }

    // Ensure backgroundRect has positive dimensions before drawing
    if (backgroundRect.width > 0 && backgroundRect.height > 0) {
        final rrect = RRect.fromRectAndCorners(
          backgroundRect,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );
        canvas.drawRRect(rrect, backgroundPaint);

        if (isSelected) {
          canvas.drawRRect(rrect, borderPaint);
        }

        _drawEventContent(canvas, layout, backgroundRect); // Pass backgroundRect
    }


    // Draw "+N more" indicator if needed (only for horizontal events)
    if (layout.orientation == Axis.horizontal && layout.hasMoreIndicator) {
      _drawMoreIndicator(canvas, layout, rect); // Call the helper method
    }

    // Draw resize handles if this event is selected or being resized
    // Don't draw handles if it's being dragged
    if ((isSelected || isResized) && !isDragged && !event.isAllDay) {
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

    // Ensure contentRect has positive dimensions
    if (contentRect.width <= 0 || contentRect.height <= 0) return;

    // Calculate available height for text
    double availableHeight = contentRect.height;

    // Create text painters for title and time
    final titleTextSpan = TextSpan(
      text: event.title,
      style: style.titleStyle,
    );

    final titlePainter = TextPainter(
      text: titleTextSpan,
      textDirection: ui.TextDirection.ltr,
      maxLines: 2, // Allow up to 2 lines for title by default
      ellipsis: '...',
    );

    titlePainter.layout(maxWidth: contentRect.width);

    // Calculate height needed for title
    double titleHeight = titlePainter.height;
    availableHeight -= titleHeight; // Reduce available height

    // Create time painter only if needed and space allows
    TextPainter? timePainter;
    double timeHeight = 0;
    // Use a reasonable default minimum space (e.g., font size + padding)
    // Estimate min space needed based on time text style font size + some padding
    final double estimatedMinSpaceForTime = (style.timeStyle.fontSize ?? 10.0) + 4.0;
    if (availableHeight > estimatedMinSpaceForTime && !event.isAllDay && style.showTime) {
      timePainter = _getTimePainter(layout, contentRect.width);
      if (timePainter != null) {
        final double titleTimeSpacing = style.contentPadding.top; // Use content padding as spacing
        timeHeight = timePainter.height + titleTimeSpacing; // Add spacing
        // Check if there's enough space for time after title
        if (availableHeight < timeHeight) {
          timePainter = null; // Not enough space, don't draw time
          timeHeight = 0;
        } else {
           availableHeight -= timeHeight; // Reduce available height
        }
      }
    }

    // TODO: Add location painter calculation if style.showLocation is true

    // Determine text position based on orientation
    double textTop;
    final contentLeft = contentRect.left;

    if (layout.orientation == Axis.vertical) {
      // Top-left alignment for vertical events
      textTop = contentRect.top;
    } else {
      // Center vertically for horizontal events (all-day)
      final double totalTextHeight = titleHeight + timeHeight; // Add location height later
      // Ensure offset is not negative if text is taller than rect
      final double verticalOffset = max(0.0, (contentRect.height - totalTextHeight) / 2);
      textTop = contentRect.top + verticalOffset;
    }

    // Paint title
    titlePainter.paint(canvas, Offset(contentLeft, textTop));

    // Paint time if available
    if (timePainter != null) {
       final double titleTimeSpacing = style.contentPadding.top; // Use content padding as spacing
       timePainter.paint(
           canvas, Offset(contentLeft, textTop + titleHeight + titleTimeSpacing));
    }
    // TODO: Add location painting
  }

  // Helper to create time painter (avoids duplication)
  TextPainter? _getTimePainter(EventLayoutInfo layout, double maxWidth) {
      final event = layout.event;
      // Return null immediately if it's an all-day event or time shouldn't be shown
      // Style check moved to _drawEventContent
      if (event.isAllDay) return null;

      final DateFormat timeFormatToUse = timeFormat ?? DateFormat.jm();
      final startTime = timeFormatToUse.format(event.start.toLocal());
      final endTime = timeFormatToUse.format(event.end.toLocal());
      final timeText = '$startTime - $endTime';
      final timeTextSpan = TextSpan(text: timeText, style: style.timeStyle);
      final timePainter = TextPainter(
        text: timeTextSpan,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1, // Time should generally be one line
        ellipsis: '...',
      );
      timePainter.layout(maxWidth: maxWidth);

      // Check if time text actually fits
      if (timePainter.didExceedMaxLines || timePainter.width > maxWidth) {
         return null; // Don't return painter if it doesn't fit
      }

      return timePainter;
  }


  /// Draw resize handles for an event based on orientation
  void _drawResizeHandles(
      Canvas canvas, Axis orientation, Rect rect, bool isResizing) {
    final handlePaint = Paint()
      ..color = style.resizeHandleColor
      ..style = PaintingStyle.fill;
    final handleSize = style.resizeHandleSize;

    // Don't draw if handle size is non-positive or rect is too small
    if (handleSize <= 0 || rect.width < handleSize || rect.height < handleSize) return;

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
        final fadedPaint = Paint()..color = style.resizeHandleColor.withOpacity(0.5)..style = PaintingStyle.fill;
        canvas.drawRect(bottomHandleRect, fadedPaint);
      } else if (isResizing && activeResizeHandle == ResizeHandle.bottom) {
        final fadedPaint = Paint()..color = style.resizeHandleColor.withOpacity(0.5)..style = PaintingStyle.fill;
        canvas.drawRect(topHandleRect, fadedPaint);
        canvas.drawRect(bottomHandleRect, handlePaint);
      } else {
        // Draw both normally when just selected
        canvas.drawRect(topHandleRect, handlePaint);
        canvas.drawRect(bottomHandleRect, handlePaint);
      }
    } else { // Horizontal orientation (All-day events - resize not typically enabled)
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
         final fadedPaint = Paint()..color = style.resizeHandleColor.withOpacity(0.5)..style = PaintingStyle.fill;
         canvas.drawRect(rightHandleRect, fadedPaint);
       } else if (isResizing && activeResizeHandle == ResizeHandle.right) {
         final fadedPaint = Paint()..color = style.resizeHandleColor.withOpacity(0.5)..style = PaintingStyle.fill;
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
    // --- Draw static events first ---
    for (final eventLayout in events) {
      // Skip drawing the static version of the event currently being dragged.
      if (eventLayout.event.id == draggedEventId) {
        continue;
      }

      // Apply scroll offset to the event's position
      final calculatedRect = eventLayout.finalRect; // Rect relative to content area (0,0)
      // Scroll offset only applies vertically for now
      final topAdjust = eventLayout.orientation == Axis.vertical ? scrollOffset : 0.0;
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

      // Determine if this event is selected or being resized
      final isSelected = selectedEventId == eventLayout.event.id;
      // Note: isDragged is handled separately below
      final isResized = resizedEventId == eventLayout.event.id;

      // Draw the event with the adjusted rect
      _drawEvent(
        canvas,
        eventLayout,
        isSelected: isSelected,
        isDragged: false, // Static events are never drawn as dragged here
        isResized: isResized,
        rect: rect, // Pass the adjusted rect
      );
    }

    // --- Restore drawing the dragged event separately ---
    if (draggedEventId != null && currentDragPosition != null && dragOffset != null) {
      // Find the layout info for the dragged event
      final draggedEventLayout = events.firstWhereOrNull((e) => e.event.id == draggedEventId);

      if (draggedEventLayout != null) {
        // Calculate the raw top-left based on current drag position and initial offset
        final rawDragTopLeft = currentDragPosition! - dragOffset!;

        // Adjust the calculated top position by subtracting the current scroll offset
        // This converts the position to the canvas's visible coordinate system.
        final adjustedTop = rawDragTopLeft.dy - (draggedEventLayout.orientation == Axis.vertical ? scrollOffset : 0.0);
        final adjustedLeft = rawDragTopLeft.dx; // Assuming no horizontal scroll adjustment needed

        // Create the rectangle for the dragged event at the adjusted position
        final dragRect = Rect.fromLTWH(
          adjustedLeft,
          adjustedTop,
          // Use the original calculated width/height from layoutInfo
          draggedEventLayout.finalRect.width,
          draggedEventLayout.finalRect.height,
        );

        // Draw the dragged event using the adjusted rectangle
        _drawEvent(
          canvas,
          draggedEventLayout,
          isSelected: false, // Don't show selected border while dragging
          isDragged: true,   // Apply drag styling (e.g., opacity)
          isResized: false,
          rect: dragRect,
        );
      }
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
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.isCollapsed != isCollapsed ||
        oldDelegate.collapsedContentHeight != collapsedContentHeight ||
        // Add new fields to shouldRepaint check
        oldDelegate.currentDragPosition != currentDragPosition ||
        oldDelegate.dragOffset != dragOffset;
  }

  /// Find the event at a specific position (relative to the CustomPaint widget)
  EventLayoutInfo? findEventAt(Offset position) {
    // The 'position' argument is the raw local position from the gesture detector.
    // We need to adjust it by the scroll offset to compare with event rects
    // which are calculated in the unscrolled coordinate space.
    final Offset adjustedPosition = Offset(position.dx, position.dy + scrollOffset);

    // Check the dragged event first if applicable (it's visually on top)
    if (draggedEventId != null && currentDragPosition != null && dragOffset != null) {
        final draggedEventLayout = events.firstWhereOrNull((e) => e.event.id == draggedEventId);
        if (draggedEventLayout != null) {
            // Calculate the current top-left of the dragged event in unscrolled coordinates
            final dragTopLeft = currentDragPosition! - dragOffset!;
            final dragRect = Rect.fromLTWH(
                dragTopLeft.dx,
                dragTopLeft.dy,
                draggedEventLayout.width,
                draggedEventLayout.height,
            );
            if (dragRect.contains(adjustedPosition)) {
                return draggedEventLayout;
            }
        }
    }


    // Check other events in reverse order (topmost visually are last in list)
    for (final eventLayout in events.reversed) {
      // Skip the currently dragged event since we checked it above
      if (eventLayout.event.id == draggedEventId) continue;

      // Check if the adjusted position hits the event's calculated rect
      if (eventLayout.finalRect.contains(adjustedPosition)) {
        return eventLayout;
      }
    }
    return null;
  }

  /// Find if a resize handle is hit at a specific position
  ResizeHandleHit? findResizeHandleAt(Offset position) {
    // Adjust position for scroll offset
    final Offset adjustedPosition = Offset(position.dx, position.dy + scrollOffset);
    final handleSize = style.resizeHandleSize;
    final handleArea = handleSize * 2; // Increase tap area slightly

    // Check only the selected event, or potentially the event being resized
    final targetEventId = resizedEventId ?? selectedEventId;
    if (targetEventId == null) return null;

    final eventLayout = events.firstWhereOrNull((e) => e.event.id == targetEventId);
    if (eventLayout == null || eventLayout.event.isAllDay) return null; // No handles for all-day

    final rect = eventLayout.finalRect;

    if (eventLayout.orientation == Axis.vertical) {
      // Top handle (check a larger area)
      final topHandleRect = Rect.fromCenter(
        center: Offset(rect.center.dx, rect.top + handleSize / 2),
        width: rect.width, // Check full width
        height: handleArea,
      );
      if (topHandleRect.contains(adjustedPosition)) {
        return ResizeHandleHit(eventLayout, ResizeHandle.top);
      }

      // Bottom handle (check a larger area)
      final bottomHandleRect = Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom - handleSize / 2),
        width: rect.width, // Check full width
        height: handleArea,
      );
      if (bottomHandleRect.contains(adjustedPosition)) {
        return ResizeHandleHit(eventLayout, ResizeHandle.bottom);
      }
    } else { // Horizontal (All-day - currently no resize)
       // Left handle
       final leftHandleRect = Rect.fromCenter(
         center: Offset(rect.left + handleSize / 2, rect.center.dy),
         width: handleArea,
         height: rect.height, // Check full height
       );
       if (leftHandleRect.contains(adjustedPosition)) {
         return ResizeHandleHit(eventLayout, ResizeHandle.left);
       }
       // Right handle
       final rightHandleRect = Rect.fromCenter(
         center: Offset(rect.right - handleSize / 2, rect.center.dy),
         width: handleArea,
         height: rect.height, // Check full height
       );
       if (rightHandleRect.contains(adjustedPosition)) {
         return ResizeHandleHit(eventLayout, ResizeHandle.right);
       }
    }

    return null;
  }
}
