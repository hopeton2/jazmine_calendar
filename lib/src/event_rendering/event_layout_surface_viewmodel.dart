import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_service.dart';
import 'package:jazmine_calendar/src/event_rendering/event_packing_service.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_broker.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // Added import

/// ViewModel for the EventLayoutSurface
/// Handles the business logic for event rendering and interaction
class EventLayoutSurfaceViewModel extends ChangeNotifier {
  /// Calendar controller
  final CalendarController controller;

  /// Services for event layout and packing
  final EventLayoutService _layoutService = EventLayoutService();
  final EventPackingService _packingService = EventPackingService();

  /// Get the broker singleton
  GridLayoutBroker get _broker => GridLayoutBroker();

  /// Minimum event size
  final double minEventSize;

  /// Minimum secondary size
  final double minSecondarySize;

  /// List of processed events
  List<EventLayoutInfo> _events = [];

  /// Loading state
  bool _isLoading = false;

  /// Selected event ID
  String? _selectedEventId;

  /// Dragged event ID
  String? _draggedEventId;

  /// Resized event ID
  String? _resizedEventId;

  /// Active resize handle
  ResizeHandle? _activeResizeHandle;

  /// Drag offset
  Offset? _dragOffset;

  /// Original event (for drag/resize)
  CalendarEvent? _originalEvent;

  /// Original start time (for drag/resize)
  DateTime? _originalStart;

  /// Original end time (for drag/resize)
  DateTime? _originalEnd;

  /// Constructor
  EventLayoutSurfaceViewModel({
    required this.controller,
    this.minEventSize = 20.0,
    this.minSecondarySize = 20.0,
  }) {
    // Listen for controller updates
    controller.addListener(_handleControllerUpdate);

    // Create mock events and process them asynchronously
    Future.microtask(() => createMockEvents());
  }

  /// Dispose resources
  @override
  void dispose() {
    controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  /// Handle controller updates - not used with mock events
  void _handleControllerUpdate() {
    // We're using mock events, so we don't need to respond to controller updates
  }

  /// Create mock events and process them
  Future<void> createMockEvents() async {
    // Set loading state
    _isLoading = true;
    notifyListeners();

    // Wait for the broker to be ready
    await _waitForBroker();

    try {
      // Create mock events
      // Use UTC for consistency across platforms
      // Use the actual viewStart from the broker to ensure mock event is in range
      if (!_broker.isReady) {
        await _waitForBroker(); // Ensure broker is ready before accessing viewStart
      }
      final viewStartDate = _broker.viewStart.dayStarts; // Get the start date of the view (UTC)

      // Create mock events
      final mockEvents = [
        CalendarEvent(
          id: '1',
          title: 'Test Event (5 AM - 9 AM UTC)',
          start: viewStartDate.add(const Duration(hours: 5)), // 5:00 UTC
          end: viewStartDate.add(const Duration(hours: 9)),   // 9:00 UTC
          color: Colors.red,
        ),
        // Add second event: 11:00 UTC for 2.5 hours
        CalendarEvent(
          id: '2',
          title: 'Test Event 2 (11 AM - 1:30 PM UTC)',
          start: viewStartDate.add(const Duration(hours: 11)), // 11:00 UTC
          end: viewStartDate.add(const Duration(hours: 13, minutes: 30)), // 13:30 UTC
          color: Colors.blue,
        ),
      ];


      // Ensure the broker is ready (already waited, but double-check)
      if (!_broker.isReady) {
        throw Exception('Broker not ready');
      }

      // --- FIX: Use EventLayoutService to measure events ---
      final measuredLayouts = _layoutService.measureEvents(
        events: mockEvents,
        broker: _broker,
        minEventSize: minEventSize,
      );

      // --- FIX: Use EventPackingService to pack events ---
      // This calculates horizontal positions/widths to avoid overlaps.
      final packedLayouts = _packingService.packEvents(
        events: measuredLayouts, // Correct parameter name is 'events'
        minSecondarySize: minSecondarySize, // Pass the required min size
      );

      // Debug print the final calculated layout

      // Assign the packed layouts to the state
      final layoutInfoList = packedLayouts;

      // Update state with the calculated and packed layout info
      _events = layoutInfoList;
      _isLoading = false;
      notifyListeners();
    } catch (e, s) {
      // Add stack trace parameter 's'
      // Reset loading state on error
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Wait for the broker to be ready
  Future<void> _waitForBroker() async {
    // Check if broker is already ready
    if (_broker.isReady) return;

    // Wait for broker to be ready with timeout
    int attempts = 0;
    while (!_broker.isReady && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!_broker.isReady) {
      throw Exception('Broker not ready after timeout');
    }
  }

  /// Handle tap on an event
  void handleTap(Offset position) {
    final renderer = EventRenderer(
      events: _events,
      selectedEventId: _selectedEventId,
    );

    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      _selectedEventId = eventAtPosition.event.id;
      notifyListeners();

      controller.onEventTap?.call(eventAtPosition.event);
    } else {
      _selectedEventId = null;
      notifyListeners();
    }
  }

  /// Handle double tap on an event
  void handleDoubleTap(Offset position) {
    final renderer = EventRenderer(
      events: _events,
      selectedEventId: _selectedEventId,
    );

    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      controller.onEventDoubleTap?.call(eventAtPosition.event);
    }
  }

  /// Handle long press on an event
  void handleLongPress(Offset position) {
    final renderer = EventRenderer(
      events: _events,
      selectedEventId: _selectedEventId,
    );

    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      controller.onEventLongPress?.call(
        eventAtPosition.event,
        position,
      );
    }
  }

