import 'package:flutter/material.dart';
import 'dart:async'; // Keep for potential future use
import 'package:flutter/gestures.dart'; // For PointerDeviceKind
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface_viewmodel.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
// EventRenderer import removed
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
// PointerRelayService import removed
import 'dart:math';
import 'package:jazmine_calendar/src/models/calendar_event.dart'; // Import CalendarEvent
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // For dayStarts/dayEnds
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/services/time_position_service.dart'; // Keep for _snapToInterval
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'dart:ui' as ui; // Import for ui.TextDirection
import 'calendar_event_widget.dart'; // Import the new widget
// Removed duplicate dart:ui import

// Define callback type for overflow state
typedef OverflowStateCallback = void Function(
    bool hasOverflow, int hiddenCount, int maxLaneIndex);

/// Widget that renders calendar events using individual widgets in a Stack
/// and acts as a DragTarget for dropped events.
class EventLayoutSurface extends StatefulWidget {
  /// Calendar controller
  final CalendarController controller;

  /// Event rendering style
  final EventRenderStyle renderStyle;

  /// Minimum event height/width (depending on orientation)
  final double minEventSize;

  /// Minimum secondary dimension (width for vertical, height for horizontal)
  final double minSecondarySize;

  /// Scroll controller for the grid
  final ScrollController? scrollController;

  /// Indicates if this surface is for the all-day event section.
  final bool isAllDay;

  /// The specific dates visible in the parent grid.
  final List<DateTime> visibleDates;

  final GridLayoutInfo gridInfo;
  final int? maxVisibleAllDayEvents;
  final OverflowStateCallback? onOverflowStateChanged;
  final bool isCollapsed;
  final double? collapsedContentHeight;
  final bool snapToIntervalOnDrop; // Keep flag for potential use
  final bool enableResize; // Add enableResize flag

  /// Creates a new EventLayoutSurface
  const EventLayoutSurface({
    super.key,
    required this.controller,
    this.renderStyle = const EventRenderStyle(),
    this.minEventSize = 20.0,
    this.minSecondarySize = 20.0,
    this.scrollController,
    this.isAllDay = false,
    required this.visibleDates,
    required this.gridInfo,
    this.maxVisibleAllDayEvents,
    this.onOverflowStateChanged,
    this.isCollapsed = false,
    this.collapsedContentHeight,
    this.snapToIntervalOnDrop = true, // Default to true
    this.enableResize = true, // Default to true
  });

  @override
  EventLayoutSurfaceState createState() => EventLayoutSurfaceState();
}

class EventLayoutSurfaceState extends State<EventLayoutSurface> {
  // ViewModel
  late EventLayoutSurfaceViewModel _viewModel;

  // Public getter to expose the ViewModel (for height calculation in parent)
  EventLayoutSurfaceViewModel? get viewModelAccessor => _viewModel;

  // Track scroll offset for positioning events
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize the ViewModel (Simpler version without drop logic)
    _viewModel = EventLayoutSurfaceViewModel(
      controller: widget.controller,
      minEventSize: widget.minEventSize,
      minSecondarySize: widget.minSecondarySize,
      isAllDay: widget.isAllDay,
      visibleDates: widget.visibleDates,
      gridInfo: widget.gridInfo,
      renderStyle: widget.renderStyle,
      maxVisibleAllDayEvents: widget.maxVisibleAllDayEvents,
      onOverflowStateChanged: widget.onOverflowStateChanged,
      isCollapsed: widget.isCollapsed,
      collapsedContentHeight: widget.collapsedContentHeight,
      snapToIntervalOnDrop: widget.snapToIntervalOnDrop, // Pass flag
      scrollController: widget.scrollController,
    );

    // Listen for changes in the ViewModel
    _viewModel.addListener(_handleViewModelUpdate);

