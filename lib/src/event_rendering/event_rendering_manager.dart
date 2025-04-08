import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_service.dart';
import 'package:jazmine_calendar/src/event_rendering/event_packing_service.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart'; // Added import
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // Import for date extensions

/// Manager for coordinating event layout and rendering
class EventRenderingManager {
  // Removed Singleton pattern
  EventRenderingManager(); // Public constructor

  // Services
  final EventLayoutService _layoutService = EventLayoutService();
  final EventPackingService _packingService = EventPackingService();

  // Cache for processed events
  final Map<String, List<EventLayoutInfo>> _processedEventsCache = {};

  /// Process events through the two-pass layout system
  List<EventLayoutInfo> processEvents({
    required List<CalendarEvent> events,
    required double minEventSize,
    required double minSecondarySize,
    required GridLayoutInfo gridInfo,
    int? maxVisibleAllDayEvents, // Added parameter back
  }) {

    // Generate cache key (consider adding maxVisibleAllDayEvents if it affects layout outcome)
    final cacheKey = _generateCacheKey(events, minEventSize, minSecondarySize, gridInfo);

    // Return cached results if available
    if (_processedEventsCache.containsKey(cacheKey)) {
      return _processedEventsCache[cacheKey]!;
    }

    // Skip processing if no events
    if (events.isEmpty) {
      return [];
    }

    // First pass: Measure events
    final layoutInfos = _layoutService.measureEvents(
      events: events,
      gridInfo: gridInfo,
      minEventSize: minEventSize,
    );

    // Second pass: Pack events
    // Approximate visibleDates from gridInfo for packing service
    final List<DateTime> managerVisibleDates = [];
    if (gridInfo.viewStart != null && gridInfo.viewEnd != null) { // Check for null safety
      DateTime currentDate = gridInfo.viewStart!.toLocal();
      final loopEndDate = gridInfo.viewEnd!.toLocal().add(const Duration(microseconds: 1));
      while (currentDate.isBefore(loopEndDate)) {
        managerVisibleDates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    final packedEvents = _packingService.packEvents(
      events: layoutInfos,
      minSecondarySize: minSecondarySize,
      style: const EventRenderStyle(), // Use default style for manager processing
      visibleDates: managerVisibleDates,
      maxVisibleAllDayEvents: maxVisibleAllDayEvents, // Pass down
    );

    // Cache the results
    _processedEventsCache[cacheKey] = packedEvents;

    return packedEvents;
  }

  /// Clear the cache
  void clearCache() {
    _processedEventsCache.clear();
  }

  /// Generate a cache key based on input parameters
  String _generateCacheKey(
    List<CalendarEvent> events,
    double minEventSize,
    double minSecondarySize,
    GridLayoutInfo broker,
    // Consider adding maxVisibleAllDayEvents to key if needed
  ) {
    // Include broker state in the key using the passed instance
    final brokerKey = '${broker.viewStart?.toIso8601String() ?? 'null'}_' // Null safety
        '${broker.viewEnd?.toIso8601String() ?? 'null'}_'
        '${broker.orientation}_'
        '${broker.divisions}_'
        '${broker.origin}_'
        '${broker.availableSpace}';

    // Include event IDs and start/end times in the key
    final eventKey = events
        .map((e) =>
            '${e.id}:${e.start.millisecondsSinceEpoch}:${e.end.millisecondsSinceEpoch}')
        .join(',');

    // Add maxVisibleAllDayEvents to the key if it influences packing result
    // final maxVisibleKey = maxVisibleAllDayEvents?.toString() ?? 'null';
    // return '$brokerKey|$eventKey|$minEventSize|$minSecondarySize|$maxVisibleKey';
    return '$brokerKey|$eventKey|$minEventSize|$minSecondarySize'; // Keep key simpler for now
  }


  /// Fetch and process events from the controller
  Future<List<EventLayoutInfo>> fetchAndProcessEvents({
    required CalendarController controller,
    required double minEventSize,
    required double minSecondarySize,
    required GridLayoutInfo broker,
    int? maxVisibleAllDayEvents, // Add parameter here as well
  }) async {
    // TEMPORARY DEBUG - Remove after debugging
    // print('DEBUG: fetchAndProcessEvents called at ${DateTime.now().toIso8601String()} - Stack trace:\n${StackTrace.current}');

    try {
      // Get events for the visible range using the passed broker
      if (broker.viewStart == null || broker.viewEnd == null) {
         // print("Warning: fetchAndProcessEvents called with null viewStart or viewEnd in broker."); // Removed print
         return [];
      }
      final events = await controller.getEventsForDateRange(
          broker.viewStart!, broker.viewEnd!);

      // Process events, passing the parameter
      final packedEvents = processEvents(
        events: events,
        minEventSize: minEventSize,
        minSecondarySize: minSecondarySize,
        gridInfo: broker,
        maxVisibleAllDayEvents: maxVisibleAllDayEvents, // Pass parameter
      );

      return packedEvents;
    } catch (e, s) {
       // print("Error in fetchAndProcessEvents: $e\n$s"); // Removed print
      return [];
    }
  }
}
