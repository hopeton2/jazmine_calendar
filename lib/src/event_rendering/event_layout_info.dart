import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

/// Represents layout information for a calendar event
class EventLayoutInfo {
  /// The calendar event being rendered
  final CalendarEvent event;

  /// The orientation of the layout (vertical or horizontal)
  final Axis orientation;

  /// The division (column in vertical layout, row in horizontal layout) this event belongs to
  final int division;

  /// Position along the primary axis (top for vertical, left for horizontal)
  final double start;

  /// Size along the primary axis (height for vertical, width for horizontal)
  final double primarySize;

  /// Position along the secondary axis (left for vertical, top for horizontal)
  /// This is determined by the packing algorithm
  double secondaryStart = 0;

  /// Size along the secondary axis (width for vertical, height for horizontal)
  /// This is determined by the packing algorithm
  double secondarySize = 0;

  /// Width of a single cell/division (needed for scaling secondary axis)
  final double cellWidth;

  /// Height of a single cell/division (needed for scaling secondary axis)
  final double cellHeight;

  // Removed availableSpace field

  // Removed origin field

  /// The initial lane index assigned during packing (0-based). Internal use for packing.
  int laneIndex = 0;

  /// The number of columns this event spans. Calculated during packing.
  int columnSpan = 1;

  /// Convenience getter for the top position
  double get top {
    // For vertical, primary axis is Y (start), secondary is X.
    // For horizontal, primary axis is X (start), secondary is Y.
    return orientation == Axis.vertical
        ? start
        : (secondaryStart * cellHeight); // Scale relative secondaryStart by cell height
  }

  /// Convenience getter for the left position
  double get left {
    // For vertical: Offset by division, then add packed position within division
    // For horizontal: Use the primary axis start position
    return orientation == Axis.vertical
        ? (division * cellWidth) + (secondaryStart * cellWidth)
        : start;
  }

  /// Convenience getter for the width
  double get width {
     // For vertical: Packed size relative to cell width
     // For horizontal: Use the primary axis size
     return orientation == Axis.vertical
        ? (secondarySize * cellWidth)
        : primarySize;
  }

  /// Convenience getter for the height
  double get height {
    return orientation == Axis.vertical
        ? primarySize
        : (secondarySize * cellHeight); // Scale relative secondarySize by cell height
  }

  /// The final rectangle for rendering
  Rect get finalRect => Rect.fromLTWH(left, top, width, height);

  /// Creates a new EventLayoutInfo
  EventLayoutInfo({
    required this.event,
    required this.orientation,
    required this.division,
    required this.start,
    required this.primarySize,
    required this.cellWidth,
    required this.cellHeight,
    // Removed origin parameter
    // Removed availableSpace parameter
  });

  /// Checks if this event overlaps with another in the primary dimension
  bool overlapsWith(EventLayoutInfo other) {
    // Only compare events in the same division
    if (division != other.division) return false;

    final thisEnd = start + primarySize;
    final otherEnd = other.start + other.primarySize;

    // Check for overlap: one event starts before the other ends
    return start < otherEnd && thisEnd > other.start;
  }

  @override
  String toString() {
    return 'EventLayoutInfo(event: ${event.title}, division: $division, lane: $laneIndex, span: $columnSpan, start: $start, primarySize: $primarySize, secondaryStart: $secondaryStart, secondarySize: $secondarySize, cellW: $cellWidth, cellH: $cellHeight)';
  }
}
