import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_service.dart';
import 'package:jazmine_calendar/src/event_rendering/event_packing_service.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_broker.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

/// Manager for coordinating event layout and rendering
class EventRenderingManager {
  // Singleton pattern
  static final EventRenderingManager _instance =
      EventRenderingManager._internal();
  factory EventRenderingManager() => _instance;
  EventRenderingManager._internal();

  // Services
  final EventLayoutService _layoutService = EventLayoutService();
  final EventPackingService _packingService = EventPackingService();
  final GridLayoutBroker _broker = GridLayoutBroker();

  // Cache for processed events
  final Map<String, List<EventLayoutInfo>> _processedEventsCache = {};

  /// Process events through the two-pass layout system
  List<EventLayoutInfo> processEvents({
    required List<CalendarEvent> events,
    required double minEventSize,
    required double minSecondarySize,
  }) {
    if (!_broker.isReady) {
      throw StateError('Grid layout information is not available');
    }

    // Generate cache key
    final cacheKey = _generateCacheKey(events, minEventSize, minSecondarySize);

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
      broker: _broker,
      minEventSize: minEventSize,
    );

    // Second pass: Pack events
    final packedEvents = _packingService.packEvents(
      events: layoutInfos,
      minSecondarySize: minSecondarySize,
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
  ) {
    // Include broker state in the key
    final brokerKey = '${_broker.viewStart.toIso8601String()}_'
        '${_broker.viewEnd.toIso8601String()}_'
        '${_broker.orientation}_'
        '${_broker.divisions}_'
        '${_broker.origin}_'
        '${_broker.availableSpace}';

    // Include event IDs and start/end times in the key
    final eventKey = events
        .map((e) =>
            '${e.id}:${e.start.millisecondsSinceEpoch}:${e.end.millisecondsSinceEpoch}')
        .join(',');

    return '$brokerKey|$eventKey|$minEventSize|$minSecondarySize';
  }

  /// Check if the broker is ready
  bool get isBrokerReady => _broker.isReady;

  /// Get the current broker state
  GridLayoutBroker get broker => _broker;

  /// Fetch and process events from the controller
  Future<List<EventLayoutInfo>> fetchAndProcessEvents({
    required CalendarController controller,
    required double minEventSize,
    required double minSecondarySize,
  }) async {
    // TEMPORARY DEBUG - Remove after debugging
    print(
        'DEBUG: fetchAndProcessEvents called at ${DateTime.now().toIso8601String()} - Stack trace:\n${StackTrace.current}');
    if (!_broker.isReady) {
      return [];
    }

    try {
      // Get events for the visible range
      final events = await controller.getEventsForDateRange(
          _broker.viewStart, _broker.viewEnd);

      // Process events
      final packedEvents = processEvents(
        events: events,
        minEventSize: minEventSize,
        minSecondarySize: minSecondarySize,
      );

      return packedEvents;
    } catch (e) {
      return [];
    }
  }
}
