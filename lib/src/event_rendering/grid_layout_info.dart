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
  Duration? _intervalDuration; // Add interval duration
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
  Duration get intervalDuration {
     if (_intervalDuration == null) throw StateError('Grid layout information (intervalDuration) is not available');
     return _intervalDuration!;
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
    required Duration intervalDuration, // Add parameter
  }) {
    _viewStart = viewStart;
    _viewEnd = viewEnd;
    _origin = origin; // Restored to original value
    _availableSpace = availableSpace;
    _orientation = orientation;
    _divisions = divisions;
    _cellWidth = cellWidth;
    _cellHeight = cellHeight;
    _intervalDuration = intervalDuration; // Store interval duration

    // Removed setting _isReady flag
  }

  /// Get the position for a specific date-time and division
  Offset getPositionForDateTime(DateTime dateTime, int division) {
    // Removed isReady check (getters will throw if not initialized)
    // Ensure required properties are initialized
     if (_viewStart == null || _viewEnd == null || _origin == null || _availableSpace == null || _divisions == null || _cellWidth == null || _cellHeight == null || _orientation == null) {
      print("Error: GridLayoutInfo not fully initialized in getPositionForDateTime.");
      // Return origin or throw, depending on desired behavior for uninitialized state
      return _origin ?? Offset.zero;
    }


    // Ensure the date-time is within the overall view range for clamping purposes
    final clampedDateTime = dateTime.isBefore(_viewStart!)
        ? _viewStart!
        : (dateTime.isAfter(_viewEnd!) ? _viewEnd! : dateTime);

    // Clamp division index
    final clampedDivision = division.clamp(0, _divisions! - 1);


    if (_orientation == Axis.vertical) {
      // Vertical Orientation (e.g., Day/Week View)
      // X depends on the division (column/day)
      // Y depends on the time of day relative to the displayed daily time range

      // TODO: Get the actual displayed time range per day (e.g., from controller or config)
      // Assuming 00:00 to 24:00 for now.
      final dayStartHour = 0;
      final dayEndHour = 24;
      final dayDisplayDurationMs = Duration(hours: dayEndHour - dayStartHour).inMilliseconds;

      if (dayDisplayDurationMs <= 0 || _availableSpace!.height <= 0) {
        // Avoid division by zero or invalid state, return origin for the division
        return Offset(_origin!.dx + (clampedDivision * _cellWidth!), _origin!.dy);
      }

      // Calculate the time offset within the displayed day range (milliseconds since midnight of the clampedDateTime)
      final timeOfDayMs = Duration(hours: clampedDateTime.hour, minutes: clampedDateTime.minute, seconds: clampedDateTime.second, milliseconds: clampedDateTime.millisecond).inMilliseconds;
      // Assuming day starts at dayStartHour (e.g., 0 for midnight)
      final startOfDayOffsetMs = Duration(hours: dayStartHour).inMilliseconds;
      // Calculate offset relative to the displayed start hour and clamp within the displayed duration
      final timeOffsetWithinDisplayedDayMs = (timeOfDayMs - startOfDayOffsetMs).clamp(0, dayDisplayDurationMs);

      // Calculate the vertical fraction based on the time within the displayed day range
      double timeFraction;
      // Use the original dateTime for boundary checks, not clampedDateTime
      if (dateTime.isAfter(_viewEnd!)) {
          // If the original time was after the view end, clamp fraction to 1.0 (bottom)
          timeFraction = 1.0;
      } else if (dateTime.isBefore(_viewStart!)) {
          // If the original time was before the view start, clamp fraction to 0.0 (top)
          timeFraction = 0.0;
      } else {
          // Otherwise, calculate fraction normally based on the clamped time within the day
          // Ensure dayDisplayDurationMs is not zero before dividing
          timeFraction = (dayDisplayDurationMs > 0)
              ? timeOffsetWithinDisplayedDayMs / dayDisplayDurationMs
              : 0.0;
      }

      // Calculate position
      final x = _origin!.dx + (clampedDivision * _cellWidth!);
      final y = _origin!.dy + (timeFraction * _availableSpace!.height);
      return Offset(x, y);

    } else { // Horizontal orientation
      // Original logic for horizontal might be okay if it's a simple linear timeline
      // X depends on the time fraction within the total view duration
      // Y depends on the division (row)
      final totalDuration = _viewEnd!.difference(_viewStart!).inMilliseconds;
      if (totalDuration <= 0 || _availableSpace!.width <= 0) {
         // Avoid division by zero, return origin for the division
         return Offset(_origin!.dx, _origin!.dy + (clampedDivision * _cellHeight!));
      }
      // Offset from the start of the entire view
      final offset = clampedDateTime.difference(_viewStart!).inMilliseconds;
      final timeFraction = (offset / totalDuration).clamp(0.0, 1.0);

      final x = _origin!.dx + (timeFraction * _availableSpace!.width);
      final y = _origin!.dy + (clampedDivision * _cellHeight!);
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

    // Ensure viewStart and viewEnd are valid and other properties are initialized
    if (_viewStart == null || _viewEnd == null || _origin == null || _availableSpace == null || _divisions == null || _cellWidth == null || _cellHeight == null || _orientation == null) {
      print("Error: GridLayoutInfo not fully initialized in getDateTimeForPosition.");
      return null; // Or throw StateError
    }

    final totalViewDuration = _viewEnd!.difference(_viewStart!);
    if (totalViewDuration.inMilliseconds <= 0) return null;

    // Position is already relative to the grid origin (top-left of the grid drawing area)
    final relativeX = position.dx;
    final relativeY = position.dy;

    DateTime calculatedTime;

    if (_orientation == Axis.vertical) {
      // Vertical orientation (e.g., Day, Week View)
      // X determines the day (division), Y determines the time within the day

      final availableHeight = _availableSpace!.height;
      final availableWidth = _availableSpace!.width; // Total width for all divisions
      if (availableHeight <= 0 || availableWidth <= 0 || _cellWidth! <= 0 || _divisions! <= 0) return null;

      // 1. Determine the division (day column index)
      int divisionIndex;
      if (_cellWidth! <= 0) {
          divisionIndex = 0; // Avoid division by zero
      } else {
          divisionIndex = (relativeX / _cellWidth!).floor();

          // Check if relativeX is very close to the next cell boundary
          // This handles cases where floating point math might put it just under the boundary
          const boundaryTolerance = 1.0; // Allow 1 pixel tolerance
          double nextBoundary = (divisionIndex + 1) * _cellWidth!;
          if ((nextBoundary - relativeX).abs() < boundaryTolerance) {
             // If we are very close to the *next* boundary, consider it in the next division
             // (unless it's the last division already)
             if (divisionIndex < _divisions! - 1) {
                divisionIndex++;
             }
          }
      }
      divisionIndex = divisionIndex.clamp(0, _divisions! - 1); // Clamp after potential adjustment

      // 2. Determine the time offset based on Y position and interval height/duration
      final clampedY = relativeY.clamp(0.0, availableHeight); // Clamp Y within bounds

      // Calculate how many intervals fit into the clamped Y position
      double intervalsFromTop;
      if (_cellHeight! <= 0) {
        intervalsFromTop = 0; // Avoid division by zero if cell height is invalid
      } else {
        intervalsFromTop = clampedY / _cellHeight!;
      }

      // Calculate the time offset based on the number of intervals and interval duration
      final timeOffsetMs = (intervalsFromTop * _intervalDuration!.inMilliseconds).round();

      // 3. Calculate the base date for the division
      // Assuming viewStart is the start of the first day and days are contiguous.
      final baseDate = _viewStart!.add(Duration(days: divisionIndex));

      // 4. Time offset is already calculated above based on intervals

      // 5. Combine base date and time offset, always constructing a local DateTime
      calculatedTime = DateTime(baseDate.year, baseDate.month, baseDate.day)
          .add(Duration(milliseconds: timeOffsetMs));

    } else { // Horizontal orientation (e.g., Timeline View)
      // Original logic for horizontal might be sufficient if it's a simple linear timeline
      final availableWidth = _availableSpace!.width;
      if (availableWidth <= 0) return null;

      final clampedX = relativeX.clamp(0.0, availableWidth);
      final fraction = availableWidth == 0 ? 0.0 : clampedX / availableWidth; // Avoid division by zero

      final millisecondsOffset = (fraction * totalViewDuration.inMilliseconds).round();
      calculatedTime = _viewStart!.add(Duration(milliseconds: millisecondsOffset));
    }

    // Clamp the final time within the overall view bounds
    if (calculatedTime.isBefore(_viewStart!)) return _viewStart!;
    if (calculatedTime.isAfter(_viewEnd!)) return _viewEnd!;
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
