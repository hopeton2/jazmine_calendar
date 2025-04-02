import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_broker.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/services/time_position_service.dart';

/// Service for measuring events and determining their primary dimensions
class EventLayoutService {
  /// First pass: Measure events and determine fixed positions
  ///
  /// This calculates the position and size along the primary axis (time axis)
  /// for each event based on its start and end times.
  List<EventLayoutInfo> measureEvents({
    required List<CalendarEvent> events,
    required GridLayoutBroker broker,
    required double minEventSize,
  }) {
    if (!broker.isReady) {
      throw StateError('Grid layout information is not available');
    }

    final List<EventLayoutInfo> layoutInfos = [];

    for (final event in events) {
      // Determine which division (column/row) this event belongs to
      final division = _getDivisionForEvent(event, broker);

      // Clamp event times to visible range for accurate duration calculation within view
      final clampedStart = event.start.isBefore(broker.viewStart)
          ? broker.viewStart
          : event.start;
      final clampedEnd =
          event.end.isAfter(broker.viewEnd) ? broker.viewEnd : event.end;

      // Calculate the actual duration visible within the view
      final visibleDuration = clampedEnd.difference(clampedStart);

      // Calculate the absolute start position using TimePositionService
      // IMPORTANT: Do NOT pass scrollOffset here, as EventRenderer handles it.
      final start = TimePositionService.calculatePositionWithBroker(
        time: clampedStart, // Use the clamped start time for position
        broker: broker,
        scrollOffset:
            0.0, // Explicitly pass 0.0, though service ignores it for relative calc
      );

      // Calculate the size based on the visible duration
      final size = TimePositionService.calculateSizeWithBroker(
        duration: visibleDuration,
        broker: broker,
      );

      // Ensure minimum size
      final effectiveSize = size < minEventSize ? minEventSize : size;

      // Create layout info, passing cell dimensions from the broker
      layoutInfos.add(EventLayoutInfo(
        event: event,
        orientation: broker.orientation,
        division: division,
        start: start,
        primarySize: effectiveSize,
        cellWidth: broker.cellWidth,
        cellHeight: broker.cellHeight,
        availableSpace: broker.availableSpace,
      ));
    }

    return layoutInfos;
  }

  /// Determines which division (column/row) an event belongs to
  int _getDivisionForEvent(CalendarEvent event, GridLayoutBroker broker) {
    // For day/week view, determine which day the event belongs to
    for (int i = 0; i < broker.divisions; i++) {
      final dayStart = broker.viewStart.add(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));

      if (event.start.isAfter(dayStart) && event.start.isBefore(dayEnd)) {
        return i;
      }
    }

    // If no match found, use the first division
    // This can happen for events that start before the view range
    return 0;
  }
}
