import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/enums/enums.dart'; // Import enums


/// Service for packing events to avoid overlaps
class EventPackingService {

  // --- Helper Methods (Moved to top) ---

  /// Packs HORIZONTAL (all-day) events, handling spanning and vertical stacking.
  /// Returns a tuple containing the list of processed layouts and the total number of lanes used.
  ({List<EventLayoutInfo> layouts, int laneCount}) _packHorizontalEvents(
    List<EventLayoutInfo> horizontalLayouts,
    EventRenderStyle style,
    List<DateTime> visibleDates,
    int? maxVisibleAllDayEvents, // Added parameter back
  ) {
    if (horizontalLayouts.isEmpty) return (layouts: [], laneCount: 0);

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
      if (visibleDates.isNotEmpty) {
        final firstVisible = visibleDates.first;
        final lastVisible = visibleDates.last;
        final viewStartDate = DateTime(firstVisible.year, firstVisible.month, firstVisible.day);
        final viewEndDate = DateTime(lastVisible.year, lastVisible.month, lastVisible.day, 23, 59, 59, 999, 999);
        firstSegment.startsBeforeView = firstSegment.event.start.isBefore(viewStartDate);
        firstSegment.endsAfterView = firstSegment.event.end.isAfter(viewEndDate);
      } else {
        firstSegment.startsBeforeView = false;
        firstSegment.endsAfterView = false;
      }
      // Reset indicator flags initially (will be set later if needed)
      firstSegment.hasMoreIndicator = false;
      firstSegment.hiddenEventCount = 0;

      primaryLayouts.add(firstSegment);
    }

    // --- Vertical Stacking Logic for Spanned Events ---
    primaryLayouts.sort((a, b) { // Sort for consistent stacking
      final divisionComparison = a.division.compareTo(b.division);
      if (divisionComparison != 0) return divisionComparison;
      return a.event.start.compareTo(b.event.start);
    });

    final List<List<EventLayoutInfo>> lanes = []; // Lane assignment
    for (final event in primaryLayouts) {
      bool placed = false;
      for (int i = 0; i < lanes.length; i++) {
        bool overlapsInLane = lanes[i].any((existing) {
          final eventStartCol = event.division;
          final eventEndCol = event.division + event.columnSpan - 1;
          final existingStartCol = existing.division;
          final existingEndCol = existing.division + existing.columnSpan - 1;
          return (eventStartCol > existingEndCol || eventEndCol < existingStartCol) == false;
        });
        if (!overlapsInLane) {
          lanes[i].add(event);
          event.laneIndex = i;
          placed = true;
          break;
        }
      }
      if (!placed) {
        lanes.add([event]);
        event.laneIndex = lanes.length - 1;
      }
    }

    // --- Assign Positions and Heights ---
    final double fixedEventHeightPixels = 25.0;
    final double verticalSpacingPixels = style.horizontalSpacing; // Vertical gap

    // Assign pixel-based positions and fixed height for ALL lanes.
    for (int i = 0; i < lanes.length; i++) {
        final laneEvents = lanes[i];
        for (final event in laneEvents) {
            event.secondaryStart = i * (fixedEventHeightPixels + verticalSpacingPixels);
            event.secondarySize = fixedEventHeightPixels; // Always assign full height
        }
    }

    // --- Calculate 'More' Indicators based on maxVisibleAllDayEvents ---
    // This logic is now primarily for the on-event indicator if needed,
    // but the AllDayGrid uses the callback for its button visibility.
    final int maxLanes = maxVisibleAllDayEvents ?? 999; // Use parameter or default

    if (lanes.length > maxLanes && maxLanes > 0) {
        final lastVisibleLaneIndex = maxLanes - 1;
        if (lastVisibleLaneIndex >= 0 && lastVisibleLaneIndex < lanes.length) {
            final Map<int, int> hiddenCountsPerDivision = {};
            // Count events in hidden lanes (lanes >= maxLanes)
            for (int i = maxLanes; i < lanes.length; i++) {
                 if (i < lanes.length) { // Safety check
                     for (final hiddenEvent in lanes[i]) {
                          for (int d = 0; d < hiddenEvent.columnSpan; d++) {
                            final divisionIndex = hiddenEvent.division + d;
                            hiddenCountsPerDivision[divisionIndex] = (hiddenCountsPerDivision[divisionIndex] ?? 0) + 1;
                          }
                     }
                 }
            }

            // Assign indicators
            for (final visibleEvent in lanes[lastVisibleLaneIndex]) {
                 if (visibleEvent.secondarySize > 0) { // Check if actually visible
                     int totalHiddenBelowInSpan = 0;
                     bool indicatorNeeded = false;
                     for (int d = 0; d < visibleEvent.columnSpan; d++) {
                         final divisionIndex = visibleEvent.division + d;
                         if (hiddenCountsPerDivision.containsKey(divisionIndex)) {
                             totalHiddenBelowInSpan += hiddenCountsPerDivision[divisionIndex]!;
                             indicatorNeeded = true;
                         }
                     }
                     if (indicatorNeeded && totalHiddenBelowInSpan > 0) {
                         visibleEvent.hasMoreIndicator = true;
                         visibleEvent.hiddenEventCount = totalHiddenBelowInSpan;
                     }
                 }
            }
        }
    }
    // --- End Indicator Calculation ---

