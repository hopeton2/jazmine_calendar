import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'dart:math';
import 'package:jazmine_calendar/src/event_rendering/event_rendering_manager.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface.dart'; // For OverflowStateCallback
import 'package:collection/collection.dart'; // For ListEquality, firstWhereOrNull

/// ViewModel for the EventLayoutSurface
/// Handles the business logic for event rendering and interaction
class EventLayoutSurfaceViewModel extends ChangeNotifier {
  /// Calendar controller
  final CalendarController controller;

  /// Services for event layout and packing
  final EventRenderingManager _renderingManager = EventRenderingManager();

  /// gridInfo instance for this surface
  late GridLayoutInfo _gridInfo;

  /// Minimum event size
  final double minEventSize;

  /// Minimum secondary size
  final double minSecondarySize;

  /// Indicates if this view model is for the all-day section.
  final bool isAllDay;

  /// The specific dates visible in the parent grid.
  List<DateTime> visibleDates;

  int? maxVisibleAllDayEvents;
  OverflowStateCallback? onOverflowStateChanged;

  // Fields for collapsed state filtering
  bool _isCollapsed = false;
  double? _collapsedContentHeight;
  bool _snapToIntervalOnDrop; // Flag to control snapping

  /// List of processed events (layout and packed) - Represents the stable layout
  List<EventLayoutInfo> _events = [];

  /// Loading state
  bool _isLoading = false;

  /// Currently selected event ID
  String? _selectedEventId;

  // --- Drag and Resize State ---
  String? _draggedEventId;
  String? _resizedEventId;
  ResizeHandle? _activeResizeHandle;
  Offset? _dragOffset; // Offset between initial touch point and event's top-left (both relative to content area)
  CalendarEvent? _originalEvent; // Event being dragged/resized
  DateTime? _originalStart; // Original UTC start time
  DateTime? _originalEnd; // Original UTC end time
  Offset? _initialPanPosition; // Initial pan position (relative to content area)
  Offset? _currentDragPosition; // Current pan position (relative to content area)
  ScrollController? _scrollController; // Field for scroll controller
  late EventRenderStyle _renderStyle; // Field for render style (initialized in constructor)

