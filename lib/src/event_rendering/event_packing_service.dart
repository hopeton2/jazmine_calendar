import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/enums/enums.dart'; // Import enums

/// Service for packing events to avoid overlaps
class EventPackingService {
  /// Second pass: Pack events to avoid overlaps
  ///
  /// This determines the position and size along the secondary axis
  /// (perpendicular to the time axis) for each event.
  List<EventLayoutInfo> packEvents({
    required List<EventLayoutInfo> events,
    required double minSecondarySize,
    required EventRenderStyle style, // Add style parameter
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

      // Check orientation of the first event (all should be the same within a division)
      if (divisionEvents.isNotEmpty &&
          divisionEvents.first.orientation == Axis.horizontal) {
        // --- Horizontal (All-Day) Stacking Logic ---
        // Simple stacking: assign vertical position based on index
        // TODO: Implement proper overlap detection for vertical stacking if needed
        final double fixedRelativeHeight = 0.25; // Example: Allow up to 4 stacked events visible
        for (int i = 0; i < divisionEvents.length; i++) {
          final event = divisionEvents[i];
          event.secondaryStart = i * fixedRelativeHeight;
          event.secondarySize = fixedRelativeHeight;
          event.columnSpan = 1; // No horizontal spanning for all-day
          event.laneIndex = i; // Use index as lane/row index
        }
        packedEvents.addAll(divisionEvents); // Add the modified events
      } else if (divisionEvents.isNotEmpty) {
        // --- Vertical (Timed) Packing Logic ---
        final packedDivisionEvents = _packEventsInDivision(
          divisionEvents,
          minSecondarySize,
          style, // Pass style
        );
        packedEvents.addAll(packedDivisionEvents);
      }
      // Else (divisionEvents is empty): do nothing
    }

    return packedEvents;
  }

  /// Packs events within a single division
  List<EventLayoutInfo> _packEventsInDivision(
    List<EventLayoutInfo> events,
    double minSecondarySize,
    EventRenderStyle style, // Add style parameter
  ) {
    // Track lanes of events
    final List<List<EventLayoutInfo>> lanes = [];

    for (final event in events) {
      // Find a lane where this event doesn't overlap with existing events
      bool placed = false;
      for (int i = 0; i < lanes.length; i++) {
        if (_canPlaceInLane(event, lanes[i])) {
          lanes[i].add(event);
          event.laneIndex = i; // Store the initial lane index
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

    // Get spacing from style (it's already in pixels)
    final double horizontalSpacingPixels = style.horizontalSpacing;

    // Convert pixel spacing to relative value based on available width
    // Assuming the '1.0' availableWidth represents the full width of the division
    // We need the actual pixel width of the division to do this conversion accurately.
    // Let's use the cellWidth from the first event as an approximation for now.
    // TODO: Find a better way to get the division's total pixel width if needed.
    final double divisionPixelWidth = events.isNotEmpty ? events.first.cellWidth : 1.0; // Use cellWidth as proxy
    final double horizontalSpacing = divisionPixelWidth > 0 ? horizontalSpacingPixels / divisionPixelWidth : 0;

    // Calculate relative right margin
    final double rightMarginPixels = style.rightMargin;
    final double relativeRightMargin = divisionPixelWidth > 0 ? rightMarginPixels / divisionPixelWidth : 0;

    // Adjust available width to account for the right margin
    final availableWidth = 1.0 - relativeRightMargin;

    // Calculate lane size with spacing
    // Calculate lane size based on the adjusted available width and spacing
    final laneSize = lanes.isEmpty ? availableWidth : // Avoid division by zero if no lanes
        (availableWidth / lanes.length) - (horizontalSpacing * (lanes.length - 1) / lanes.length);

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

    // Calculate initial secondary dimensions (before potential spanning)
    for (int i = 0; i < lanes.length; i++) {
      for (final event in lanes[i]) {
         event.laneIndex = i; // Store initial lane index
         final startPosition = i * (laneSize + horizontalSpacing);
         if (event.orientation == Axis.vertical) {
           event.secondaryStart = startPosition;
           event.secondarySize = laneSize;
         } else {
           event.secondaryStart = startPosition;
           event.secondarySize = laneSize;
         }
      }
    }

    // Conditionally apply column spanning based on the mode
    if (style.spanningMode != null) { // Check if spanningMode is set
      final numLanes = lanes.length;
      for (final event in events) {
        int span = 1;
        if (style.spanningMode == EventSpanningMode.strict) {
          // Strict: Span only if the entire column is free
          for (int j = event.laneIndex + 1; j < numLanes; j++) {
            bool collisionInLaneJ = lanes[j].any((otherEvent) => event.overlapsWith(otherEvent));
            if (!collisionInLaneJ) {
              span++;
            } else {
              break;
            }
          }
        } else if (style.spanningMode == EventSpanningMode.compact) {
          // Compact: Span if the specific event doesn't collide in the next column
          // Check against events originally placed in the target lane 'j'
           for (int j = event.laneIndex + 1; j < numLanes; j++) {
             bool collisionWithLaneJEvent = lanes[j].any((otherEvent) => otherEvent.laneIndex == j && event.overlapsWith(otherEvent));
             if (!collisionWithLaneJEvent) {
                span++;
             } else {
                break;
             }
           }
        }
        event.columnSpan = span;

        // Recalculate secondarySize based on span if span > 1
        if (event.columnSpan > 1) {
          final totalSpanSize = (event.columnSpan * laneSize) + ((event.columnSpan - 1) * horizontalSpacing);
          if (event.orientation == Axis.vertical) {
            event.secondarySize = totalSpanSize;
          } else {
            event.secondarySize = totalSpanSize;
          }
        }
        // secondaryStart remains based on the initial laneIndex calculation above
      }
    }


    // Flatten and return (already done by iterating through 'events')
    // return lanes.expand((lane) => lane).toList();
    return events; // Return the modified events list directly
  }

  /// Checks if an event can be placed in a lane without overlapping
  bool _canPlaceInLane(EventLayoutInfo event, List<EventLayoutInfo> lane) {
    return !lane.any((existing) => event.overlapsWith(existing));
  }
}
