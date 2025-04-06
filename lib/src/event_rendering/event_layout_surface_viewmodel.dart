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
  Offset? _dragOffset;
  CalendarEvent? _originalEvent;
  DateTime? _originalStart;
  DateTime? _originalEnd;
  Offset? _initialPanPosition;
  Offset? _currentDragPosition;
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
    ScrollController? scrollController, // Receive scroll controller
  })  : _isCollapsed = isCollapsed,
        _collapsedContentHeight = collapsedContentHeight,
        _scrollController = scrollController // Initialize scroll controller field
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
    // Avoid notifying if it's just a background refresh triggered by data change
    // notifyListeners();

    List<EventLayoutInfo> previousEvents = List.from(_events); // Keep track for comparison

    try {
      if (visibleDates.isEmpty) {
        _events = [];
      } else {
        final rangeStart = visibleDates.first.toUtc().dayStarts;
        final rangeEnd = visibleDates.last.toUtc().dayEnds;

        final eventsFromController =
            await controller.getEventsForDateRange(rangeStart, rangeEnd);
        // Use the rendering manager which combines layout and packing
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
      print("Error fetching/processing events: $e");
      _events = []; // Reset on error
    } finally {
      _isLoading = false;
      // Only notify if the actual layout info list has changed.
      if (!ListEquality().equals(previousEvents, _events)) {
          notifyListeners();
      }
      _calculateAndNotifyOverflow(); // Calculate overflow based on the new state
    }
  }

  /// Updates the grid info and triggers a re-fetch and process.
  void updateGridInfo(GridLayoutInfo newGridInfo) {
    // Always update the grid info when the widget provides a new one.
    // The parent view is responsible for deciding when the layout changes.
    _gridInfo = newGridInfo;
    // Avoid refetch if drag/resize is in progress, it will be handled by handlePanEnd.
    if (_draggedEventId == null && _resizedEventId == null) {
      _fetchAndProcessEvents();
    }
  }

  /// Updates the max visible events and triggers a re-process if changed.
  void updateMaxVisibleEvents(int? newMaxVisible) {
    if (maxVisibleAllDayEvents != newMaxVisible) {
      maxVisibleAllDayEvents = newMaxVisible;
      // Avoid refetch if drag/resize is in progress
      if (_draggedEventId == null && _resizedEventId == null) {
        _fetchAndProcessEvents();
      }
    }
  }

  /// Updates the overflow callback reference.
  void updateOverflowCallback(OverflowStateCallback? newCallback) {
    onOverflowStateChanged = newCallback;
    _calculateAndNotifyOverflow(); // Recalculate with potentially new callback
  }

  /// Updates the collapsed state if it changes.
  void updateCollapsedState(bool isCollapsed, double? collapsedContentHeight) {
    if (_isCollapsed != isCollapsed ||
        _collapsedContentHeight != collapsedContentHeight) {
      _isCollapsed = isCollapsed;
      _collapsedContentHeight = collapsedContentHeight;
      // Notify listeners as this affects rendering directly
      notifyListeners();
    }
  }

  /// Updates the visible dates and triggers a re-fetch if they changed.
  void updateVisibleDates(List<DateTime> newVisibleDates) {
    bool datesChanged = visibleDates.length != newVisibleDates.length ||
        !ListEquality().equals(visibleDates, newVisibleDates);

    if (datesChanged) {
      visibleDates = newVisibleDates;
      // Avoid refetch if drag/resize is in progress
      if (_draggedEventId == null && _resizedEventId == null) {
        _fetchAndProcessEvents();
      }
    }
  }

  /// Updates the render style.
  void updateRenderStyle(EventRenderStyle newStyle) {
    // Assuming style changes don't require re-fetching events, just repaint
    if (_renderStyle != newStyle) {
      _renderStyle = newStyle;
      notifyListeners(); // Notify for repaint with new style
    }
  }

  /// Updates the scroll controller reference.
  void updateScrollController(ScrollController? newController) {
    // No direct action needed in ViewModel when controller changes,
    // but store it for potential use (like in BaseDayView overlay)
    _scrollController = newController;
  }

  /// Calculates overflow state and notifies the parent widget.
  void _calculateAndNotifyOverflow() {
    if (onOverflowStateChanged == null) return;

    int maxLaneIndex = -1;
    int hiddenCount = 0;
    bool hasOverflow = false;
    final int maxVisible = maxVisibleAllDayEvents ?? 2; // Default max visible

    if (isAllDay && _events.isNotEmpty) { // Only calculate for all-day section
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
    // Ensure callback is always called, even if no overflow
    onOverflowStateChanged!(hasOverflow, hiddenCount, maxLaneIndex);
  }

  // --- Interaction Handlers ---

  /// Handle tap on an event
  void handleTap(Offset position, double scrollOffset) {
    // Ensure no drag/resize is in progress
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
    // Ensure no drag/resize is in progress
    if (_draggedEventId != null || _resizedEventId != null) return;

    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);

    if (eventAtPosition != null) {
      controller.onEventDoubleTap?.call(eventAtPosition.event);
    }
  }

  /// Handle long press on an event
  void handleLongPress(Offset position, double scrollOffset) {
    // Ensure no drag/resize is in progress
    if (_draggedEventId != null || _resizedEventId != null) return;

    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final eventAtPosition = renderer.findEventAt(position);

    if (eventAtPosition != null) {
      controller.onEventLongPress?.call(eventAtPosition.event, position);
      // Potentially initiate drag here if desired, similar to handlePanStart
    }
  }

  /// Handle the start of a pan gesture (drag or resize)
  void handlePanStart(Offset position, double scrollOffset) {
    // position is already adjusted for scroll offset by the caller (EventLayoutSurface)

    // Check if we're on a resize handle first
    final renderer = EventRenderer(events: _events, scrollOffset: scrollOffset);
    final resizeHandleHit = renderer.findResizeHandleAt(position);

    if (resizeHandleHit != null) {
      final event = resizeHandleHit.event.event;
      // Don't allow resize for all-day events
      if (event.isAllDay) return;

      _resizedEventId = event.id;
      _activeResizeHandle = resizeHandleHit.handle;
      _originalEvent = event;
      _originalStart = event.start;
      _originalEnd = event.end;
      _initialPanPosition = position;
      _currentDragPosition = position; // Initialize current position
      notifyListeners(); // Notify UI about resize start
      return;
    }

    // Check if we're on an event (for dragging)
    final eventAtPosition = renderer.findEventAt(position);
    if (eventAtPosition != null) {
      final event = eventAtPosition.event;

      // Store drag state
      _draggedEventId = event.id;
      _dragOffset = position - eventAtPosition.finalRect.topLeft;
      _originalEvent = event;
      _originalStart = event.start;
      _originalEnd = event.end;
      _initialPanPosition = position;
      _currentDragPosition = position; // Initialize current position

      // Notify listeners to update UI (e.g., cursor, visual feedback)
      notifyListeners();
    }
  }

  /// Handle pan update during drag or resize
  /// [currentAdjustedPos] is the pointer position relative to the unscrolled content area.
  void handlePanUpdate(Offset currentAdjustedPos, double currentScrollOffset) {
    // Store the correctly calculated position passed from the view
    _currentDragPosition = currentAdjustedPos;

    // Notify listeners to trigger repaint with the new _currentDragPosition
    // The renderer will use this position to draw the dragged/resized item
    notifyListeners();

    // --- Visual update is handled by the renderer using _currentDragPosition ---
  }

  /// Handle the end of a pan gesture
  Future<void> handlePanEnd() async { // Make async
    bool changed = false;
    CalendarEvent? originalEventForCallback;
    DateTime? finalNewStart;
    DateTime? finalNewEnd;
    bool wasResize = false; // Flag to know which user callback to fire

    // Store necessary state before resetting
    final currentDraggedId = _draggedEventId;
    final currentResizedId = _resizedEventId;
    final currentOriginalEvent = _originalEvent;
    final currentOriginalStart = _originalStart;
    final currentOriginalEnd = _originalEnd;
    final currentDragOffset = _dragOffset;
    final currentActiveHandle = _activeResizeHandle;
    final lastDragPosition = _currentDragPosition; // Use the last position recorded

    // Reset drag/resize state immediately to stop visual feedback
    final wasDraggingOrResizing =
        _draggedEventId != null || _resizedEventId != null;
    _resetDragResizeState();
    if (wasDraggingOrResizing) {
      notifyListeners(); // Update UI to remove drag visuals
    }

    // --- Perform calculations if a drag/resize was in progress ---
    if (lastDragPosition == null || currentOriginalEvent == null) {
      return; // Exit if essential data is missing
    }

    if (currentResizedId != null && currentActiveHandle != null) {
      // --- Calculate final resize times ---
      wasResize = true;
      originalEventForCallback = currentOriginalEvent;
      DateTime? rawDateTime = _positionToDateTime(lastDragPosition);
      if (rawDateTime != null) {
        // Snap the calculated time to the nearest interval
        DateTime newDateTime = _snapToInterval(rawDateTime);
        DateTime newStart = currentOriginalStart!;
        DateTime newEnd = currentOriginalEnd!;

        if (currentActiveHandle == ResizeHandle.top ||
            currentActiveHandle == ResizeHandle.left) {
          newStart = newDateTime;
        } else {
          newEnd = newDateTime;
        }

        // Still enforce minimum duration, but base it on raw drop time
        final minDuration = controller.intervalNotifier.value;
        if (newEnd.difference(newStart) < minDuration) {
          if (currentActiveHandle == ResizeHandle.top ||
              currentActiveHandle == ResizeHandle.left) {
            newStart = newEnd.subtract(minDuration);
          } else {
            newEnd = newStart.add(minDuration);
          }
        }

        if (newStart != currentOriginalStart || newEnd != currentOriginalEnd) {
          finalNewStart = newStart;
          finalNewEnd = newEnd;
          changed = true;
        }
      }
    } else if (currentDraggedId != null && currentDragOffset != null) {
      // --- Calculate final drag times ---
      wasResize = false;
      originalEventForCallback = currentOriginalEvent;
      final newTopLeft = lastDragPosition - currentDragOffset;
      DateTime? newStartDateTimeRaw =
          _positionToDateTime(newTopLeft); // Calculate time from position

      if (newStartDateTimeRaw != null) {
        // Snap the calculated time to the nearest interval
        DateTime newStartDateTime = _snapToInterval(newStartDateTimeRaw);

        final duration = currentOriginalEnd!.difference(currentOriginalStart!);
        final newEndDateTime = newStartDateTime.add(duration);

        if (newStartDateTime != currentOriginalStart ||
            newEndDateTime != currentOriginalEnd) {
          finalNewStart = newStartDateTime;
          finalNewEnd = newEndDateTime;
          changed = true;
        }
      }
    }

    // --- If times changed, perform the update using the controller ---
    if (changed &&
        originalEventForCallback != null &&
        finalNewStart != null &&
        finalNewEnd != null) {
      try {
        // Call the centralized update method on the controller
        // This handles persistence and triggers the data change notification
        // Convert local times back to UTC before updating the controller
        await controller.updateEventTimes(originalEventForCallback,
            finalNewStart!.toUtc(), finalNewEnd!.toUtc());

        // The ViewModel's _handleEventDataChange listener will automatically call _fetchAndProcessEvents.

        // Now, fire the appropriate user callback *after* the update is done
        if (wasResize) {
          controller.onEventResized?.call(
              originalEventForCallback, finalNewStart!, finalNewEnd!);
        } else {
          controller.onEventRescheduled?.call(
              originalEventForCallback, finalNewStart!, finalNewEnd!);
        }
      } catch (e) {
        print("Error during controller.updateEventTimes or user callback: $e");
        // Attempt to refetch to sync UI even if update failed
        _fetchAndProcessEvents(); // Consider if refetch is appropriate on error
      }
    } else if (wasDraggingOrResizing && !changed) {
      // No change occurred, state was already reset and UI notified. No further action needed.
    }
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

  /// Convert a position (relative to the unscrolled content area 0,0) to a date/time, attempting to match grid's timezone kind.
  DateTime? _positionToDateTime(Offset positionRelativeToContentArea) {
    try {
      // The positionRelativeToContentArea is already relative to the EventLayoutSurface's
      // top-left, which is positioned at the grid origin. So, no further adjustment needed.
      DateTime? calculatedTime =
          _gridInfo.getDateTimeForPosition(positionRelativeToContentArea);
      // calculatedTime is now guaranteed to be local DateTime by getDateTimeForPosition
      return calculatedTime;
    } catch (e) {
      print("Error getting DateTime for position: $e");
      return null;
    }
  }

  /// Snap a date/time to the nearest interval boundary, preserving UTC/local kind.
  DateTime _snapToInterval(DateTime dateTime) {
    final intervalMinutes = controller.intervalNotifier.value.inMinutes;
    if (intervalMinutes <= 0) return dateTime; // Avoid division by zero or no snapping

    final totalMinutes = dateTime.hour * 60 + dateTime.minute;
    final remainder = totalMinutes % intervalMinutes;

    if (remainder == 0) return dateTime; // Already snapped

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
      return DateTime.utc(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        snappedHour,
        snappedMinute,
      );
    } else {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        snappedHour,
        snappedMinute,
      );
    }
  }

  // Getters
  List<EventLayoutInfo> get events => _events;
  bool get isLoading => _isLoading;
  String? get selectedEventId => _selectedEventId;
  String? get draggedEventId => _draggedEventId;
  String? get resizedEventId => _resizedEventId;
  ResizeHandle? get activeResizeHandle => _activeResizeHandle;
  GridLayoutInfo get gridInfo => _gridInfo;
  Offset? get currentDragPosition => _currentDragPosition; // Expose current drag position
  Offset? get dragOffset => _dragOffset; // Expose drag offset
  // Getter for the layout info of the currently dragged event
  EventLayoutInfo? get draggedEventLayoutInfo => _draggedEventId != null
      ? _events.firstWhereOrNull((e) => e.event.id == _draggedEventId)
      : null;
  // Expose scroll controller if needed by parent
  ScrollController? get scrollController => _scrollController;
  // Expose render style if needed by parent
  EventRenderStyle get renderStyle => _renderStyle;
}
