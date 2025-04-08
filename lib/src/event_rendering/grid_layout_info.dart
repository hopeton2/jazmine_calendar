import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Stores and provides immutable grid layout information for a specific grid instance.
/// Uses Equatable for value-based comparison.
@immutable // Add immutable annotation
class GridLayoutInfo extends Equatable {
  final DateTime viewStart;
  final DateTime viewEnd;
  final Offset origin;
  final Size availableSpace;
  final Axis orientation;
  final int divisions;
  final double cellWidth;
  final double cellHeight;
  final Duration intervalDuration;
  final double headerWidth;
  final double headerHeight;

  /// Creates a new immutable instance of GridLayoutInfo.
  const GridLayoutInfo({
    required this.viewStart,
    required this.viewEnd,
    required this.origin,
    required this.availableSpace,
    required this.orientation,
    required this.divisions,
    required this.cellWidth,
    required this.cellHeight,
    required this.intervalDuration,
    required this.headerWidth, 
    required this.headerHeight, 
  });

  // Removed Getters (use direct final fields)
  // Removed updateGridLayout method

  /// Get the position for a specific date-time and division
  Offset getPositionForDateTime(DateTime dateTime, int division) {
    // Ensure the date-time is within the overall view range for clamping purposes
    // Use final public fields directly
    final clampedDateTime = dateTime.isBefore(viewStart)
        ? viewStart
        : (dateTime.isAfter(viewEnd) ? viewEnd : dateTime);

    // Clamp division index
    final clampedDivision = division.clamp(0, divisions - 1);


    if (orientation == Axis.vertical) {
      // Vertical Orientation (e.g., Day/Week View)
      // X depends on the division (column/day)
      // Y depends on the time of day relative to the displayed daily time range

      // TODO: Get the actual displayed time range per day (e.g., from controller or config)
      // Assuming 00:00 to 24:00 for now.
      final dayStartHour = 0;
      final dayEndHour = 24;
      final dayDisplayDurationMs = Duration(hours: dayEndHour - dayStartHour).inMilliseconds;

      // Use final public fields directly
      if (dayDisplayDurationMs <= 0 || availableSpace.height <= 0 || cellWidth <= 0) {
        // Avoid division by zero or invalid state, return origin for the division
        return Offset(origin.dx + (clampedDivision * cellWidth), origin.dy);
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
      // Use final public fields directly
      if (dateTime.isAfter(viewEnd)) { // Corrected: Use viewEnd
          // If the original time was after the view end, clamp fraction to 1.0 (bottom)
          timeFraction = 1.0;
      } else if (dateTime.isBefore(viewStart)) { // Corrected: Use viewStart
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
      // Use final public fields directly
      final x = origin.dx + (clampedDivision * cellWidth);
      final y = origin.dy + (timeFraction * availableSpace.height);
      return Offset(x, y);

    } else { // Horizontal orientation
      // Original logic for horizontal might be okay if it's a simple linear timeline
      // X depends on the time fraction within the total view duration
      // Y depends on the division (row)
      // Use final public fields directly
      final totalDuration = viewEnd.difference(viewStart).inMilliseconds;
      if (totalDuration <= 0 || availableSpace.width <= 0 || cellHeight <= 0) {
         // Avoid division by zero, return origin for the division
         return Offset(origin.dx, origin.dy + (clampedDivision * cellHeight));
      }
      // Offset from the start of the entire view
      // Use final public fields directly
      final offset = clampedDateTime.difference(viewStart).inMilliseconds; // Corrected: Use viewStart
      final timeFraction = (offset / totalDuration).clamp(0.0, 1.0);
  
      final x = origin.dx + (timeFraction * availableSpace.width);
      final y = origin.dy + (clampedDivision * cellHeight);
      return Offset(x, y);
    }
  }

  /// Get the size for a duration
  Size getSizeForDuration(Duration duration) {
    // Use final public fields directly
    final totalDuration = viewEnd.difference(viewStart).inMilliseconds;
    if (totalDuration <= 0) return Size.zero;
    final fraction = (duration.inMilliseconds / totalDuration).clamp(0.0, 1.0);

    if (orientation == Axis.vertical) {
      return Size(cellWidth, fraction * availableSpace.height);
    } else {
      return Size(fraction * availableSpace.width, cellHeight);
    }
  }

  /// Get the container rect for a specific division
  Rect getContainerRectForDivision(int division) {
    // Use final public fields directly
    final clampedDivision = division.clamp(0, divisions - 1); // Clamp division
    if (orientation == Axis.vertical) {
      return Rect.fromLTWH(
        origin.dx + (clampedDivision * cellWidth),
        origin.dy,
        cellWidth,
        availableSpace.height,
      );
    } else {
      return Rect.fromLTWH(
        origin.dx,
        origin.dy + (clampedDivision * cellHeight),
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
    // Use final public fields directly (constructor ensures they are non-null)

    final totalViewDuration = viewEnd.difference(viewStart);
    if (totalViewDuration.inMilliseconds <= 0) return viewStart; // Return start if duration invalid

    // Position is already relative to the grid origin (top-left of the grid drawing area)
    // Position relative to the grid origin
    final relativeX = position.dx - origin.dx;
    // Removed hardcoded offset '- 193' from original code as it seemed incorrect.
    // Assuming input 'position' is relative to the widget origin, adjust by grid origin.
    final relativeY = position.dy - origin.dy;

    DateTime calculatedTime;

    if (orientation == Axis.vertical) {
      // Vertical orientation (e.g., Day, Week View)
      final availableHeight = availableSpace.height;
      final availableWidth = availableSpace.width; // Total width for all divisions
      // Use final public fields directly
      if (availableHeight <= 0 || availableWidth <= 0 || cellWidth <= 0 || divisions <= 0 || cellHeight <= 0 || intervalDuration.inMilliseconds <= 0) {
         return viewStart; // Return start if grid dimensions are invalid
      }

      // 1. Determine the division (day column index)
      int divisionIndex;
      // Use final public fields directly
      if (cellWidth <= 0) {
          divisionIndex = 0; // Avoid division by zero
      } else {
          divisionIndex = (relativeX / cellWidth).floor();

          // Check if relativeX is very close to the next cell boundary
          // This handles cases where floating point math might put it just under the boundary
          const boundaryTolerance = 1.0; // Allow 1 pixel tolerance
          // Use final public fields directly
          double nextBoundary = (divisionIndex + 1) * cellWidth;
          if ((nextBoundary - relativeX).abs() < boundaryTolerance) {
             // If we are very close to the *next* boundary, consider it in the next division
             // (unless it's the last division already)
             if (divisionIndex < divisions - 1) {
                divisionIndex++;
             }
          }
      }
      divisionIndex = divisionIndex.clamp(0, divisions - 1); // Clamp after potential adjustment

      // 2. Determine the time offset based on Y position and interval height/duration
      final clampedY = relativeY.clamp(0.0, availableHeight); // Clamp Y within bounds

      // Calculate how many intervals fit into the clamped Y position
      double intervalsFromTop;
      // Use final public fields directly
      if (cellHeight <= 0) {
        intervalsFromTop = 0; // Avoid division by zero if cell height is invalid
      } else {
        intervalsFromTop = clampedY / cellHeight;
      }

      // Calculate the time offset based on the number of intervals and interval duration
      // Use final public fields directly
      final timeOffsetMs = (intervalsFromTop * intervalDuration.inMilliseconds).round();

      // 3. Calculate the base date for the division
      // Assuming viewStart is the start of the first day and days are contiguous.
      final baseDate = viewStart.add(Duration(days: divisionIndex));

      // 4. Time offset is already calculated above based on intervals

      // 5. Combine base date and time offset, always constructing a local DateTime
      calculatedTime = DateTime(baseDate.year, baseDate.month, baseDate.day)
          .add(Duration(milliseconds: timeOffsetMs));

    } else { // Horizontal orientation (e.g., Timeline View)
      // Use final public fields directly
      final availableWidth = availableSpace.width;
      if (availableWidth <= 0) return viewStart; // Return start if width is invalid

      final clampedRelativeX = relativeX.clamp(0.0, availableWidth);
      final fraction = availableWidth == 0 ? 0.0 : clampedRelativeX / availableWidth; // Avoid division by zero

      final millisecondsOffset = (fraction * totalViewDuration.inMilliseconds).round();
      calculatedTime = viewStart.add(Duration(milliseconds: millisecondsOffset));
    }

    // Final clamping
    if (calculatedTime.isBefore(viewStart)) return viewStart;
    if (calculatedTime.isAfter(viewEnd)) return viewEnd;
    return calculatedTime;
  }


  // Removed reset method

  @override
  List<Object?> get props => [
        viewStart,
        viewEnd,
        origin,
        availableSpace,
        orientation,
        divisions,
        cellWidth,
        cellHeight,
        intervalDuration, // Added to props
      ];

  // Optional: Add stringify for easier debugging if needed
  // @override
  // bool get stringify => true;
}
