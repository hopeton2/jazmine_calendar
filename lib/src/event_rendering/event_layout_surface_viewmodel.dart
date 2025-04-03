import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_service.dart';
import 'package:jazmine_calendar/src/event_rendering/event_packing_service.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart'; // Needed for ResizeHandleHit
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'dart:math'; // Keep for potential future use if needed
import 'package:jazmine_calendar/src/services/time_position_service.dart'; // Needed for _positionToDateTime
import 'package:jazmine_calendar/src/event_rendering/event_rendering_manager.dart'; // Needed for processEvents
import 'package:jazmine_calendar/src/enums/enums.dart'; // Import enums for ResizeHandle

/// ViewModel for the EventLayoutSurface
/// Handles the business logic for event rendering and interaction
class EventLayoutSurfaceViewModel extends ChangeNotifier {
  /// Calendar controller
  final CalendarController controller;

  /// Services for event layout and packing
  final EventLayoutService _layoutService = EventLayoutService();
  final EventPackingService _packingService = EventPackingService();
  // Add rendering manager instance (needed for re-processing during drag/resize)
  final EventRenderingManager _renderingManager = EventRenderingManager();

  // Removed singleton gridInfo getter
  /// gridInfo instance for this surface - Made non-final
  late GridLayoutInfo _gridInfo;

  /// Minimum event size
  final double minEventSize;

  /// Minimum secondary size
  final double minSecondarySize;

  /// Indicates if this view model is for the all-day section.
  final bool isAllDay;

  /// The specific dates visible in the parent grid.
  final List<DateTime> visibleDates;

  // Removed orientation field (will get from gridInfo instance)

  /// Event rendering style used for packing calculations
  final EventRenderStyle renderStyle;

  /// List of processed events
  List<EventLayoutInfo> _events = [];

  /// Loading state
  bool _isLoading = false;

  /// Currently selected event ID
  String? _selectedEventId;

  /// Dragged event ID
  String? _draggedEventId;

  /// Resized event ID - Restored
  String? _resizedEventId;

