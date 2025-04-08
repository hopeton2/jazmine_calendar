import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';

// Import for dayStarts

class TimePositionService {
  // Helpers removed as calculations are now based on total space and time fractions

  // Note: Old calculateTimePosition and calculateSizeForDuration methods are removed
  // as they are replaced by the gridInfo versions using the new interval logic.

  /// Calculate the pixel position along the primary axis for a given LOCAL time.
  /// Returns the offset relative to the grid content origin (e.g., origin.dy for vertical).
  static double calculatePosition({
    required DateTime localTime,
    required GridLayoutInfo gridInfo,
  }) {
    if (gridInfo.orientation == Axis.horizontal) {
      // --- Horizontal Logic (Keep original fraction-based approach) ---
      final totalDuration =
          gridInfo.viewEnd.difference(gridInfo.viewStart).inMilliseconds;
      if (totalDuration <= 0 || gridInfo.availableSpace.width <= 0) {
        return gridInfo.origin.dx; // Avoid division by zero
      }
      // Clamp time within view bounds for calculation
      final clampedTime = localTime.isBefore(gridInfo.viewStart)
          ? gridInfo.viewStart
          : (localTime.isAfter(gridInfo.viewEnd)
              ? gridInfo.viewEnd
              : localTime);
      final offset = clampedTime.difference(gridInfo.viewStart).inMilliseconds;
      final timeFraction = (offset / totalDuration).clamp(0.0, 1.0);
      return gridInfo.origin.dx +
          (timeFraction * gridInfo.availableSpace.width);
    } else {
      // --- Vertical Logic (Interval-based) ---
      final intervalMinutes = gridInfo.intervalDuration.inMinutes;
      if (intervalMinutes <= 0 || gridInfo.cellHeight <= 0) {
        return gridInfo.origin.dy; // Avoid division by zero or invalid state
      }

      // Calculate minutes since midnight (assuming day starts at 00:00 for calculation)
      final minutesSinceMidnight = (localTime.hour * 60) +
          localTime.minute +
          (localTime.second / 60.0) +
          (localTime.millisecond / 60000.0);

      // Calculate how many intervals have passed since midnight
      final intervalsSinceMidnight = minutesSinceMidnight / intervalMinutes;

      // Calculate the vertical position relative to the origin
      final relativePosition = intervalsSinceMidnight * gridInfo.cellHeight;

      // Clamp position within the available space height (relative to origin)
      final clampedRelativePosition =
          relativePosition.clamp(0.0, gridInfo.availableSpace.height);

      // Add the origin offset
      return gridInfo.origin.dy + clampedRelativePosition;
    }
  }

  /// Calculate the pixel size along the primary axis for a given duration.
  static double calculateSize({
    required Duration duration,
    required GridLayoutInfo gridInfo,
  }) {
    if (gridInfo.orientation == Axis.horizontal) {
      // --- Horizontal Logic (Keep original fraction-based approach) ---
      final totalDuration =
          gridInfo.viewEnd.difference(gridInfo.viewStart).inMilliseconds;
      if (totalDuration <= 0 || gridInfo.availableSpace.width <= 0) {
        return 0; // Avoid division by zero
      }
      final fraction =
          (duration.inMilliseconds / totalDuration).clamp(0.0, 1.0);
      final size = fraction * gridInfo.availableSpace.width;
      return size < 0 ? 0 : size;
    } else {
      // --- Vertical Logic (Interval-based) ---
      final intervalMinutes = gridInfo.intervalDuration.inMinutes;
      if (intervalMinutes <= 0 || gridInfo.cellHeight <= 0) {
        return 0; // Avoid division by zero or invalid state
      }
      // Calculate how many intervals the duration spans
      final intervalsInDuration = duration.inMinutes / intervalMinutes;
      // Calculate size based on intervals and cell height
      final size = intervalsInDuration * gridInfo.cellHeight;
      // Ensure size is not negative
      return size < 0 ? 0 : size;
    }
  }
  /// Convert a pixel offset (relative to the grid content origin) back to a LOCAL DateTime.
  /// This logic is based on inverting the calculatePosition function.
  static DateTime? positionToTime({
    required Offset position,
    required GridLayoutInfo gridInfo,
  }) {

     
    final totalViewDuration = gridInfo.viewEnd.difference(gridInfo.viewStart);
    if (totalViewDuration.inMilliseconds <= 0) return gridInfo.viewStart; // Return start if duration is invalid

    DateTime calculatedTime;

    if (gridInfo.orientation == Axis.vertical) {
      // --- Vertical Logic (Inverse of interval-based position) ---
      final availableHeight = gridInfo.availableSpace.height;
      final availableWidth = gridInfo.availableSpace.width; // Total width for all divisions
      if (availableHeight <= 0 || availableWidth <= 0 || gridInfo.cellWidth <= 0 || gridInfo.divisions! <= 0 || gridInfo.cellHeight! <= 0 || gridInfo.intervalDuration!.inMilliseconds <= 0) {
         return gridInfo.viewStart; // Return start if grid dimensions are invalid
      }

      // 1. Determine the division (day column index) relative to origin
      final relativeX = position.dx - gridInfo.origin.dx;
      int divisionIndex = (relativeX / gridInfo.cellWidth).floor();
      divisionIndex = divisionIndex.clamp(0, gridInfo.divisions - 1); // Clamp

      // 2. Determine the time offset based on Y position relative to origin
      final relativeY = (position.dy - gridInfo.origin.dy).clamp(0.0, availableHeight); // Clamp Y within bounds

      // Calculate how many intervals fit into the relative Y position
      final intervalsFromTop = relativeY / gridInfo.cellHeight;

      // Calculate the time offset based on the number of intervals and interval duration
      final timeOffsetMs = (intervalsFromTop * gridInfo.intervalDuration.inMilliseconds).round();

      // 3. Calculate the base date for the division
      final baseDate = gridInfo.viewStart.add(Duration(days: divisionIndex));

      // 4. Combine base date and time offset, always constructing a local DateTime
      //    (Assuming baseDate is already local or UTC consistency is handled elsewhere)
      calculatedTime = DateTime(baseDate.year, baseDate.month, baseDate.day)
          .add(Duration(milliseconds: timeOffsetMs));

    } else {
      // --- Horizontal Logic (Inverse of fraction-based position) ---
      final availableWidth = gridInfo.availableSpace.width;
      if (availableWidth <= 0) {
         return gridInfo.viewStart; // Return start if width is invalid
      }

      // Calculate horizontal position relative to origin
      final relativeX = (position.dx - gridInfo.origin.dx).clamp(0.0, availableWidth);

      // Determine the fraction this relative position represents
      final fraction = relativeX / availableWidth;

      // Calculate the time duration corresponding to this fraction
      final millisecondsOffset = (fraction * totalViewDuration.inMilliseconds).round();
      calculatedTime = gridInfo.viewStart.add(Duration(milliseconds: millisecondsOffset));
    }

    // Final clamping within the overall view bounds
    if (calculatedTime.isBefore(gridInfo.viewStart)) return gridInfo.viewStart;
    if (calculatedTime.isAfter(gridInfo.viewEnd)) return gridInfo.viewEnd;
    return calculatedTime;
  }
} // End TimePositionService class
