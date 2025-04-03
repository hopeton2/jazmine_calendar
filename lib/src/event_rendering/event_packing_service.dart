import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/enums/enums.dart'; // Import enums
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // Import for startOfDay/endOfDay
import 'dart:math'; // Import for max function

/// Service for packing events to avoid overlaps
class EventPackingService {

  // --- Helper Methods (Moved to top) ---

  /// Packs HORIZONTAL (all-day) events, handling spanning and vertical stacking.
  List<EventLayoutInfo> _packHorizontalEvents(
    List<EventLayoutInfo> horizontalLayouts,
    EventRenderStyle style,
    List<DateTime> visibleDates, // Added visibleDates
  ) {
    if (horizontalLayouts.isEmpty) return [];

    // Group layouts by original event ID
    final Map<String, List<EventLayoutInfo>> layoutsByEventId = {};
    for (final layout in horizontalLayouts) {
      final eventId = layout.event.id;
      if (!layoutsByEventId.containsKey(eventId)) {
        layoutsByEventId[eventId] = [];
      }
      layoutsByEventId[eventId]!.add(layout);
    }

    // Create primary layout info for each event, calculating span
    final List<EventLayoutInfo> primaryLayouts = [];
    for (final eventId in layoutsByEventId.keys) {
      final segments = layoutsByEventId[eventId]!;
      segments.sort((a, b) => a.division.compareTo(b.division)); // Sort by division index

      final firstSegment = segments.first;
      final lastSegment = segments.last;
      final columnSpan = lastSegment.division - firstSegment.division + 1;

      // Use the first segment as the base, update its span and edge flags
      firstSegment.columnSpan = columnSpan;

      // Calculate edge flags using visibleDates
      // Ensure visibleDates is not empty before accessing
      if (visibleDates.isNotEmpty) {
        // Use helper extensions for start/end of day for robust comparison
        final firstVisible = visibleDates.first;
        final lastVisible = visibleDates.last;
        final viewStartDate = DateTime(firstVisible.year, firstVisible.month, firstVisible.day);
        final viewEndDate = DateTime(lastVisible.year, lastVisible.month, lastVisible.day, 23, 59, 59, 999, 999);
        firstSegment.startsBeforeView = firstSegment.event.start.isBefore(viewStartDate);
        firstSegment.endsAfterView = firstSegment.event.end.isAfter(viewEndDate);
      } else {
        // Default if visibleDates is empty (should ideally not happen)
        firstSegment.startsBeforeView = false;
        firstSegment.endsAfterView = false;
      }

      primaryLayouts.add(firstSegment);
    }

    // --- Vertical Stacking Logic for Spanned Events ---

    // Sort primary layouts for consistent stacking order (e.g., by start division, then event start time)
    primaryLayouts.sort((a, b) {
      final divisionComparison = a.division.compareTo(b.division);
      if (divisionComparison != 0) return divisionComparison;
      return a.event.start.compareTo(b.event.start);
    });

    // Lane assignment (similar to vertical packing, but assigning rows)
    final List<List<EventLayoutInfo>> lanes = []; // Each inner list represents a horizontal row
    for (final event in primaryLayouts) {
      bool placed = false;
      for (int i = 0; i < lanes.length; i++) {
        // Check for horizontal overlap within the lane, considering column spans
        bool overlapsInLane = lanes[i].any((existing) {
          final eventStartCol = event.division;
          final eventEndCol = event.division + event.columnSpan - 1;
          final existingStartCol = existing.division;
          final existingEndCol = existing.division + existing.columnSpan - 1;
          // Check for overlap: max(start1, start2) <= min(end1, end2)
          return (eventStartCol > existingEndCol || eventEndCol < existingStartCol) == false;
        });

        if (!overlapsInLane) {
          lanes[i].add(event);
          event.laneIndex = i; // Store the row index
          placed = true;
          break;
        }
      }
      if (!placed) {
        lanes.add([event]);
        event.laneIndex = lanes.length - 1; // New row index
      }
    }

    // Calculate vertical position (secondaryStart) and height (secondarySize) in PIXELS
    final double fixedEventHeightPixels = 25.0;
    final double verticalSpacingPixels = style.horizontalSpacing; // Vertical gap between events

    // Assign pixel-based positions and fixed height for all lanes.
    // Clipping based on available height (minus reserved space) will be handled
    // by the ClipRect in the UI layer (CalendarGrid).
    for (final lane in lanes) {
      for (final event in lane) {
        // secondaryStart is the top pixel offset from the container top
        event.secondaryStart = event.laneIndex * (fixedEventHeightPixels + verticalSpacingPixels);
        // secondarySize is the fixed pixel height
        event.secondarySize = fixedEventHeightPixels;
      }
    }

    return primaryLayouts; // Return the processed list with spans and vertical positions
  }

  /// Packs VERTICAL events within a single division
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
         // Assign lane index for the new lane
         event.laneIndex = lanes.length - 1;
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
    final double divisionPixelWidth = events.isNotEmpty
        ? events.first.cellWidth
        : 1.0; // Use cellWidth as proxy
    final double horizontalSpacing = divisionPixelWidth > 0
        ? horizontalSpacingPixels / divisionPixelWidth
        : 0;

