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
// Import the callback definition (assuming it's in event_layout_surface.dart)
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface.dart';
import 'package:collection/collection.dart'; // Import for ListEquality
/// ViewModel for the EventLayoutSurface
/// Handles the business logic for event rendering and interaction
class EventLayoutSurfaceViewModel extends ChangeNotifier {
  /// Calendar controller
  final CalendarController controller;

  /// Services for event layout and packing
  final EventLayoutService _layoutService = EventLayoutService();
  final EventPackingService _packingService = EventPackingService();
  final EventRenderingManager _renderingManager = EventRenderingManager();

  /// gridInfo instance for this surface - Made non-final
  late GridLayoutInfo _gridInfo;

  /// Minimum event size
  final double minEventSize;

  /// Minimum secondary size
  final double minSecondarySize;

  /// Indicates if this view model is for the all-day section.
  final bool isAllDay;

  /// The specific dates visible in the parent grid. Made non-final.
  List<DateTime> visibleDates;

  /// Event rendering style used for packing calculations
  final EventRenderStyle renderStyle;
  // Add maxVisibleAllDayEvents field back (make it nullable and potentially non-final)
  int? maxVisibleAllDayEvents;
  // Store the callback
  OverflowStateCallback? onOverflowStateChanged;
  // Add fields for collapsed state
  bool _isCollapsed = false;
  double? _collapsedContentHeight;
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

  /// Stores the number of lanes calculated during the last horizontal packing.
  int _lastCalculatedHorizontalLaneCount = 0; // Keep for potential future use

  /// Constructor
  EventLayoutSurfaceViewModel({
    required this.controller,
    required GridLayoutInfo gridInfo,
    this.minEventSize = 20.0,
    this.minSecondarySize = 20.0,
    required this.isAllDay,
    required this.visibleDates,
    required this.renderStyle,
    this.maxVisibleAllDayEvents, // Add parameter back
    this.onOverflowStateChanged, // Add callback parameter
    // Add new parameters to constructor (optional, with defaults)
    bool isCollapsed = false,
    double? collapsedContentHeight,
  }) : _isCollapsed = isCollapsed, // Initialize new fields
       _collapsedContentHeight = collapsedContentHeight {
    _gridInfo = gridInfo;
    controller.addListener(_handleControllerUpdate);
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
    _fetchAndProcessEvents();
  }

  /// Fetch events from controller and process them
  Future<void> _fetchAndProcessEvents() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners(); // Notify start of loading

