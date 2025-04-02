import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_broker.dart';

/// Service for calculating time positions in the calendar grid
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // Import for dayStarts

class TimePositionService {
  // Helper to get interval size in pixels
  static double _getIntervalPixels(GridLayoutBroker broker) {
    // CellHeight/Width already represent the size of a 60-minute interval in the broker setup
    return broker.orientation == Axis.vertical
        ? broker.cellHeight
        : broker.cellWidth;
  }

  // Helper to get interval duration (assuming 60 mins based on broker cell setup)
  static const Duration _intervalDuration = Duration(minutes: 60);

  // Note: Old calculateTimePosition and calculateSizeForDuration methods are removed
  // as they are replaced by the broker versions using the new interval logic.

  /// Calculate position using the GridLayoutBroker
  /// Calculate position using the GridLayoutBroker based on intervals
  static double calculatePositionWithBroker({
    required DateTime time,
    required GridLayoutBroker broker,
    double? scrollOffset, // Keep scrollOffset for EventRenderer
  }) {
    if (!broker.isReady) {
      throw StateError('Grid layout information is not available');
    }

    // Convert the event time (which is likely UTC) to local time
    final localTime = time.toLocal();

    // Calculate minutes since midnight using the local time's hour and minute components
    // This aligns with how CurrentTimeIndicator calculates its position relative to visual time slots
    final minutesSinceMidnight = (localTime.hour * 60) + localTime.minute;

    // No clamping needed here as we are using hour/minute components (0-23, 0-59)
    final clampedMinutes = minutesSinceMidnight;

    // Calculate position based on intervals
    final intervalPixels = _getIntervalPixels(broker);
    // Ensure we don't divide by zero if interval is zero
    final position = _intervalDuration.inMinutes == 0
        ? 0.0
        : (clampedMinutes / _intervalDuration.inMinutes) * intervalPixels;
    // Removed debug print

    // Adjust for scroll offset if provided (used by EventRenderer)
    // The final position is relative to the EventLayoutSurface's top-left (0,0)
    final finalPosition =
        scrollOffset != null ? position - scrollOffset : position;

    return finalPosition;
  }

  /// Calculate size using the GridLayoutBroker based on intervals
  static double calculateSizeWithBroker({
    required Duration duration,
    required GridLayoutBroker broker,
  }) {
    if (!broker.isReady) {
      throw StateError('Grid layout information is not available');
    }
    final intervalPixels = _getIntervalPixels(broker);
    // Ensure we don't divide by zero if interval is zero
    final size = _intervalDuration.inMinutes == 0
        ? 0.0
        : (duration.inMinutes / _intervalDuration.inMinutes) * intervalPixels;

    // Ensure size is not negative
    return size < 0 ? 0 : size;
  } // End calculateSizeWithBroker
} // End TimePositionService class