    // Listen to scroll events
    widget.scrollController?.addListener(_handleScroll);
    if (widget.scrollController?.hasClients ?? false) {
      _scrollOffset = widget.scrollController!.position.pixels;
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelUpdate);
    widget.scrollController?.removeListener(_handleScroll);
    _viewModel.dispose();
    super.dispose();
  }

  /// Handle scroll events
  void _handleScroll() {
    if (widget.scrollController != null &&
        widget.scrollController!.hasClients) {
      final newOffset = widget.scrollController!.position.pixels;
      if (_scrollOffset != newOffset) {
        setState(() {
          _scrollOffset = newOffset;
        });
      }
    }
  }

  @override
  void didUpdateWidget(EventLayoutSurface oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update scroll controller if changed
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController?.removeListener(_handleScroll);
      widget.scrollController?.addListener(_handleScroll);
      _scrollOffset = widget.scrollController?.hasClients ?? false
          ? widget.scrollController!.position.pixels
          : 0.0;
      _viewModel.updateScrollController(widget.scrollController);
    }

    // Update ViewModel with new data
    _viewModel.updateVisibleDates(widget.visibleDates);
    _viewModel.updateGridInfo(widget.gridInfo);
    _viewModel.updateMaxVisibleEvents(widget.maxVisibleAllDayEvents);
    _viewModel.updateOverflowCallback(widget.onOverflowStateChanged);
    _viewModel.updateCollapsedState(
        widget.isCollapsed, widget.collapsedContentHeight);
    _viewModel.updateSnapSetting(widget.snapToIntervalOnDrop);
    _viewModel.updateRenderStyle(widget.renderStyle);
  }

  /// Handle updates from the ViewModel
  void _handleViewModelUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the Stack with DragTarget
    return DragTarget<CalendarEvent>(
      builder: (context, candidateData, rejectedData) {
        // Build a Stack of Positioned Draggable event widgets
        return Stack(
          // Removed ClipRect wrapper
          clipBehavior: Clip.none, // Allow feedback to draw outside bounds
          children: _viewModel.events.map((eventLayoutInfo) {
            final event = eventLayoutInfo.event;
            final rect = eventLayoutInfo.finalRect;

            // Use a dedicated widget for rendering the event item
            // Use the new CalendarEventWidget with CustomPainter
            final isSelected = _viewModel.selectedEventId == event.id;
            final isResizing = _viewModel.resizedEventId == event.id;
            // Use enableResize from the widget's properties
            final eventWidgetChild = Padding(
              // Add Padding
              padding: const EdgeInsets.all(0.5), // Changed padding to 0.5
              child: CalendarEventWidget(
                key: ValueKey(event.id), // Use event ID for key
                eventLayoutInfo: eventLayoutInfo,
                style: widget.renderStyle,
                isSelected: isSelected,
                isResizing: isResizing,
                activeResizeHandle:
                    isResizing ? _viewModel.activeResizeHandle : null,
                enableResize:
                    widget.enableResize, // Pass widget's enableResize flag
              ),
            );

            // The feedback widget shown during drag - Use CalendarEventWidget
            final eventWidgetFeedback = Opacity(
              opacity: 0.7,
              child: Material(
                color: Colors.transparent,
                elevation: 4.0,
                // Ensure the Material widget itself has the correct size for the painter
                child: SizedBox(
                  width: rect.width,
                  height: rect.height,
                  child: Padding(
                    // Add Padding
                    padding:
                        const EdgeInsets.all(0.5), // Changed padding to 0.5
                    child: CalendarEventWidget(
                      // Key is not strictly needed for feedback, but can be kept
                      key: ValueKey('${event.id}_feedback'),
                      eventLayoutInfo: eventLayoutInfo,
                      style: widget.renderStyle,
                      // Feedback doesn't need selection, resizing state, or handles
                      isSelected: false,
                      isResizing: false,
                      activeResizeHandle: null,
                      enableResize: false, // Handles not needed for feedback
                    ),
                  ),
                ),
              ),
            );

            // Use Positioned for layout and AnimatedOpacity for fade
            return Positioned(
              // Removed duration and curve
              left: rect.left,
              // Adjust top position based on scroll offset for vertical orientation
              top: widget.gridInfo.orientation == Axis.vertical
                  ? rect.top - _scrollOffset
                  : rect.top,
              width: rect.width,
              height: rect.height,
              // Wrap the draggable content with AnimatedOpacity
              child: LongPressDraggable<CalendarEvent>(
                data: event, // The data being dragged
                feedback: eventWidgetFeedback, // Widget shown under the finger
                childWhenDragging: const SizedBox
                    .shrink(), // Hide original widget while dragging
                hapticFeedbackOnStart: true,
                // Use ViewModel handlers for pan gestures
                onDragStarted: () => _viewModel.handlePanStart(
                    eventLayoutInfo.finalRect.topLeft +
                        Offset(0, _scrollOffset),
                    _scrollOffset), // Pass position relative to surface
                onDragUpdate: (details) {
                  // Convert global position to position relative to content area
                  //final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  //final Offset surfaceLocalPosition = details.localPosition; // renderBox.globalToLocal(details.globalPosition);
                  //final Offset adjustedPosition = details.localPosition + Offset(0, _scrollOffset);
                  //_viewModel.handlePanUpdate(adjustedPosition, _scrollOffset);
                },
                onDragEnd: (details) => _viewModel.handlePanEnd(),
                onDraggableCanceled: (velocity, offset) =>
                    _viewModel.handlePanEnd(), // Treat cancel as end
                child: GestureDetector(
                  // Add GestureDetector for taps
                  onTap: () {
                    // Use ViewModel to handle tap
                    _viewModel.handleTap(
                        eventLayoutInfo.finalRect.topLeft +
                            Offset(0, _scrollOffset),
                        _scrollOffset); // Pass position relative to surface
                  },
                  onDoubleTap: () {
                    _viewModel.handleDoubleTap(
                        eventLayoutInfo.finalRect.topLeft +
                            Offset(0, _scrollOffset),
                        _scrollOffset);
                  },
                  // onLongPress removed to allow LongPressDraggable to handle drag start
                  child: eventWidgetChild,
                ),
              ),
            );
          }).toList(),
        ); // End Stack
      }, // End DragTarget builder
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        // --- Drop Logic moved back here from ViewModel ---
        final CalendarEvent event = details.data;
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final Offset surfaceLocalPosition =
            renderBox.globalToLocal(details.offset);
        final Offset adjustedPosition = surfaceLocalPosition +
            (widget.gridInfo.orientation == Axis.vertical
                ? Offset(widget.gridInfo.headerWidth, _scrollOffset)
                : Offset(_scrollOffset, widget.gridInfo.headerHeight));

        DateTime? localDropDateTime = TimePositionService.positionToTime(
          position: adjustedPosition,
          gridInfo: widget.gridInfo,
        );

        if (localDropDateTime == null) {
          // print("[EventLayoutSurface] Could not determine local drop time."); // Removed print
          return;
        }

        DateTime localNewStart;
        DateTime localNewEnd;

        if (widget.isAllDay) {
          // Snap to the start/end of the day in LOCAL time
          localNewStart = DateTime(localDropDateTime.year,
              localDropDateTime.month, localDropDateTime.day);
          localNewEnd = localNewStart.add(const Duration(days: 1));
        } else {
          // Handle timeline drop with optional snapping
          localNewStart = _snapToInterval(
              localDropDateTime); // Use snapping logic controlled by flag
          // Calculate duration based on original UTC times for consistency
          final originalStartUTC =
              event.start.isUtc ? event.start : event.start.toUtc();
          final originalEndUTC =
              event.end.isUtc ? event.end : event.end.toUtc();
          final duration = originalEndUTC.difference(originalStartUTC);
          localNewEnd = localNewStart.add(duration);
        }

        // Convert final local times to UTC before sending to controller
        final utcNewStart = localNewStart.toUtc();
        final utcNewEnd = localNewEnd.toUtc();

        // Reschedule only if UTC time changed. Ensure comparison uses UTC for original event times.
        final originalStartUTC =
            event.start.isUtc ? event.start : event.start.toUtc();
        final originalEndUTC = event.end.isUtc ? event.end : event.end.toUtc();

        if (utcNewStart != originalStartUTC || utcNewEnd != originalEndUTC) {
          widget.controller.rescheduleEvent(
              event, utcNewStart, utcNewEnd, widget.isAllDay);
        } else {}
        // --- End Drop Logic ---
      },
    ); // End DragTarget
  }

  /// Snap a date/time to the nearest interval boundary, preserving UTC/local kind.
  /// This version uses the controller's intervalNotifier.
  DateTime _snapToInterval(DateTime dateTime) {
    if (!widget.snapToIntervalOnDrop) {
      // Use widget flag
      // print("[EventLayoutSurface._snapToInterval] Snapping disabled, returning original: $dateTime");
      return dateTime;
    }
    final intervalMinutes = widget.controller.intervalNotifier.value.inMinutes;
    if (intervalMinutes <= 0)
      return dateTime; // Avoid division by zero or no snapping

    final totalMinutes = dateTime.hour * 60 + dateTime.minute;
    final remainder = totalMinutes % intervalMinutes;

    if (remainder == 0 &&
        dateTime.second == 0 &&
        dateTime.millisecond == 0 &&
        dateTime.microsecond == 0) {
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
      return DateTime.utc(dateTime.year, dateTime.month, dateTime.day,
          snappedHour, snappedMinute, 0, 0, 0 // Reset smaller units
          );
    } else {
      return DateTime(dateTime.year, dateTime.month, dateTime.day, snappedHour,
          snappedMinute, 0, 0, 0 // Reset smaller units
          );
    }
  }
}