    try {
      if (visibleDates.isEmpty) {
        print('Warning: visibleDates is empty in _fetchAndProcessEvents');
        _events = [];
        _isLoading = false;
        notifyListeners(); // Notify end of loading (empty state)
        _calculateAndNotifyOverflow(); // Notify overflow state even if empty
        return;
      }
      final rangeStart = visibleDates.first.toUtc().dayStarts;
      final rangeEnd = visibleDates.last.toUtc().dayEnds;

      final eventsFromController =
          await controller.getEventsForDateRange(rangeStart, rangeEnd);
      await _processEvents(eventsFromController, _gridInfo);
    } catch (e, s) {
      print('Error fetching/processing events: $e\n$s');
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify end of loading (with potentially updated events)
      // Calculate and notify overflow state *after* processing and notifying listeners
      _calculateAndNotifyOverflow();
    }
  }

  /// Helper method to process a list of events (filter, measure and pack)
  Future<void> _processEvents(
      List<CalendarEvent> eventsToProcess, GridLayoutInfo gridInfo) async {

    try {
      // 1. Filter by isAllDay flag
      final relevantTypeEvents =
          eventsToProcess.where((event) => event.isAllDay == isAllDay).toList();

      if (relevantTypeEvents.isEmpty) {
        _events = [];
        return; // No need to pack if empty
      }

      // 2. Filter by visible dates (REMOVED - measureEvents handles clipping to view)
      final filteredEvents = relevantTypeEvents;

      if (filteredEvents.isEmpty) {
         _events = [];
         return;
       }

      // 3. Measure the filtered events using the gridInfo instance
      final measuredLayouts = _layoutService.measureEvents(
        events: filteredEvents,
        gridInfo: gridInfo,
        minEventSize: minEventSize,
      );

      // 4. Pack the measured events
      final packedLayouts = _packingService.packEvents(
        events: measuredLayouts,
        minSecondarySize: minSecondarySize,
        style: renderStyle,
        visibleDates: visibleDates,
        maxVisibleAllDayEvents: maxVisibleAllDayEvents, // Pass down
      );
      _events = packedLayouts;
      // Reset lane count if not all-day
      if (!isAllDay) {
         _lastCalculatedHorizontalLaneCount = 0;
      }
    } catch (e, s) {
      print('Error processing events: $e\n$s');
      _events = [];
    }
    // Note: Overflow calculation happens in the finally block of _fetchAndProcessEvents
  }

  /// Updates the grid info and triggers a re-fetch and process.
  void updateGridInfo(GridLayoutInfo newGridInfo) {
    // Check if grid info actually changed to avoid unnecessary fetches
    if (_gridInfo != newGridInfo) {
        _gridInfo = newGridInfo;
        _fetchAndProcessEvents(); // Fetch immediately on grid info update
    }
  }

  /// Updates the max visible events and triggers a re-process if changed.
  void updateMaxVisibleEvents(int? newMaxVisible) {
    if (maxVisibleAllDayEvents != newMaxVisible) {
      maxVisibleAllDayEvents = newMaxVisible; // Update the internal value
      // Re-process events as the packing result depends on this value
      _fetchAndProcessEvents();
    }
  }

  /// Updates the overflow callback reference.
  void updateOverflowCallback(OverflowStateCallback? newCallback) {
      onOverflowStateChanged = newCallback;
      // Optionally, trigger a calculation immediately if needed
      _calculateAndNotifyOverflow();
    }
  
    /// Updates the collapsed state if it changes.
    void updateCollapsedState(bool isCollapsed, double? collapsedContentHeight) {
      if (_isCollapsed != isCollapsed || _collapsedContentHeight != collapsedContentHeight) {
        _isCollapsed = isCollapsed;
        _collapsedContentHeight = collapsedContentHeight;
        // No need to notify listeners here, as this doesn't directly change
        // the rendered event list, only how it might be filtered by the renderer.
        // The parent widget rebuilds anyway when collapsed state changes.
      }
    }
  
    /// Updates the visible dates and triggers a re-fetch if they changed.
    void updateVisibleDates(List<DateTime> newVisibleDates) {
      // Simple equality check might not be sufficient for lists.
      // Consider a more robust check if necessary (e.g., comparing elements).
      bool datesChanged = visibleDates.length != newVisibleDates.length ||
                          !ListEquality().equals(visibleDates, newVisibleDates);
  
      if (datesChanged) {
        visibleDates = newVisibleDates;
        _fetchAndProcessEvents(); // Fetch events for the new date range
      }
    }

  /// Calculates overflow state and notifies the parent widget.
  void _calculateAndNotifyOverflow() {
      if (onOverflowStateChanged == null) return; // No callback registered

      int maxLaneIndex = -1;
      Set<String> hiddenEventIds = {};
      int hiddenCount = 0;
      bool hasOverflow = false;
      final int maxVisible = maxVisibleAllDayEvents ?? 2; // Use default if null

      if (_events.isNotEmpty) {
          for (final eventLayout in _events) {
              maxLaneIndex = max(maxLaneIndex, eventLayout.laneIndex);
          }
          final int actualRowCount = maxLaneIndex + 1;

          if (actualRowCount > maxVisible) {
              hasOverflow = true;
              // Count unique hidden events
              for (final event in _events) {
                  if (event.laneIndex >= maxVisible) {
                     hiddenEventIds.add(event.event.id);
                  }
              }
              hiddenCount = hiddenEventIds.length;
          }
      }
      // Call the callback with the calculated state
      onOverflowStateChanged!(hasOverflow, hiddenCount, maxLaneIndex);
  }


  // --- Interaction Handlers ---
  // ... (Interaction handlers remain the same) ...

  /// Handle tap on an event
  void handleTap(Offset position, double scrollOffset) {
    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);

    if (eventAtPosition != null) {
      _selectedEventId = eventAtPosition.event.id;
      notifyListeners();
      controller.onEventTap?.call(eventAtPosition.event);
    } else {
      if (_selectedEventId != null) {
        _selectedEventId = null;
        notifyListeners();
      }
    }
  }

  /// Handle double tap on an event
  void handleDoubleTap(Offset position, double scrollOffset) {
    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      controller.onEventDoubleTap?.call(eventAtPosition.event);
    }
  }

  /// Handle long press on an event
  void handleLongPress(Offset position, double scrollOffset) {
    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      controller.onEventLongPress?.call(
        eventAtPosition.event,
        position,
      );
    }
  }

  /// Handle pan start for drag and resize
  void handlePanStart(Offset position, double scrollOffset) {
    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);

    final resizeHandleHit = renderer.findResizeHandleAt(position);
    if (resizeHandleHit != null) {
      final event = resizeHandleHit.event.event;
      if (event.isAllDay) return;

      _resizedEventId = event.id;
      _activeResizeHandle = resizeHandleHit.handle;
      _originalEvent = event;
      _originalStart = event.start;
      _originalEnd = event.end;
      notifyListeners();
      return;
    }

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
    if (_draggedEventId == null || _originalEvent == null || _dragOffset == null) return;

    final newTopLeft = position - _dragOffset!;
    DateTime? newStartDateTime = _positionToDateTime(newTopLeft);
    if (newStartDateTime == null) return;

    final duration = _originalEnd!.difference(_originalStart!);
    final newEndDateTime = newStartDateTime.add(duration);

    final updatedEventData = _originalEvent!.copyWith(
      start: newStartDateTime,
      end: newEndDateTime,
    );

    _updateLayoutForDragOrResize(updatedEventData, _draggedEventId!, _gridInfo);
  }

  /// Handle resize updates - Restored
  void _handleResize(Offset position) {
    if (_resizedEventId == null || _originalEvent == null || _activeResizeHandle == null) return;

    DateTime? newDateTime = _positionToDateTime(position);
    if (newDateTime == null) return;

    CalendarEvent updatedEventData;
    if (_activeResizeHandle == ResizeHandle.top || _activeResizeHandle == ResizeHandle.left) {
      if (newDateTime.isBefore(_originalEnd!)) {
        updatedEventData = _originalEvent!.copyWith(start: newDateTime);
      } else {
        updatedEventData = _originalEvent!.copyWith(start: _originalEnd!.subtract(const Duration(minutes: 15)));
      }
    } else {
      if (newDateTime.isAfter(_originalStart!)) {
        updatedEventData = _originalEvent!.copyWith(end: newDateTime);
      } else {
        updatedEventData = _originalEvent!.copyWith(end: _originalStart!.add(const Duration(minutes: 15)));
      }
    }

    _updateLayoutForDragOrResize(updatedEventData, _resizedEventId!, _gridInfo);
  }

  /// Helper to re-process layout during drag/resize for visual feedback
  void _updateLayoutForDragOrResize(CalendarEvent updatedEventData,
      String targetEventId, GridLayoutInfo currentGridInfo) {
    final tempEvents = List<CalendarEvent>.from(_events
        .map((e) => e.event.id == targetEventId ? updatedEventData : e.event));

    // Pass maxVisibleAllDayEvents from the current state
    final tempPackedLayouts = _renderingManager.processEvents(
      events: tempEvents,
      minEventSize: minEventSize,
      minSecondarySize: minSecondarySize,
      gridInfo: currentGridInfo,
      maxVisibleAllDayEvents: maxVisibleAllDayEvents, // Pass current value
    );

    _events = tempPackedLayouts;
    notifyListeners(); // Update UI
    // Recalculate overflow after drag/resize update
    _calculateAndNotifyOverflow();
  }

  /// Handle pan end for drag and resize
  void handlePanEnd() {
    bool changed = false;
    CalendarEvent? finalEvent;
    CalendarEvent? originalEvent = _originalEvent; // Capture original event

    if (_resizedEventId != null && originalEvent != null) {
      final finalLayoutInfo = _events.firstWhere((e) => e.event.id == _resizedEventId);
      finalEvent = finalLayoutInfo.event;
      if (finalEvent.start != _originalStart || finalEvent.end != _originalEnd) {
        controller.onEventResized?.call(originalEvent, finalEvent.start, finalEvent.end);
        changed = true;
      }
      _resizedEventId = null;
      _activeResizeHandle = null;
    } else if (_draggedEventId != null && originalEvent != null) {
      final finalLayoutInfo = _events.firstWhere((e) => e.event.id == _draggedEventId);
      finalEvent = finalLayoutInfo.event;
      if (finalEvent.start != _originalStart || finalEvent.end != _originalEnd) {
        controller.onEventRescheduled?.call(originalEvent, finalEvent.start, finalEvent.end);
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
    // Recalculate overflow state after drag/resize ends
    _calculateAndNotifyOverflow();
  }

  // Getters
  List<EventLayoutInfo> get events => _events;
  bool get isLoading => _isLoading;
  String? get selectedEventId => _selectedEventId;
  String? get draggedEventId => _draggedEventId;
  String? get resizedEventId => _resizedEventId; // Restored
  ResizeHandle? get activeResizeHandle => _activeResizeHandle; // Restored

  /// Convert a position to a date/time based on grid layout (Helper)
  DateTime? _positionToDateTime(Offset position) {
    return _gridInfo.getDateTimeForPosition(position);
  }
}
// Removed import from bottom