  /// Handle pan start for drag and resize
  void handlePanStart(Offset position) {
    final renderer = EventRenderer(
      events: _events,
      selectedEventId: _selectedEventId,
    );

    // Check if we're on a resize handle
    final resizeHandleHit = renderer.findResizeHandleAt(position);
    if (resizeHandleHit != null) {
      final event = resizeHandleHit.event.event;

      // Don't allow resizing all-day events
      if (event.isAllDay) return;

      _resizedEventId = event.id;
      _activeResizeHandle = resizeHandleHit.handle;
      _originalEvent = event;
      _originalStart = event.start;
      _originalEnd = event.end;
      notifyListeners();
      return;
    }

    // Check if we're on an event for dragging
    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      final event = eventAtPosition.event;

      _draggedEventId = event.id;
      _dragOffset = position - eventAtPosition.finalRect.topLeft;
      _originalEvent = event;
      _originalStart = event.start;
      _originalEnd = event.end;
      notifyListeners();
    }
  }

  /// Handle pan update for drag and resize
  void handlePanUpdate(Offset position) {
    if (_resizedEventId != null && _originalEvent != null) {
      _handleResize(position);
    } else if (_draggedEventId != null && _originalEvent != null) {
      _handleDrag(position);
    }
  }

  /// Handle drag updates
  void _handleDrag(Offset position) {
    // TODO: Implement drag logic using broker to convert position to date/time
    // This is a placeholder for now
    // Will use position and _dragOffset to calculate new event position
  }

  /// Handle resize updates
  void _handleResize(Offset position) {
    // TODO: Implement resize logic using broker to convert position to date/time
    // This is a placeholder for now
  }

  /// Handle pan end for drag and resize
  void handlePanEnd() {
    if (_resizedEventId != null &&
        _originalEvent != null &&
        _originalStart != null &&
        _originalEnd != null) {
      // Finalize resize
      // TODO: Implement final resize logic

      _resizedEventId = null;
      _activeResizeHandle = null;
      _originalEvent = null;
      _originalStart = null;
      _originalEnd = null;
      notifyListeners();
    } else if (_draggedEventId != null &&
        _originalEvent != null &&
        _originalStart != null &&
        _originalEnd != null) {
      // Finalize drag
      // TODO: Implement final drag logic

      _draggedEventId = null;
      _dragOffset = null;
      _originalEvent = null;
      _originalStart = null;
      _originalEnd = null;
      notifyListeners();
    }
  }

  // Getters

  /// Get the list of processed events
  List<EventLayoutInfo> get events => _events;

  /// Get the loading state
  bool get isLoading => _isLoading;

  /// Get the selected event ID
  String? get selectedEventId => _selectedEventId;

  /// Get the dragged event ID
  String? get draggedEventId => _draggedEventId;

  /// Get the resized event ID
  String? get resizedEventId => _resizedEventId;

  /// Get the active resize handle
  ResizeHandle? get activeResizeHandle => _activeResizeHandle;
}
