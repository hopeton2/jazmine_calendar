import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/services/time_position_service.dart';
import 'dart:math'; // Import for max/min
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // Import for dayStarts

/// Service for measuring events and determining their primary dimensions
class EventLayoutService {
  /// First pass: Measure events and determine fixed positions
  ///
  /// This calculates the position and size along the primary axis (time axis)
  /// for each event based on its start and end times.
  List<EventLayoutInfo> measureEvents({
    required List<CalendarEvent> events,
    required GridLayoutInfo gridInfo, // Use gridInfo instance
    required double minEventSize,
  }) {
    // No isReady check needed as gridInfo instance implies readiness

    final List<EventLayoutInfo> layoutInfos = [];

    final viewStartDay = gridInfo.viewStart.dayStarts; // Use gridInfo

    for (final event in events) {
      // Determine the range of divisions (days) this event spans within the view
      final firstDayIndex = max<int>(0, event.start.difference(viewStartDay).inDays);
      // Use dayEnds to correctly capture events ending exactly at midnight
      final lastDayIndex = min<int>(gridInfo.divisions - 1,
          event.end.difference(viewStartDay).inDays); // Use gridInfo

      // Iterate through each day the event spans within the view
      for (int division = firstDayIndex; division <= lastDayIndex; division++) {
        // Calculate the start and end of the current division (day) in UTC
        final dayStart = viewStartDay.add(Duration(days: division));
        final dayEnd = dayStart.add(const Duration(days: 1));

        // Determine the actual start time for this segment on this day, clamped by view and day
        DateTime segmentStart =
            event.start.isAfter(dayStart) ? event.start : dayStart;
        segmentStart = segmentStart.isAfter(gridInfo.viewStart)
            ? segmentStart
            : gridInfo.viewStart; // Use gridInfo

        // Determine the actual end time for this segment on this day, clamped by view and day
        DateTime segmentEnd = event.end.isBefore(dayEnd) ? event.end : dayEnd;
        segmentEnd = segmentEnd.isBefore(gridInfo.viewEnd)
            ? segmentEnd
            : gridInfo.viewEnd; // Use gridInfo

        // Ensure start is not after end after clamping, skip if no duration on this day
        if (segmentStart.isAfter(segmentEnd) ||
            segmentStart.isAtSameMomentAs(segmentEnd)) {
          continue;
        }

        // Calculate the duration visible *on this day*
        final visibleDurationOnDay = segmentEnd.difference(segmentStart);

        // Calculate the relative start position for this segment using TimePositionService
        final start = TimePositionService.calculatePositionWithBroker(
          time: segmentStart, // Use the segment's start time
          gridInfo: gridInfo, // Pass gridInfo instance
          scrollOffset: 0.0, // Pass 0 for relative calculation
        );

        // Calculate the size based on the visible duration *on this day*
        final size = TimePositionService.calculateSizeWithBroker(
          duration: visibleDurationOnDay,
          gridInfo: gridInfo, // Pass gridInfo instance
        );

        // Ensure minimum size (consider if this should apply per segment or overall?)
        // Applying per segment for now.
        final effectiveSize = size < minEventSize ? minEventSize : size;

        // Create layout info for this segment
        layoutInfos.add(EventLayoutInfo(
          event: event, // Reference the original event
          orientation: gridInfo.orientation, // Use gridInfo
          division: division, // Assign to the current day's division
          start: start, // Position relative to the day's start (00:00)
          primarySize: effectiveSize, // Height/Width for this segment
          cellWidth: gridInfo.cellWidth, // Use gridInfo
          cellHeight: gridInfo.cellHeight, // Use gridInfo
          // Removed availableSpace parameter
        ));
      }
    }

    return layoutInfos;
  }

  // _getDivisionForEvent is no longer needed.
}
