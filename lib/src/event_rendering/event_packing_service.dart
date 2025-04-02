import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';

/// Service for packing events to avoid overlaps
class EventPackingService {
  /// Second pass: Pack events to avoid overlaps
  ///
  /// This determines the position and size along the secondary axis
  /// (perpendicular to the time axis) for each event.
  List<EventLayoutInfo> packEvents({
    required List<EventLayoutInfo> events,
    required double minSecondarySize,
  }) {
    if (events.isEmpty) return [];

    // Group events by division
    final Map<int, List<EventLayoutInfo>> eventsByDivision = {};
    for (final event in events) {
      if (!eventsByDivision.containsKey(event.division)) {
        eventsByDivision[event.division] = [];
      }
      eventsByDivision[event.division]!.add(event);
    }

    // Pack events within each division
    final List<EventLayoutInfo> packedEvents = [];

    for (final division in eventsByDivision.keys) {
      final divisionEvents = eventsByDivision[division]!;

      // Sort events by start time, then by duration (longer events first)
      divisionEvents.sort((a, b) {
        final startComparison = a.start.compareTo(b.start);
        if (startComparison != 0) return startComparison;

        // If start times are equal, sort by duration (longer events first)
        return b.primarySize.compareTo(a.primarySize);
      });

      // Pack events within this division
      final packedDivisionEvents = _packEventsInDivision(
        divisionEvents,
        minSecondarySize,
      );

      packedEvents.addAll(packedDivisionEvents);
    }

    return packedEvents;
  }

  /// Packs events within a single division
  List<EventLayoutInfo> _packEventsInDivision(
    List<EventLayoutInfo> events,
    double minSecondarySize,
  ) {
    // Track lanes of events
    final List<List<EventLayoutInfo>> lanes = [];

    for (final event in events) {
      // Find a lane where this event doesn't overlap with existing events
      bool placed = false;
      for (int i = 0; i < lanes.length; i++) {
        if (_canPlaceInLane(event, lanes[i])) {
          lanes[i].add(event);
          placed = true;
          break;
        }
      }

      // If no suitable lane found, create a new one
      if (!placed) {
        lanes.add([event]);
      }
    }

    // Calculate secondary dimension size based on number of lanes
    // We use a relative size (0.0 to 1.0) that will be scaled by the container later
    // Add spacing between events and ensure a 10-pixel margin at the end

    // Constants for spacing between events
    const double horizontalSpacingPixels =
        3.0; // 3-pixel spacing between events

    // Note: The 10-pixel right margin for the container is handled at the container level,
    // not in the packing service. We're only concerned with spacing between events here.

    // Convert pixel values to relative values (will be converted back in the renderer)
    // We'll use a reference width of 300 pixels for the conversion
    const double referenceWidth = 300.0;
    final double horizontalSpacing = horizontalSpacingPixels / referenceWidth;

    // Use the full available width (the container margin is handled elsewhere)
    final availableWidth = 1.0;

    // Calculate lane size with spacing
    final laneSize = (availableWidth / lanes.length) -
        (horizontalSpacing * (lanes.length - 1) / lanes.length);

    // Assign secondary position and size to each event
    for (int i = 0; i < lanes.length; i++) {
      for (final event in lanes[i]) {
        if (event.orientation == Axis.vertical) {
          // For vertical orientation: left and width
          // Calculate position with spacing
          final position = i * (laneSize + horizontalSpacing);

          // Set position and size
          event.secondaryStart = position;
          event.secondarySize = laneSize;
        } else {
          // For horizontal orientation: top and height
          // Calculate position with spacing
          final position = i * (laneSize + horizontalSpacing);

          // Set position and size
          event.secondaryStart = position;
          event.secondarySize = laneSize;
        }
      }
    }

    // Flatten and return
    return lanes.expand((lane) => lane).toList();
  }

  /// Checks if an event can be placed in a lane without overlapping
  bool _canPlaceInLane(EventLayoutInfo event, List<EventLayoutInfo> lane) {
    return !lane.any((existing) => event.overlapsWith(existing));
  }
}
