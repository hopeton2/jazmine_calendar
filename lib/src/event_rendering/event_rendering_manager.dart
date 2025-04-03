import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_service.dart';
import 'package:jazmine_calendar/src/event_rendering/event_packing_service.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart'; // Added import

/// Manager for coordinating event layout and rendering
class EventRenderingManager {
  // Removed Singleton pattern
  EventRenderingManager(); // Public constructor

  // Services
  final EventLayoutService _layoutService = EventLayoutService();
  final EventPackingService _packingService = EventPackingService();
  // Removed singleton broker field reference

  // Cache for processed events
  final Map<String, List<EventLayoutInfo>> _processedEventsCache = {};

  /// Process events through the two-pass layout system
  List<EventLayoutInfo> processEvents({
    required List<CalendarEvent> events,
    required double minEventSize,
    required double minSecondarySize,
    required GridLayoutInfo gridInfo, // Renamed class
  }) {
    // No isReady check needed

    // Generate cache key
    final cacheKey = _generateCacheKey(events, minEventSize, minSecondarySize,
        gridInfo); // Pass broker to cache key

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
      gridInfo: gridInfo, // Pass the broker instance received as parameter
      minEventSize: minEventSize,
    );

    // Second pass: Pack events
    // Pass a default style for now. TODO: Refactor if specific style needed here.
    // Approximate visibleDates from gridInfo for packing service
    final List<DateTime> managerVisibleDates = [];
    // Removed isReady check, assume gridInfo is valid here
    DateTime currentDate = gridInfo.viewStart.toLocal(); // Assuming gridInfo dates are UTC
    // Ensure viewEnd is included if it's exactly the end date
    final loopEndDate = gridInfo.viewEnd.toLocal().add(const Duration(microseconds: 1));
    while (currentDate.isBefore(loopEndDate)) {
      managerVisibleDates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    final packedEvents = _packingService.packEvents(
      events: layoutInfos,
      minSecondarySize: minSecondarySize,
      style: const EventRenderStyle(), // Keep default style for now
      visibleDates: managerVisibleDates, // Pass approximated visibleDates
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
    GridLayoutInfo broker, // Renamed class
  ) {
    // Include broker state in the key using the passed instance
    final brokerKey = '${broker.viewStart.toIso8601String()}_'
        '${broker.viewEnd.toIso8601String()}_'
        '${broker.orientation}_'
        '${broker.divisions}_'
        '${broker.origin}_'
        '${broker.availableSpace}';

    // Include event IDs and start/end times in the key
    final eventKey = events
        .map((e) =>
            '${e.id}:${e.start.millisecondsSinceEpoch}:${e.end.millisecondsSinceEpoch}')
        .join(',');

    return '$brokerKey|$eventKey|$minEventSize|$minSecondarySize';
  }

  // Removed broker related getters

  /// Fetch and process events from the controller
  Future<List<EventLayoutInfo>> fetchAndProcessEvents({
    required CalendarController controller,
    required double minEventSize,
    required double minSecondarySize,
    required GridLayoutInfo broker, // Renamed class
  }) async {
    // TEMPORARY DEBUG - Remove after debugging
    print(
        'DEBUG: fetchAndProcessEvents called at ${DateTime.now().toIso8601String()} - Stack trace:\n${StackTrace.current}');
    // No isReady check needed

    try {
      // Get events for the visible range using the passed broker
      final events = await controller.getEventsForDateRange(
          broker.viewStart, broker.viewEnd);

      // Process events
      final packedEvents = processEvents(
        events: events,
        minEventSize: minEventSize,
        minSecondarySize: minSecondarySize,
        gridInfo: broker, // Pass broker instance
      );

      return packedEvents;
    } catch (e) {
      return [];
    }
  }
}
