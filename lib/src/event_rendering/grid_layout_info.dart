import 'package:equatable/equatable.dart'; // Import equatable
import 'package:flutter/material.dart';

/// Stores and provides grid layout information for a specific grid instance.
/// Uses Equatable for value-based comparison.
class GridLayoutInfo extends Equatable { // Extend Equatable
  // Removed Singleton pattern

  /// Creates a new instance of the broker.
  GridLayoutInfo(); // Public constructor

  // Layout information
  DateTime? _viewStart;
  DateTime? _viewEnd;
  Offset? _origin;
  Size? _availableSpace;
  Axis? _orientation;
  int? _divisions;
  double? _cellWidth;
  double? _cellHeight;
  // Removed _isReady flag

  // Getters
  DateTime get viewStart {
    if (_viewStart == null) throw StateError('Grid layout information (viewStart) is not available');
    return _viewStart!;
  }
  DateTime get viewEnd {
    if (_viewEnd == null) throw StateError('Grid layout information (viewEnd) is not available');
    return _viewEnd!;
  }
  Offset get origin {
    if (_origin == null) throw StateError('Grid layout information (origin) is not available');
    return _origin!;
  }
  Size get availableSpace {
    if (_availableSpace == null) throw StateError('Grid layout information (availableSpace) is not available');
    return _availableSpace!;
  }
  Axis get orientation {
    if (_orientation == null) throw StateError('Grid layout information (orientation) is not available');
    return _orientation!;
  }
  int get divisions {
    if (_divisions == null) throw StateError('Grid layout information (divisions) is not available');
    return _divisions!;
  }
  double get cellWidth {
    if (_cellWidth == null) throw StateError('Grid layout information (cellWidth) is not available');
    return _cellWidth!;
  }
  double get cellHeight {
    if (_cellHeight == null) throw StateError('Grid layout information (cellHeight) is not available');
    return _cellHeight!;
  }

  // This getter is replaced by the _isReady field

  /// Update grid layout information
  void updateGridLayout({
    required DateTime viewStart,
    required DateTime viewEnd,
    required Offset origin,
    required Size availableSpace,
    required Axis orientation,
    required int divisions,
    required double cellWidth,
    required double cellHeight,
  }) {
    _viewStart = viewStart;
    _viewEnd = viewEnd;
    _origin = origin; // Restored to original value
    _availableSpace = availableSpace;
    _orientation = orientation;
    _divisions = divisions;
    _cellWidth = cellWidth;
    _cellHeight = cellHeight;

    // Removed setting _isReady flag
  }

  /// Get the position for a specific date-time and division
  Offset getPositionForDateTime(DateTime dateTime, int division) {
    // Removed isReady check (getters will throw if not initialized)

    // Ensure the date-time is within range
    final effectiveDateTime = dateTime.isBefore(viewStart)
        ? viewStart
        : (dateTime.isAfter(viewEnd) ? viewEnd : dateTime);

    // Calculate position based on time and division
    final totalDuration = viewEnd.difference(viewStart).inMilliseconds;
    // Handle potential zero duration
    if (totalDuration <= 0) return origin; // Return origin if duration is zero or negative
    final offset = effectiveDateTime.difference(viewStart).inMilliseconds;
    final timeFraction = (offset / totalDuration).clamp(0.0, 1.0); // Clamp fraction

    if (orientation == Axis.vertical) {
      // For vertical orientation:
      // - X depends on the division (column)
      // - Y depends on the time
      final x = origin.dx + (division * cellWidth);
      final y = origin.dy + (timeFraction * availableSpace.height);
      return Offset(x, y);
    } else {
      // For horizontal orientation:
      // - X depends on the time
      // - Y depends on the division (row)
      final x = origin.dx + (timeFraction * availableSpace.width);
      final y = origin.dy + (division * cellHeight);
      return Offset(x, y);
    }
  }

  /// Get the size for a duration
  Size getSizeForDuration(Duration duration) {
    // Removed isReady check (getters will throw if not initialized)

    // Calculate size based on duration
    final totalDuration = viewEnd.difference(viewStart).inMilliseconds;
    // Handle potential zero duration
    if (totalDuration <= 0) return Size.zero;
    final fraction = (duration.inMilliseconds / totalDuration).clamp(0.0, 1.0); // Clamp fraction

    if (orientation == Axis.vertical) {
      // For vertical orientation, height depends on duration
      return Size(cellWidth, fraction * availableSpace.height);
    } else {
      // For horizontal orientation, width depends on duration
      return Size(fraction * availableSpace.width, cellHeight);
    }
  }

  /// Get the container rect for a specific division
  Rect getContainerRectForDivision(int division) {
    // Removed isReady check (getters will throw if not initialized)

    if (orientation == Axis.vertical) {
      // For vertical orientation, each division is a column
      return Rect.fromLTWH(
        origin.dx + (division * cellWidth),
        origin.dy,
        cellWidth,
        availableSpace.height,
      );
    } else {
      // For horizontal orientation, each division is a row
      return Rect.fromLTWH(
        origin.dx,
        origin.dy + (division * cellHeight),
        availableSpace.width,
        cellHeight,
      );
    }
  }

  /// Get the date-time for a specific position within the grid
  /// Note: For horizontal layouts, this provides a linear interpolation.
  /// Snapping to specific intervals (like days) might require additional logic
  /// possibly using cellWidth and the duration it represents.
  DateTime? getDateTimeForPosition(Offset position) {
    // Removed isReady check (getters will throw if not initialized)

    final totalDurationMs = viewEnd.difference(viewStart).inMilliseconds;
    if (totalDurationMs <= 0) return null; // Avoid division by zero or negative duration

    double fraction = 0;
    if (orientation == Axis.vertical) {
      // Vertical: Calculate fraction based on Y position relative to available height
      final availableHeight = availableSpace.height;
      if (availableHeight <= 0) return null;
      // Adjust position relative to origin and clamp
      final relativeY = position.dy - origin.dy;
      final clampedY = relativeY.clamp(0.0, availableHeight);
      fraction = clampedY / availableHeight;
    } else { // Horizontal orientation
      // Horizontal: Calculate fraction based on X position relative to available width
      final availableWidth = availableSpace.width;
      if (availableWidth <= 0) return null;
      // Adjust position relative to origin and clamp
      final relativeX = position.dx - origin.dx;
      final clampedX = relativeX.clamp(0.0, availableWidth);
      fraction = clampedX / availableWidth;
    }

    // Calculate the time offset based on the fraction
    final millisecondsOffset = (fraction * totalDurationMs).round();

    // Return the calculated time (ensure it's UTC like viewStart/viewEnd)
    // Clamp the final time within view bounds as well
    final calculatedTime = viewStart.add(Duration(milliseconds: millisecondsOffset));
    if (calculatedTime.isBefore(viewStart)) return viewStart;
    if (calculatedTime.isAfter(viewEnd)) return viewEnd;
    return calculatedTime;
  }


  /// Reset the broker (mainly for testing)
  void reset() {
    _viewStart = null;
    _viewEnd = null;
    _origin = null;
    _availableSpace = null;
    _orientation = null;
    _divisions = null;
    _cellWidth = null;
    _cellHeight = null;
    // Removed resetting _isReady flag
  }

  @override
  List<Object?> get props => [
        _viewStart,
        _viewEnd,
        _origin,
        _availableSpace,
        _orientation,
        _divisions,
        _cellWidth,
        _cellHeight,
      ];

  // Optional: Add stringify for easier debugging if needed
  // @override
  // bool get stringify => true;
}
