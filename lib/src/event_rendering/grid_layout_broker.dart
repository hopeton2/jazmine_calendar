import 'package:flutter/material.dart';

/// A broker service that stores and provides grid layout information
class GridLayoutBroker {
  // Singleton pattern
  static final GridLayoutBroker _instance = GridLayoutBroker._internal();
  factory GridLayoutBroker() => _instance;
  GridLayoutBroker._internal();

  // Layout information
  DateTime? _viewStart;
  DateTime? _viewEnd;
  Offset? _origin;
  Size? _availableSpace;
  Axis? _orientation;
  int? _divisions;
  double? _cellWidth;
  double? _cellHeight;
  bool _isReady = false;

  // Getters
  DateTime get viewStart {
    if (!_isReady) throw StateError('Grid layout information is not available');
    return _viewStart!;
  }
  DateTime get viewEnd {
    if (!_isReady) throw StateError('Grid layout information is not available');
    return _viewEnd!;
  }
  Offset get origin {
    if (!_isReady) throw StateError('Grid layout information is not available');
    return _origin!;
  }
  Size get availableSpace {
    if (!_isReady) throw StateError('Grid layout information is not available');
    return _availableSpace!;
  }
  Axis get orientation {
    if (!_isReady) throw StateError('Grid layout information is not available');
    return _orientation!;
  }
  int get divisions {
    if (!_isReady) throw StateError('Grid layout information is not available');
    return _divisions!;
  }
  double get cellWidth {
    if (!_isReady) throw StateError('Grid layout information is not available');
    return _cellWidth!;
  }
  double get cellHeight {
    if (!_isReady) throw StateError('Grid layout information is not available');
    return _cellHeight!;
  }
  bool get isReady => _isReady;

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

    // Set ready flag
    _isReady = true;

    // TEMPORARY DEBUG - Remove after debugging
    print(
        'DEBUG: GridLayoutBroker updated at ${DateTime.now().toIso8601String()} - Stack trace:\n${StackTrace.current}');
  }

  /// Get the position for a specific date-time and division
  Offset getPositionForDateTime(DateTime dateTime, int division) {
    if (!isReady) {
      throw StateError('Grid layout information is not available');
    }

    // Ensure the date-time is within range
    final effectiveDateTime = dateTime.isBefore(viewStart)
        ? viewStart
        : (dateTime.isAfter(viewEnd) ? viewEnd : dateTime);

    // Calculate position based on time and division
    final totalDuration = viewEnd.difference(viewStart).inMilliseconds;
    final offset = effectiveDateTime.difference(viewStart).inMilliseconds;
    final timeFraction = offset / totalDuration;

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
    if (!isReady) {
      throw StateError('Grid layout information is not available');
    }

    // Calculate size based on duration
    final totalDuration = viewEnd.difference(viewStart).inMilliseconds;
    final fraction = duration.inMilliseconds / totalDuration;

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
    if (!isReady) {
      throw StateError('Grid layout information is not available');
    }

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
  }
}