  /// Active resize handle - Restored
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
    required GridLayoutInfo gridInfo, // Renamed for initialization
    this.minEventSize = 20.0,
    this.minSecondarySize = 20.0,
    required this.isAllDay,
    required this.visibleDates,
    required this.renderStyle, // Add renderStyle parameter
    // Removed orientation parameter
  }) {
    _gridInfo = gridInfo; // Initialize _gridInfo
    // Listen for controller updates to refetch events
    controller.addListener(_handleControllerUpdate);

    // Initial fetch and process
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _fetchAndProcessEvents();
    });
  }

  /// Dispose resources
  @override
  void dispose() {
    controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  /// Handle controller updates by refetching and processing events
  void _handleControllerUpdate() {
    // Refetch events when the controller notifies of changes
    // Don't fetch here initially, wait for gridInfo update or explicit call
    // _fetchAndProcessEvents(); // Let the initial call in initState handle it
    // We might need to reconsider the initial fetch logic slightly
    // Let's keep the initial fetch in initState for now.
    _fetchAndProcessEvents();
  }

  /// Fetch events from controller and process them
  Future<void> _fetchAndProcessEvents() async {
    if (_isLoading) return; // Prevent concurrent fetches

    _isLoading = true;
    notifyListeners();

    try {
      // No need to wait for gridInfo, it's passed in and assumed ready

      if (visibleDates.isEmpty) {
        print('Warning: visibleDates is empty in _fetchAndProcessEvents');
        _events = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      final rangeStart = visibleDates.first.toUtc().dayStarts;
      final rangeEnd = visibleDates.last.toUtc().dayEnds;

      final eventsFromController =
          await controller.getEventsForDateRange(rangeStart, rangeEnd);
      // Pass the gridInfo instance to _processEvents
      // Use the internal _gridInfo for processing
      await _processEvents(eventsFromController, _gridInfo);
    } catch (e, s) {
      print('Error fetching/processing events: $e\n$s');
      _events = [];
    } finally {
      // Removed mounted check
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper method to process a list of events (filter, measure and pack)
  Future<void> _processEvents(
      List<CalendarEvent> eventsToProcess, GridLayoutInfo gridInfo) async {
    // Add gridInfo parameter
    // No gridInfo readiness checks needed

    try {
      // 1. Filter by isAllDay flag
      final relevantTypeEvents =
          eventsToProcess.where((event) => event.isAllDay == isAllDay).toList();

      if (relevantTypeEvents.isEmpty) {
        _events = [];
        return;
      }

      // 2. Filter by visible dates
      final visibleDayStarts = visibleDates.map((d) => d.dayStarts).toSet();
      final filteredEvents = relevantTypeEvents.where((event) {
        DateTime current = event.start.dayStarts;
        bool startsBeforeOrDuring =
            !event.start.isAfter(visibleDates.last.dayEnds);
        bool endsDuringOrAfter =
            !event.end.isBefore(visibleDates.first.dayStarts);
        if (!startsBeforeOrDuring || !endsDuringOrAfter) return false;
        while (current.isBefore(event.end)) {
          if (visibleDayStarts.contains(current)) return true;
          current = current.add(const Duration(days: 1));
        }
        if (event.end.isAfter(event.start) &&
            event.end.millisecondsSinceEpoch % Duration.millisecondsPerDay ==
                0) {
          if (visibleDayStarts.contains(
              event.end.subtract(const Duration(milliseconds: 1)).dayStarts))
            return true;
        }
        return false;
      }).toList();

      if (filteredEvents.isEmpty) {
        _events = [];
        return;
      }

      // 3. Measure the filtered events using the gridInfo instance
      final measuredLayouts = _layoutService.measureEvents(
        events: filteredEvents,
        gridInfo: gridInfo, // Use the passed gridInfo for this specific process run
        minEventSize: minEventSize,
      );

      // 4. Pack the measured events
      final packedLayouts = _packingService.packEvents(
        events: measuredLayouts,
        minSecondarySize: minSecondarySize,
        style: renderStyle, // Use the stored renderStyle
      );

      _events = packedLayouts;
    } catch (e, s) {
      print('Error processing events: $e\n$s');
      _events = [];
    }
  }

  /// Updates the grid info and triggers a re-fetch and process.
  void updateGridInfo(GridLayoutInfo newGridInfo) {
   // if (_gridInfo != newGridInfo) { // Avoid unnecessary updates
      _gridInfo = newGridInfo;
      // Re-fetch and process events with the new grid dimensions
    //  _fetchAndProcessEvents();
    //}
    _fetchAndProcessEvents();
  }

  // Removed _waitForgridInfo method

  // --- Interaction Handlers ---

  /// Handle tap on an event
  void handleTap(Offset position, double scrollOffset) {
    // Add scrollOffset parameter
    // Use EventRenderer for hit testing
    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);

    if (eventAtPosition != null) {
      _selectedEventId = eventAtPosition.event.id;
      notifyListeners();
      controller.onEventTap?.call(eventAtPosition.event);
    } else {
      // Only deselect if the tap wasn't on an event
      if (_selectedEventId != null) {
        _selectedEventId = null;
        notifyListeners();
      }
    }
  }

  /// Handle double tap on an event
  void handleDoubleTap(Offset position, double scrollOffset) {
    // Add scrollOffset
    // Use EventRenderer for hit testing
    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      controller.onEventDoubleTap?.call(eventAtPosition.event);
    }
  }

  /// Handle long press on an event
  void handleLongPress(Offset position, double scrollOffset) {
    // Add scrollOffset
    // Use EventRenderer for hit testing
    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      controller.onEventLongPress?.call(
        eventAtPosition.event,
        position, // Pass local position relative to the surface
      );
    }
  }

  /// Handle pan start for drag and resize
  void handlePanStart(Offset position, double scrollOffset) {
    // Add scrollOffset
    // Use EventRenderer for hit testing
    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);

    // Check if we're on a resize handle first
    final resizeHandleHit = renderer.findResizeHandleAt(position);
    if (resizeHandleHit != null) {
      final event = resizeHandleHit.event.event;
      if (event.isAllDay) return; // Cannot resize all-day events

      _resizedEventId = event.id;
      _activeResizeHandle = resizeHandleHit.handle;
      _originalEvent = event;
      _originalStart = event.start;
      _originalEnd = event.end;
      notifyListeners();
      return; // Prioritize resize
    }

    // Check if we're on an event for dragging
    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      final event = eventAtPosition.event;
      _draggedEventId = event.id;
      _dragOffset = position -
          eventAtPosition.finalRect.topLeft; // Offset relative to event rect
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
    if (_draggedEventId == null ||
        _originalEvent == null ||
        _dragOffset == null) return;

    // Calculate new top-left position relative to the surface
    final newTopLeft = position - _dragOffset!;

    // Convert position to DateTime
    DateTime? newStartDateTime = _positionToDateTime(newTopLeft);
    if (newStartDateTime == null) return;

    // TODO: Add snapping logic if needed

    // Calculate new end time
    final duration = _originalEnd!.difference(_originalStart!);
    final newEndDateTime = newStartDateTime.add(duration);

    // Create updated event data
    final updatedEventData = _originalEvent!.copyWith(
      start: newStartDateTime,
      end: newEndDateTime,
    );

    // Re-process layout visually during drag
    // Use the current _gridInfo for drag/resize updates
    _updateLayoutForDragOrResize(updatedEventData, _draggedEventId!, _gridInfo);
  }

  /// Handle resize updates - Restored
  void _handleResize(Offset position) {
    if (_resizedEventId == null ||
        _originalEvent == null ||
        _activeResizeHandle == null) return;

    // Convert position to DateTime
    DateTime? newDateTime = _positionToDateTime(position);
    if (newDateTime == null) return;

    // TODO: Add snapping logic if needed

    // Create new event with updated times, ensuring start is before end
    CalendarEvent updatedEventData;
    if (_activeResizeHandle == ResizeHandle.top ||
        _activeResizeHandle == ResizeHandle.left) {
      // Adjust start time
      if (newDateTime.isBefore(_originalEnd!)) {
        updatedEventData = _originalEvent!.copyWith(start: newDateTime);
      } else {
        updatedEventData = _originalEvent!.copyWith(
            start: _originalEnd!.subtract(const Duration(minutes: 15)));
      }
    } else {
      // Adjust end time (bottom or right handle)
      if (newDateTime.isAfter(_originalStart!)) {
        updatedEventData = _originalEvent!.copyWith(end: newDateTime);
      } else {
        updatedEventData = _originalEvent!
            .copyWith(end: _originalStart!.add(const Duration(minutes: 15)));
      }
    }

    // Re-process layout visually during resize
    // Use the current _gridInfo for drag/resize updates
    _updateLayoutForDragOrResize(updatedEventData, _resizedEventId!, _gridInfo);
  }

  /// Helper to re-process layout during drag/resize for visual feedback
  void _updateLayoutForDragOrResize(CalendarEvent updatedEventData,
      String targetEventId, GridLayoutInfo currentGridInfo) {
    // Add currentGridInfo parameter
    // Create a temporary list with the updated event data
    final tempEvents = List<CalendarEvent>.from(_events
        .map((e) => e.event.id == targetEventId ? updatedEventData : e.event));

    // Reprocess layout using the manager, passing the gridInfo instance
    final tempPackedLayouts = _renderingManager.processEvents(
      events: tempEvents,
      minEventSize: minEventSize,
      minSecondarySize: minSecondarySize,
      gridInfo: currentGridInfo, // Use the passed gridInfo
    );

    // Update the state to show the dragged/resized position visually
    // Removed mounted check
    _events = tempPackedLayouts;
    notifyListeners(); // Update UI
  }

  /// Handle pan end for drag and resize
  void handlePanEnd() {
    bool changed = false;
    CalendarEvent? finalEvent;
    CalendarEvent? originalEvent = _originalEvent; // Capture original event

    if (_resizedEventId != null && originalEvent != null) {
      final finalLayoutInfo = _events.firstWhere(
        (e) => e.event.id == _resizedEventId,
        // orElse: () => null // Handle case where event might disappear?
      );
      finalEvent = finalLayoutInfo.event;
      // Check if time actually changed
      if (finalEvent.start != _originalStart ||
          finalEvent.end != _originalEnd) {
        controller.onEventResized?.call(
            originalEvent, finalEvent.start, finalEvent.end); // Add null check
        changed = true;
      }
      _resizedEventId = null;
      _activeResizeHandle = null;
    } else if (_draggedEventId != null && originalEvent != null) {
      final finalLayoutInfo = _events.firstWhere(
        (e) => e.event.id == _draggedEventId,
        // orElse: () => null
      );
      finalEvent = finalLayoutInfo.event;
      // Check if time actually changed
      if (finalEvent.start != _originalStart ||
          finalEvent.end != _originalEnd) {
        controller.onEventRescheduled?.call(
            originalEvent, finalEvent.start, finalEvent.end); // Add null check
        changed = true;
      }
      _draggedEventId = null;
      _dragOffset = null;
    }

    // Clear original event state
    _originalEvent = null;
    _originalStart = null;
    _originalEnd = null;

    // Notify if something actually changed or drag/resize ended
    if (changed || _draggedEventId == null || _resizedEventId == null) {
      notifyListeners();
    }
    // Optionally refetch after modification if persistence layer changed
    // _fetchAndProcessEvents();
  }

  // Getters
  List<EventLayoutInfo> get events => _events;
  bool get isLoading => _isLoading;
  String? get selectedEventId => _selectedEventId;
  String? get draggedEventId => _draggedEventId;
  String? get resizedEventId => _resizedEventId; // Restored
  ResizeHandle? get activeResizeHandle => _activeResizeHandle; // Restored

  // Removed local hit testing helpers (_findEventLayoutAt, findResizeHandleAt)
  // ViewModel now delegates hit testing to EventRenderer instance in handlers.

  /// Convert a position to a date/time based on grid layout (Helper)
  DateTime? _positionToDateTime(Offset position) {
    // Use the instance gridInfo
    // Delegate to the gridInfo instance's method
    // Use the internal _gridInfo
    return _gridInfo.getDateTimeForPosition(position);
  }
}
