import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';

/// CustomPainter for drawing a single calendar event efficiently.
class SingleEventPainter extends CustomPainter {
  final EventLayoutInfo eventLayoutInfo;
  final EventRenderStyle style;
  final bool isSelected;
  final bool isResizing;
  final ResizeHandle? activeResizeHandle;
  final bool enableResize; // Controls handle drawing
  final Color defaultColor;

  SingleEventPainter({
    required this.eventLayoutInfo,
    required this.style,
    required this.isSelected,
    required this.isResizing,
    this.activeResizeHandle,
    required this.enableResize,
    required this.defaultColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final event = eventLayoutInfo.event;
    // Painter works in local coordinates (0,0) to (size.width, size.height)
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final color = event.color ?? style.defaultEventColor; // Use defaultColor from theme

    final backgroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Paint for selected border
    final selectedBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Calculate darker color for unselected border
    final hslColor = HSLColor.fromColor(color);
    // Darken by reducing lightness (e.g., by 0.2), clamp to avoid going below 0
    final darkerColor = hslColor.withLightness(max(0.0, hslColor.lightness - 0.4)).toColor();

    // Paint for unselected border
    final unselectedBorderPaint = Paint()
      ..color = darkerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1; // Thinner border when not selected

    // --- Draw Background & Vertical Indicator ---
    Rect backgroundRect = rect;
    if (eventLayoutInfo.orientation == Axis.vertical &&
        style.verticalIndicatorWidth > 0) {
      backgroundRect = Rect.fromLTWH(
        rect.left + style.verticalIndicatorWidth,
        rect.top,
        max(0.0, rect.width - style.verticalIndicatorWidth),
        rect.height,
      );
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

    // --- Determine BorderRadius ---
    Radius cornerRadius = Radius.circular(style.cornerRadius);
    BorderRadius borderRadius = BorderRadius.all(cornerRadius);
    if (eventLayoutInfo.orientation == Axis.horizontal) {
      // All-day events
      if (eventLayoutInfo.startsBeforeView && eventLayoutInfo.endsAfterView) {
        borderRadius = BorderRadius.zero;
      } else if (eventLayoutInfo.startsBeforeView) {
        borderRadius = BorderRadius.only(
            topRight: cornerRadius, bottomRight: cornerRadius);
      } else if (eventLayoutInfo.endsAfterView) {
        borderRadius =
            BorderRadius.only(topLeft: cornerRadius, bottomLeft: cornerRadius);
      }
    }

    // --- Draw Background RRect & Border ---
    if (backgroundRect.width > 0 && backgroundRect.height > 0) {
      final rrect = RRect.fromRectAndCorners(
        backgroundRect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      );
      canvas.drawRRect(rrect, backgroundPaint);
      // Always draw a border, color depends on selection state
      canvas.drawRRect(rrect, isSelected ? selectedBorderPaint : unselectedBorderPaint);
      _drawContent(canvas, backgroundRect);
    }

    // --- Draw Resize Handles ---
    // Only draw if enabled, selected/resizing, and not all-day
    if (enableResize && (isSelected || isResizing) && !event.isAllDay) {
      _drawResizeHandles(canvas, rect);
    }
  }

  void _drawContent(Canvas canvas, Rect backgroundRect) {
    final event = eventLayoutInfo.event;
    final EdgeInsets paddingToUse =
        eventLayoutInfo.orientation == Axis.horizontal &&
                style.allDayContentPadding != null
            ? style.allDayContentPadding!
            : style.contentPadding;

    final contentRect = paddingToUse.deflateRect(backgroundRect);
    if (contentRect.width <= 0 || contentRect.height <= 0) return;

    double availableHeight = contentRect.height;

    // Title
    final titleSpan =
        TextSpan(text: event.title, style: style.titleStyle);
    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    titlePainter.layout(maxWidth: contentRect.width);
    double titleHeight = titlePainter.height;
    availableHeight -= titleHeight;

    // Time
    TextPainter? timePainter;
    double timeHeight = 0;
    final double estimatedMinSpaceForTime =
        (style.timeStyle.fontSize ?? 10.0) + 4.0;
    if (availableHeight > estimatedMinSpaceForTime &&
        !event.isAllDay &&
        style.showTime) {
      final timeText =
          "${DateFormat.Hm().format(event.start.toLocal())} - ${DateFormat.Hm().format(event.end.toLocal())}";
      final timeSpan = TextSpan(text: timeText, style: style.timeStyle);
      timePainter = TextPainter(
        text: timeSpan,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      timePainter.layout(maxWidth: contentRect.width);

      final double titleTimeSpacing = style.contentPadding.top;
      timeHeight = timePainter.height + titleTimeSpacing;
      if (availableHeight < timeHeight) {
        timePainter = null;
        timeHeight = 0;
      } else {
        availableHeight -= timeHeight;
      }
    }

    // Positioning
    double textTop;
    final contentLeft = contentRect.left;
    if (eventLayoutInfo.orientation == Axis.vertical) {
      textTop = contentRect.top; // Align top
    } else {
      // Horizontal (All-day) - Center vertically
      final double totalTextHeight = titleHeight + timeHeight;
      final double verticalOffset =
          max(0.0, (contentRect.height - totalTextHeight) / 2);
      textTop = contentRect.top + verticalOffset;
    }

    // Paint
    titlePainter.paint(canvas, Offset(contentLeft, textTop));
    if (timePainter != null) {
      final double titleTimeSpacing = style.contentPadding.top;
      timePainter.paint(canvas,
          Offset(contentLeft, textTop + titleHeight + titleTimeSpacing));
    }
  }

  void _drawResizeHandles(Canvas canvas, Rect rect) {
    final handlePaint = Paint()
      ..color = style.resizeHandleColor
      ..style = PaintingStyle.fill;
    final handleSize = style.resizeHandleSize;
    if (handleSize <= 0 || rect.width < handleSize || rect.height < handleSize)
      return;

    final halfHandle = handleSize / 2;

    if (eventLayoutInfo.orientation == Axis.vertical) {
      final topHandleCenter = Offset(rect.center.dx, rect.top + halfHandle);
      final bottomHandleCenter =
          Offset(rect.center.dx, rect.bottom - halfHandle);
      final topHandleRect = Rect.fromCenter(
          center: topHandleCenter, width: handleSize * 1.5, height: handleSize);
      final bottomHandleRect = Rect.fromCenter(
          center: bottomHandleCenter,
          width: handleSize * 1.5,
          height: handleSize);

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
        // Just selected, draw both normally
        canvas.drawRect(topHandleRect, handlePaint);
        canvas.drawRect(bottomHandleRect, handlePaint);
      }
    }
    // No horizontal handles needed based on feedback (resize not typical for all-day)
  }

  @override
  bool shouldRepaint(covariant SingleEventPainter oldDelegate) {
    return oldDelegate.eventLayoutInfo != eventLayoutInfo ||
        oldDelegate.style != style ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isResizing != isResizing ||
        oldDelegate.activeResizeHandle != activeResizeHandle ||
        oldDelegate.enableResize != enableResize || // Include enableResize
        oldDelegate.defaultColor != defaultColor;
  }
}