    // Calculate relative right margin
    final double rightMarginPixels = style.rightMargin;
    final double relativeRightMargin =
        divisionPixelWidth > 0 ? rightMarginPixels / divisionPixelWidth : 0;

    // Adjust available width to account for the right margin
    final availableWidth = 1.0 - relativeRightMargin;

    // Calculate lane size with spacing
    // Calculate lane size based on the adjusted available width and spacing
    final laneSize = lanes.isEmpty
        ? availableWidth
        : // Avoid division by zero if no lanes
        (availableWidth / lanes.length) -
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
          // For horizontal orientation: top and height (Should not happen here, but defensive)
          final position = i * (laneSize + horizontalSpacing);
          event.secondaryStart = position;
          event.secondarySize = laneSize;
        }
      }
    }

    // Calculate initial secondary dimensions (before potential spanning)
    // This loop seems redundant now as position/size is set above. Removing.
    // for (int i = 0; i < lanes.length; i++) { ... }

    // Apply column spanning based on the mode
    final numLanes = lanes.length;
    for (final event in events) {
        // Ensure laneIndex is assigned (should be done above)
        if (event.laneIndex < 0) {
           print("Error: Event ${event.event.id} has no lane index assigned.");
           continue; // Skip spanning calculation if lane is unknown
        }
        int span = 1;
        if (style.spanningMode == EventSpanningMode.strict) {
          // Strict: Span only if the entire column is free
          for (int j = event.laneIndex + 1; j < numLanes; j++) {
            bool collisionInLaneJ =
                lanes[j].any((otherEvent) => event.overlapsWith(otherEvent));
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
            // Ensure lane j exists before accessing it
            if (j >= lanes.length) break;
            bool collisionWithLaneJEvent = lanes[j].any((otherEvent) =>
                otherEvent.laneIndex == j && event.overlapsWith(otherEvent));
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
          final totalSpanSize = (event.columnSpan * laneSize) +
              ((event.columnSpan - 1) * horizontalSpacing);
          if (event.orientation == Axis.vertical) {
            event.secondarySize = totalSpanSize;
          } else {
             // Should not happen here
            event.secondarySize = totalSpanSize;
          }
        }
        // secondaryStart remains based on the initial laneIndex calculation above
      } // End of for loop (spanning calculation)
    // Return the modified events list directly
    return events;
  } // End of _packEventsInDivision

  /// Checks if an event can be placed in a lane without overlapping
  bool _canPlaceInLane(EventLayoutInfo event, List<EventLayoutInfo> lane) {
    return !lane.any((existing) => event.overlapsWith(existing));
  }

  // --- Main Public Method ---

  /// Second pass: Pack events to avoid overlaps
  ///
  /// This determines the position and size along the secondary axis
  /// (perpendicular to the time axis) for each event.
  List<EventLayoutInfo> packEvents({
    required List<EventLayoutInfo> events,
    required double minSecondarySize,
    required EventRenderStyle style,
    required List<DateTime> visibleDates, // Added visibleDates
  }) {
    if (events.isEmpty) return [];

    // Pack events within each division
    final List<EventLayoutInfo> packedEvents = [];

    // --- Packing Logic ---
    // Separate processing for horizontal (all-day) and vertical (timed) events

    // 1. Filter events by orientation
    // Note: We process *all* measured events passed in, not grouped by division initially
    final horizontalEvents = events.where((e) => e.orientation == Axis.horizontal).toList();
    final verticalEvents = events.where((e) => e.orientation == Axis.vertical).toList();

    // 2. Process Horizontal (All-Day) Events - Spanning and Stacking
    if (horizontalEvents.isNotEmpty) {
      final packedHorizontal = _packHorizontalEvents(horizontalEvents, style, visibleDates); // Pass visibleDates
      packedEvents.addAll(packedHorizontal);
    }

    // 3. Process Vertical (Timed) Events - Group by division and pack
    if (verticalEvents.isNotEmpty) {
      // Group vertical events by division
      final Map<int, List<EventLayoutInfo>> verticalEventsByDivision = {};
      for (final event in verticalEvents) {
        if (!verticalEventsByDivision.containsKey(event.division)) {
          verticalEventsByDivision[event.division] = [];
        }
        verticalEventsByDivision[event.division]!.add(event);
      }

      // Pack vertical events within each division
      for (final division in verticalEventsByDivision.keys) {
        final divisionEvents = verticalEventsByDivision[division]!;
        // Sort vertical events (important for packing algorithm)
         divisionEvents.sort((a, b) {
           final startComparison = a.start.compareTo(b.start);
           if (startComparison != 0) return startComparison;
           return b.primarySize.compareTo(a.primarySize); // Longer first if start is same
         });

        final packedDivisionEvents = _packEventsInDivision(
          divisionEvents,
          minSecondarySize,
          style,
        );
        packedEvents.addAll(packedDivisionEvents);
      }
    }
    // Return the final combined list of packed events
    return packedEvents;
  }

  // Helper methods are now defined above packEvents
// Removed extra closing brace that was here
  // Helper methods are now defined above packEvents
} // Closing brace for EventPackingService class