  /// Constructor
  EventLayoutSurfaceViewModel({
    required this.controller,
    required GridLayoutInfo gridInfo,
    this.minEventSize = 20.0,
    this.minSecondarySize = 20.0,
    required this.isAllDay,
    required this.visibleDates,
    required EventRenderStyle renderStyle, // Receive as parameter
    this.maxVisibleAllDayEvents,
    this.onOverflowStateChanged,
    bool isCollapsed = false,
    double? collapsedContentHeight,
    ScrollController? scrollController,
    required bool snapToIntervalOnDrop, // Add required parameter
  })  : _isCollapsed = isCollapsed,
        _collapsedContentHeight = collapsedContentHeight,
        _scrollController = scrollController,
        _snapToIntervalOnDrop = snapToIntervalOnDrop // Initialize the flag
  {
    _gridInfo = gridInfo;
    _renderStyle = renderStyle; // Initialize render style field
    controller.eventDataChangeNotifier.addListener(_handleEventDataChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndProcessEvents();
    });
  }

  /// Dispose resources
  @override
  void dispose() {
    controller.eventDataChangeNotifier.removeListener(_handleEventDataChange);
    super.dispose();
  }

  /// Handle notifications about event data changes.
  void _handleEventDataChange() {
    // If a drag/resize is in progress, don't refetch immediately,
    // it will be handled in handlePanEnd if needed.
    if (_draggedEventId == null && _resizedEventId == null) {
      _fetchAndProcessEvents();
    }
  }

  /// Fetch events from controller and process them
  Future<void> _fetchAndProcessEvents() async {
    if (_isLoading) return;

    _isLoading = true;
    List<EventLayoutInfo> previousEvents = List.from(_events);

    try {
      if (visibleDates.isEmpty) {
        _events = [];
      } else {
        final rangeStart = visibleDates.first.toUtc().dayStarts;
        final rangeEnd = visibleDates.last.toUtc().dayEnds;

        final eventsFromController =
            await controller.getEventsForDateRange(rangeStart, rangeEnd);
        _events = _renderingManager.processEvents(
            events: eventsFromController
                .where((ev) => ev.isAllDay == isAllDay)
                .toList(),
            gridInfo: _gridInfo,
            minEventSize: minEventSize,
            minSecondarySize: minSecondarySize,
            maxVisibleAllDayEvents: maxVisibleAllDayEvents);
      }
    } catch (e) {
      // print("Error fetching/processing events: $e"); // Removed print
      _events = [];
    } finally {
      _isLoading = false;
      if (!ListEquality().equals(previousEvents, _events)) {
          notifyListeners();
        }
      _calculateAndNotifyOverflow();
    }
  }

  /// Updates the snap setting.
  void updateSnapSetting(bool snap) {
    if (_snapToIntervalOnDrop != snap) {
      _snapToIntervalOnDrop = snap;
    }
  }

  // --- Public Methods for Interaction ---

  /// Handles the logic for an event drop, including time calculation, snapping, and rescheduling.
  /// All calculations up to the final controller call should be in LOCAL time.
  void handleEventDrop({
    required CalendarEvent event,
    required Offset surfaceLocalOffset, // This is WIDGET-LOCAL offset from DragTarget
    required double scrollOffset,
    // required BuildContext context, // No longer needed
  }) {
    // Calculate the local drop time using gridInfo
    DateTime? localDropDateTime = _gridInfo.getDateTimeForPosition(
      surfaceLocalOffset, // Pass WIDGET-LOCAL offset
      // scrollOffset parameter removed from getDateTimeForPosition
    );

    if (localDropDateTime == null) {
      // print("[ViewModel.handleEventDrop] Could not determine local drop time."); // Removed print
      return;
    }

    DateTime localNewStart;
    DateTime localNewEnd;

    if (isAllDay) {
      // Snap to the start/end of the day in LOCAL time
      localNewStart = DateTime(localDropDateTime.year, localDropDateTime.month, localDropDateTime.day); // Local midnight
      localNewEnd = localNewStart.add(const Duration(days: 1)); // Local midnight next day
    } else {
      // Handle timeline drop with optional snapping
      localNewStart = _snapToInterval(localDropDateTime); // Use snapping logic controlled by flag
      // Calculate duration based on original UTC times for consistency
      final originalStartUTC = event.start.isUtc ? event.start : event.start.toUtc();
      final originalEndUTC = event.end.isUtc ? event.end : event.end.toUtc();
      final duration = originalEndUTC.difference(originalStartUTC);
      localNewEnd = localNewStart.add(duration);
    }

    // Convert final local times to UTC before sending to controller
    final utcNewStart = localNewStart.toUtc();
    final utcNewEnd = localNewEnd.toUtc();

    // Reschedule only if UTC time changed. Ensure comparison uses UTC for original event times.
    final originalStartUTC = event.start.isUtc ? event.start : event.start.toUtc();
    final originalEndUTC = event.end.isUtc ? event.end : event.end.toUtc();

    if (utcNewStart != originalStartUTC || utcNewEnd != originalEndUTC) {
      // print("[ViewModel.handleEventDrop] Rescheduling event ${event.id}. UTC: $utcNewStart - $utcNewEnd"); // Removed print
      controller.rescheduleEvent(event, utcNewStart, utcNewEnd, isAllDay || event.isAllDay);
    } else {
      // print("[ViewModel.handleEventDrop] Drop detected for event ${event.id}, but time did not change."); // Removed print
    }
  }


  /// Updates the grid info and triggers a re-fetch and process.
  void updateGridInfo(GridLayoutInfo newGridInfo) {
    _gridInfo = newGridInfo;
    if (_draggedEventId == null && _resizedEventId == null) {
      _fetchAndProcessEvents();
    }
  }

  /// Updates the max visible events and triggers a re-process if changed.
  void updateMaxVisibleEvents(int? newMaxVisible) {
    if (maxVisibleAllDayEvents != newMaxVisible) {
      maxVisibleAllDayEvents = newMaxVisible;
      if (_draggedEventId == null && _resizedEventId == null) {
        _fetchAndProcessEvents();
      }
    }
  }

  /// Updates the overflow callback reference.
  void updateOverflowCallback(OverflowStateCallback? newCallback) {
    onOverflowStateChanged = newCallback;
    _calculateAndNotifyOverflow();
  }

  /// Updates the collapsed state if it changes.
  void updateCollapsedState(bool isCollapsed, double? collapsedContentHeight) {
    if (_isCollapsed != isCollapsed ||
        _collapsedContentHeight != collapsedContentHeight) {
      _isCollapsed = isCollapsed;
      _collapsedContentHeight = collapsedContentHeight;
      notifyListeners();
    }
  }

  /// Updates the visible dates and triggers a re-fetch if they changed.
  void updateVisibleDates(List<DateTime> newVisibleDates) {
    bool datesChanged = visibleDates.length != newVisibleDates.length ||
        !ListEquality().equals(visibleDates, newVisibleDates);

    if (datesChanged) {
      visibleDates = newVisibleDates;
      if (_draggedEventId == null && _resizedEventId == null) {
        _fetchAndProcessEvents();
      }
    }
  }

  /// Updates the render style.
  void updateRenderStyle(EventRenderStyle newStyle) {
    if (_renderStyle != newStyle) {
      _renderStyle = newStyle;
      notifyListeners();
    }
  }

  /// Updates the scroll controller reference.
  void updateScrollController(ScrollController? newController) {
    _scrollController = newController;
  }

  /// Calculates overflow state and notifies the parent widget.
  void _calculateAndNotifyOverflow() {
    if (onOverflowStateChanged == null) return;

    int maxLaneIndex = -1;
    int hiddenCount = 0;
    bool hasOverflow = false;
    final int maxVisible = maxVisibleAllDayEvents ?? 2;

    if (isAllDay && _events.isNotEmpty) {
      Set<String> hiddenEventIds = {};
      for (final eventLayout in _events) {
        maxLaneIndex = max(maxLaneIndex, eventLayout.laneIndex);
      }
      final int actualRowCount = maxLaneIndex + 1;

      if (actualRowCount > maxVisible) {
        hasOverflow = true;
        for (final event in _events) {
          if (event.laneIndex >= maxVisible) {
            hiddenEventIds.add(event.event.id);
          }
        }
        hiddenCount = hiddenEventIds.length;
      }
    }
    onOverflowStateChanged!(hasOverflow, hiddenCount, maxLaneIndex);
  }

  // --- Interaction Handlers ---

  /// Handle tap on an event
  void handleTap(Offset position, double scrollOffset) {
    if (_draggedEventId != null || _resizedEventId != null) return;

    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);

    if (eventAtPosition != null) {
      _selectedEventId = eventAtPosition.event.id;
      notifyListeners();
      controller.onEventTap?.call(eventAtPosition.event);
    } else if (_selectedEventId != null) {
      _selectedEventId = null;
      notifyListeners();
    }
  }

  /// Handle double tap on an event
  void handleDoubleTap(Offset position, double scrollOffset) {
    if (_draggedEventId != null || _resizedEventId != null) return;

    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);

    if (eventAtPosition != null) {
      controller.onEventDoubleTap?.call(eventAtPosition.event);
    }
  }

  /// Handle long press on an event
  void handleLongPress(Offset position, double scrollOffset) {
    if (_draggedEventId != null || _resizedEventId != null) return;

    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);

    if (eventAtPosition != null) {
      controller.onEventLongPress?.call(eventAtPosition.event, position);
    }
  }

  /// Handle the start of a pan gesture (drag or resize)
  void handlePanStart(Offset position, double scrollOffset) {
    // position is already adjusted for scroll offset by the caller (EventLayoutSurface)

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
      _initialPanPosition = position; // Relative to content area
      _currentDragPosition = position;
      notifyListeners();
      return;
    }

    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      final event = eventAtPosition.event;
      _draggedEventId = event.id;
      _originalEvent = event;
      _originalStart = event.start;
      _originalEnd = event.end;
      _initialPanPosition = position; // Relative to content area
      _currentDragPosition = position;

      // Calculate the event's top-left offset relative to the content area origin
      final originalTopLeft = _getOffsetForTime(_originalStart!);
      if (originalTopLeft == null) {
         // print("Error: Could not calculate original event position in handlePanStart."); // Removed print
         _resetDragResizeState(); // Abort drag
         return;
      }
      _dragOffset = _initialPanPosition! - originalTopLeft; // Offset between touch point and event top-left

      notifyListeners();
    }
  }

  /// Handle pan update during drag or resize
  /// [currentAdjustedPos] is the pointer position relative to the unscrolled content area.
  void handlePanUpdate(Offset currentAdjustedPos, double currentScrollOffset) {
    _currentDragPosition = currentAdjustedPos;
    notifyListeners();
  }

  /// Handle the end of a pan gesture - Restore simpler version
  Future<void> handlePanEnd() async {
    // Reset drag/resize state immediately
    final wasDraggingOrResizing = _draggedEventId != null || _resizedEventId != null;
    _resetDragResizeState(); // Reset state
    if (wasDraggingOrResizing) {
      notifyListeners(); // Notify UI to remove drag visuals
    }
    // Note: The actual calculation and update logic is triggered
    // by the DragTarget's onAcceptWithDetails -> handleEventDrop
  }


  /// Helper to reset all drag/resize state variables
  void _resetDragResizeState() {
    _draggedEventId = null;
    _resizedEventId = null;
    _activeResizeHandle = null;
    _dragOffset = null;
    _originalEvent = null;
    _originalStart = null;
    _originalEnd = null;
    _initialPanPosition = null;
    _currentDragPosition = null;
  }

  /// Convert a position (relative to the unscrolled content area 0,0) to a LOCAL date/time.
  DateTime? _positionToDateTime(Offset positionRelativeToContentArea) {
    try {
      // Use gridInfo to convert position to LOCAL DateTime
      // Pass scrollOffset 0 because positionRelativeToContentArea is already adjusted for scroll by caller
      return _gridInfo.getDateTimeForPosition(positionRelativeToContentArea); // scrollOffset no longer needed/accepted
    } catch (e) {
      // print("Error getting DateTime for position: $e"); // Removed print
      return null;
    }
  }

  /// Get the pixel offset (relative to content area 0,0) for a given LOCAL time.
  Offset? _getOffsetForTime(DateTime localTime) {
     try {
       // Find the division index for the given local time
       if (_gridInfo.viewStart == null) return null;
       final division = localTime.difference(_gridInfo.viewStart!.dayStarts).inDays;
       if (division < 0 || division >= _gridInfo.divisions) return null; // Outside view range

       // Use gridInfo to get the position
       return _gridInfo.getPositionForDateTime(localTime, division);
     } catch (e) {
       // print("Error getting position for DateTime: $e"); // Removed print
       return null;
     }
  }


  /// Snap a date/time to the nearest interval boundary, preserving UTC/local kind.
  /// This version uses the controller's intervalNotifier.
  DateTime _snapToInterval(DateTime dateTime) {
     if (!_snapToIntervalOnDrop) {
      // print("[ViewModel._snapToInterval] Snapping disabled, returning original: $dateTime");
      return dateTime;
    }
    final intervalMinutes = controller.intervalNotifier.value.inMinutes;
    if (intervalMinutes <= 0) return dateTime; // Avoid division by zero or no snapping

    final totalMinutes = dateTime.hour * 60 + dateTime.minute;
    final remainder = totalMinutes % intervalMinutes;

    if (remainder == 0 && dateTime.second == 0 && dateTime.millisecond == 0 && dateTime.microsecond == 0) {
       return dateTime; // Already snapped precisely
    }

    // Snap DOWN to the start of the CURRENT interval boundary
    int snappedTotalMinutes = (totalMinutes - remainder).toInt();

    // Handle potential day rollover - clamp to end of the day
    int snappedHour = snappedTotalMinutes ~/ 60;
    int snappedMinute = snappedTotalMinutes % 60;

    if (snappedHour >= 24) {
      // If snapping pushes past midnight, clamp to last possible interval of the original day
      snappedHour = 23;
      snappedMinute = 59;
      final lastIntervalStartMinute = (24 * 60) - intervalMinutes;
      if (lastIntervalStartMinute >= 0) {
        snappedMinute = (lastIntervalStartMinute % 60).toInt();
        snappedHour = (lastIntervalStartMinute ~/ 60).toInt();
      }
    }

    // Ensure snapped time doesn't go before the start of the day (00:00)
    if (snappedHour < 0) {
      snappedHour = 0;
      snappedMinute = 0;
    }

    // Construct new DateTime preserving original date and UTC flag
    if (dateTime.isUtc) {
      // This should not happen if _positionToDateTime returns local, but handle defensively
      // print("Warning: _snapToInterval received UTC time unexpectedly."); // Removed print
      return DateTime.utc(
        dateTime.year, dateTime.month, dateTime.day,
        snappedHour, snappedMinute, 0, 0, 0 // Reset smaller units
      );
    } else {
      return DateTime(
        dateTime.year, dateTime.month, dateTime.day,
        snappedHour, snappedMinute, 0, 0, 0 // Reset smaller units
      );
    }
  }


  // --- Getters ---
  List<EventLayoutInfo> get events => _events;
  bool get isLoading => _isLoading;
  String? get selectedEventId => _selectedEventId;

  // Getters for drag/resize state needed by the renderer
  String? get draggedEventId => _draggedEventId;
  String? get resizedEventId => _resizedEventId;
  ResizeHandle? get activeResizeHandle => _activeResizeHandle;
  Offset? get currentDragPosition => _currentDragPosition; // Position relative to content area
  Offset? get dragOffset => _dragOffset; // Offset within the event widget
  EventRenderStyle get renderStyle => _renderStyle; // Expose render style
}