    // Return the primary layouts
    return (layouts: primaryLayouts, laneCount: lanes.length);
  }


  /// Packs VERTICAL events within a single division
  List<EventLayoutInfo> _packEventsInDivision(
    List<EventLayoutInfo> events,
    double minSecondarySize,
    EventRenderStyle style,
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
    final double horizontalSpacingPixels = style.horizontalSpacing;
    final double divisionPixelWidth = events.isNotEmpty ? events.first.cellWidth : 1.0;
    final double horizontalSpacing = divisionPixelWidth > 0 ? horizontalSpacingPixels / divisionPixelWidth : 0;
    final double rightMarginPixels = style.rightMargin;
    final double relativeRightMargin = divisionPixelWidth > 0 ? rightMarginPixels / divisionPixelWidth : 0;
    final availableWidth = 1.0 - relativeRightMargin;
    final laneSize = lanes.isEmpty ? availableWidth : (availableWidth / lanes.length) - (horizontalSpacing * (lanes.length - 1) / lanes.length);

    // Assign secondary position and size to each event
    for (int i = 0; i < lanes.length; i++) {
      for (final event in lanes[i]) {
        if (event.orientation == Axis.vertical) {
          final position = i * (laneSize + horizontalSpacing);
          event.secondaryStart = position;
          event.secondarySize = laneSize;
        } else { // Defensive
          final position = i * (laneSize + horizontalSpacing);
          event.secondaryStart = position;
          event.secondarySize = laneSize;
        }
      }
    }

    // Apply column spanning based on the mode
    final numLanes = lanes.length;
    for (final event in events) {
        if (event.laneIndex < 0) {
           // print("Error: Event ${event.event.id} has no lane index assigned."); // Removed print
           continue;
        }
        int span = 1;
        if (style.spanningMode == EventSpanningMode.strict) {
          for (int j = event.laneIndex + 1; j < numLanes; j++) {
            bool collisionInLaneJ = lanes[j].any((otherEvent) => event.overlapsWith(otherEvent));
            if (!collisionInLaneJ) { span++; } else { break; }
          }
        } else if (style.spanningMode == EventSpanningMode.compact) {
          for (int j = event.laneIndex + 1; j < numLanes; j++) {
            if (j >= lanes.length) break;
            bool collisionWithLaneJEvent = lanes[j].any((otherEvent) => otherEvent.laneIndex == j && event.overlapsWith(otherEvent));
            if (!collisionWithLaneJEvent) { span++; } else { break; }
          }
        }
        event.columnSpan = span;

        if (event.columnSpan > 1) {
          final totalSpanSize = (event.columnSpan * laneSize) + ((event.columnSpan - 1) * horizontalSpacing);
          if (event.orientation == Axis.vertical) {
            event.secondarySize = totalSpanSize;
          } else { // Defensive
            event.secondarySize = totalSpanSize;
          }
        }
      }
    return events;
  }

  /// Checks if an event can be placed in a lane without overlapping
  bool _canPlaceInLane(EventLayoutInfo event, List<EventLayoutInfo> lane) {
    return !lane.any((existing) => event.overlapsWith(existing));
  }

  // --- Main Public Method ---
  List<EventLayoutInfo> packEvents({
    required List<EventLayoutInfo> events,
    required double minSecondarySize,
    required EventRenderStyle style,
    required List<DateTime> visibleDates,
    int? maxVisibleAllDayEvents, // Added parameter back
  }) {
    if (events.isEmpty) return [];
    final List<EventLayoutInfo> packedEvents = [];
    final horizontalEvents = events.where((e) => e.orientation == Axis.horizontal).toList();
    final verticalEvents = events.where((e) => e.orientation == Axis.vertical).toList();

    if (horizontalEvents.isNotEmpty) {
      // Call _packHorizontalEvents which now returns a record
      final horizontalResult = _packHorizontalEvents(
          horizontalEvents, style, visibleDates, maxVisibleAllDayEvents); // Pass parameter correctly
      // Add only the layouts to the final list
      packedEvents.addAll(horizontalResult.layouts);
    }

    if (verticalEvents.isNotEmpty) {
      final Map<int, List<EventLayoutInfo>> verticalEventsByDivision = {};
      for (final event in verticalEvents) {
        if (!verticalEventsByDivision.containsKey(event.division)) {
          verticalEventsByDivision[event.division] = [];
        }
        verticalEventsByDivision[event.division]!.add(event);
      }
      for (final division in verticalEventsByDivision.keys) {
        final divisionEvents = verticalEventsByDivision[division]!;
         divisionEvents.sort((a, b) {
           final startComparison = a.start.compareTo(b.start);
           if (startComparison != 0) return startComparison;
           return b.primarySize.compareTo(a.primarySize);
         });
        // Vertical packing doesn't use maxVisibleAllDayEvents
        final packedDivisionEvents = _packEventsInDivision(divisionEvents, minSecondarySize, style);
        packedEvents.addAll(packedDivisionEvents);
      }
    }
    return packedEvents;
  }
}
