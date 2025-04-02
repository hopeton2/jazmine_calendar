import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart';
import 'package:jazmine_calendar/src/event_rendering/event_rendering_manager.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // Added for dayStarts/Ends
import 'package:jazmine_calendar/src/enums/enums.dart'; // Ensure import for ResizeHandle

/// Widget that displays calendar events with interaction support
class EventDisplayWidget extends StatefulWidget {
  /// Calendar controller
  final CalendarController controller;

  /// Style configuration
  final EventRenderStyle renderStyle;

  /// Minimum event size
  final double minEventSize;

  /// Minimum secondary size
  final double minSecondarySize;

  /// Time format for displaying event times
  final DateFormat? timeFormat;

  /// Callback when an event is tapped
  final Function(CalendarEvent)? onEventTap;

  /// Callback when an event is double tapped
  final Function(CalendarEvent)? onEventDoubleTap;

  /// Callback when an event is long pressed
  final Function(CalendarEvent, Offset)? onEventLongPress;

  /// Callback when an event is moved
  final Function(CalendarEvent, DateTime, DateTime)? onEventMove;

  /// Callback when an event is resized
  final Function(CalendarEvent, DateTime, DateTime)? onEventResize;
  // Removed onEventResize callback

  /// Whether events can be dragged
  final bool enableDrag;

  /// Whether events can be resized
  final bool enableResize;
// Removed enableResize flag

  /// The broker instance for the grid this widget belongs to.
  final GridLayoutInfo broker; // Renamed class

  /// Creates a new EventDisplayWidget
  const EventDisplayWidget({
    super.key,
    required this.controller,
    this.renderStyle = const EventRenderStyle(),
    this.minEventSize = 20.0,
    this.minSecondarySize = 20.0,
    this.timeFormat,
    this.onEventTap,
    this.onEventDoubleTap,
    this.onEventLongPress,
    this.onEventMove,
    this.onEventResize, // Restored parameter
    this.enableDrag = true,
    this.enableResize = true, // Restored parameter
    required this.broker, // Add broker parameter
  });

  @override
  State<EventDisplayWidget> createState() => _EventDisplayWidgetState();
}

class _EventDisplayWidgetState extends State<EventDisplayWidget> {
  /// List of processed events
  List<EventLayoutInfo> _packedEvents = [];

  /// Whether events are being loaded
  bool _isLoading = false;

  /// Currently selected event ID
  String? _selectedEventId;

  /// Event being dragged
  String? _draggedEventId;

  /// Original event data before dragging
  CalendarEvent? _originalEvent;

  /// Event being resized
  String? _resizedEventId;

  /// Active resize handle
  ResizeHandle?
      _activeResizeHandle; // Needs import 'package:jazmine_calendar/src/enums/enums.dart';
  // Removed resizing state variables (_resizedEventId, _activeResizeHandle)

  /// Drag offset for calculating position (for dragging)
  Offset? _dragOffset;

  /// Initial position when starting a drag/resize
  Offset? _initialDragPosition;

  /// Original start time (needed for drag/resize finalization)
  DateTime? _originalStart;

  /// Original end time (needed for drag/resize finalization)
  DateTime? _originalEnd;

  /// Event rendering manager
  final EventRenderingManager _renderingManager = EventRenderingManager();

  // Removed local broker instance - use widget.broker

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerUpdate);
    // Initial fetch after first layout
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fetchAndProcessEvents());
  }

  @override
  void didUpdateWidget(EventDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerUpdate);
      widget.controller.addListener(_handleControllerUpdate);
      // Fetch events when controller changes
      _fetchAndProcessEvents();
    }

    // Reprocess if style or size constraints change
    if (oldWidget.renderStyle != widget.renderStyle ||
        oldWidget.minEventSize != widget.minEventSize ||
        oldWidget.minSecondarySize != widget.minSecondarySize) {
      // Clear cache only if style affecting packing might have changed
      if (oldWidget.renderStyle != widget.renderStyle) {
        _renderingManager.clearCache();
      }
      _fetchAndProcessEvents();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  /// Handle controller updates
  void _handleControllerUpdate() {
    // Only reprocess events if the events have changed flag is set
    if (widget.controller.eventsChanged) {
      _renderingManager.clearCache();
      _fetchAndProcessEvents();
    }
  }

  /// Fetch and process events
  Future<void> _fetchAndProcessEvents() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // No broker readiness checks needed - assume widget.broker is ready

      // Get events from the rendering manager, passing the broker instance
      final packedEvents = await _renderingManager.fetchAndProcessEvents(
        controller: widget.controller,
        minEventSize: widget.minEventSize,
        minSecondarySize: widget.minSecondarySize,
        broker: widget.broker, // Pass broker instance
      );

      if (mounted) {
        setState(() {
          _packedEvents = packedEvents;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      // Add stack trace
      print('EventDisplayWidget: Error fetching events: $e\n$s');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _packedEvents = []; // Clear events on error
        });
      }
    }
  }

  // Removed _waitForBroker method

  @override
  Widget build(BuildContext context) {
    // No LayoutBuilder needed here as EventRenderer uses Size.infinite

    return GestureDetector(
      onTapUp: _handleTap,
      onDoubleTapDown: _handleDoubleTap,
      onLongPressStart: _handleLongPress,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        // Use Stack to potentially overlay loading indicator
        children: [
          // Event renderer
          CustomPaint(
            painter: EventRenderer(
              events: _packedEvents,
              style: widget.renderStyle,
              selectedEventId: _selectedEventId,
              draggedEventId: _draggedEventId,
              resizedEventId: _resizedEventId, // Restore parameter
              activeResizeHandle: _activeResizeHandle, // Restore parameter
              timeFormat: widget.timeFormat,
              // Pass scroll offset if this widget scrolls independently, otherwise 0
              // Assuming parent handles scrolling, pass 0 for now.
              scrollOffset: 0.0,
            ),
            size: Size.infinite, // Allow painter to draw anywhere
          ),
          // Optional: Loading Indicator
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  /// Handle tap events
  void _handleTap(TapUpDetails details) {
    // Use EventRenderer for hit testing
    final renderer = EventRenderer(
        events: _packedEvents,
        scrollOffset: 0.0); // TODO: Pass actual scroll offset if needed
    final eventAtPosition = renderer.findEventAt(details.localPosition);
    if (eventAtPosition != null) {
      setState(() {
        _selectedEventId = eventAtPosition.event.id;
      });
      widget.onEventTap?.call(eventAtPosition.event);
    } else {
      setState(() {
        _selectedEventId = null;
      });
    }
  }

  /// Handle double tap events
  void _handleDoubleTap(TapDownDetails details) {
    if (widget.onEventDoubleTap == null) return;
    // Use EventRenderer for hit testing
    final renderer = EventRenderer(
        events: _packedEvents,
        scrollOffset: 0.0); // TODO: Pass actual scroll offset if needed
    final eventAtPosition = renderer.findEventAt(details.localPosition);
    if (eventAtPosition != null) {
      widget.onEventDoubleTap?.call(eventAtPosition.event);
    }
  }

  /// Handle long press events
  void _handleLongPress(LongPressStartDetails details) {
    if (widget.onEventLongPress == null) return;
    // Use EventRenderer for hit testing
    final renderer = EventRenderer(
        events: _packedEvents,
        scrollOffset: 0.0); // TODO: Pass actual scroll offset if needed
    final eventAtPosition = renderer.findEventAt(details.localPosition);
    if (eventAtPosition != null) {
      widget.onEventLongPress
          ?.call(eventAtPosition.event, details.globalPosition);
    }
  }

  /// Handle pan start events (for drag)
  void _handlePanStart(DragStartDetails details) {
    // Check enable flags first
    if (!widget.enableDrag && !widget.enableResize) return;

    // Check if we're on a resize handle first
    EventRenderer? renderer; // Declare renderer here to potentially reuse

    // Check if we're on a resize handle first
    if (widget.enableResize && _selectedEventId != null) {
      renderer = EventRenderer(
        events: _packedEvents,
        style: widget.renderStyle,
        selectedEventId: _selectedEventId,
        scrollOffset: 0.0, // TODO: Pass actual scroll offset if needed
      );
      final resizeHandleHit =
          renderer.findResizeHandleAt(details.localPosition);
      if (resizeHandleHit != null) {
        setState(() {
          _resizedEventId = resizeHandleHit.event.event.id;
          _activeResizeHandle = resizeHandleHit.handle;
          _originalEvent = resizeHandleHit.event.event;
          _originalStart = _originalEvent!.start; // Store original times
          _originalEnd = _originalEvent!.end;
          _initialDragPosition =
              details.localPosition; // Store initial resize position
        });
        return; // Prioritize resize over drag
      }
    }

    // Check if we're on an event for dragging
    // Create renderer if not already created for resize check
    renderer ??= EventRenderer(
        events: _packedEvents,
        scrollOffset: 0.0); // TODO: Pass actual scroll offset if needed
    final eventAtPosition = renderer.findEventAt(details.localPosition);
    if (eventAtPosition != null) {
      setState(() {
        _draggedEventId = eventAtPosition.event.id;
        _originalEvent = eventAtPosition.event;
        // Calculate offset relative to the event's top-left in the *unscrolled* coordinate system
        // Calculate offset relative to the event's top-left for dragging
        _dragOffset = details.localPosition - eventAtPosition.finalRect.topLeft;
        _originalStart = _originalEvent!.start; // Store original times
        _originalEnd = _originalEvent!.end;
        _initialDragPosition =
            details.localPosition; // Store initial drag position
      });
    }
  }

  /// Handle pan update events (for drag)
  void _handlePanUpdate(DragUpdateDetails details) {
    // Handle resize or drag
    if (_resizedEventId != null &&
        _originalEvent != null &&
        widget.enableResize) {
      _handleResize(details);
    } else if (_draggedEventId != null &&
        _originalEvent != null &&
        widget.enableDrag) {
      _handleDrag(details);
    }
  }

  /// Handle pan end events (for drag)
  void _handlePanEnd(DragEndDetails details) {
    // Handle resize finalization
    if (_resizedEventId != null &&
        _originalEvent != null &&
        _originalStart != null &&
        _originalEnd != null &&
        widget.enableResize) {
      // Find the final updated event from the state
      final finalLayoutInfo = _packedEvents.firstWhere(
        (e) => e.event.id == _resizedEventId,
        // orElse: () => null // Handle case where event might disappear?
      );
      final finalEvent = finalLayoutInfo.event;

      // Call the callback if the time actually changed
      if (finalEvent.start != _originalStart ||
          finalEvent.end != _originalEnd) {
        widget.onEventResize
            ?.call(_originalEvent!, finalEvent.start, finalEvent.end);
      }

      // Clear resize state
      setState(() {
        _resizedEventId = null;
        _activeResizeHandle = null;
        _originalEvent = null;
        _originalStart = null;
        _originalEnd = null;
        _initialDragPosition = null; // Clear initial position
      });
    }
    // Handle drag finalization
    else if (_draggedEventId != null &&
        _originalEvent != null &&
        _originalStart != null &&
        _originalEnd != null &&
        widget.enableDrag) {
      final finalLayoutInfo = _packedEvents.firstWhere(
        (e) => e.event.id == _draggedEventId,
        // orElse: () => null
      );
      final finalEvent = finalLayoutInfo.event;

      // Call callback if the time actually changed
      if (finalEvent.start != _originalStart ||
          finalEvent.end != _originalEnd) {
        widget.onEventMove
            ?.call(_originalEvent!, finalEvent.start, finalEvent.end);
      }

      // Clear drag state
      setState(() {
        _draggedEventId = null;
        _originalEvent = null;
        _dragOffset = null;
        _originalStart = null;
        _originalEnd = null;
        _initialDragPosition = null; // Clear initial position
      });
    }
  }

  /// Handle drag operations
  void _handleDrag(DragUpdateDetails details) {
    if (_draggedEventId == null ||
        _originalEvent == null ||
        _dragOffset == null) return;

    // Calculate new top-left position in the local (potentially scrolled) coordinate system
    final newTopLeft = details.localPosition - _dragOffset!;

    // Convert the new top-left position to a DateTime using the broker
    // This needs the broker and potentially scroll offset if position is viewport-relative
    DateTime? newStartDateTime =
        widget.broker.getDateTimeForPosition(newTopLeft); // Use widget.broker

    if (newStartDateTime == null) return; // Could not convert position

    // TODO: Implement time snapping if needed
    // newStartDateTime = _snapToInterval(newStartDateTime);

    // Calculate new end time based on original duration
    final duration = _originalEnd!.difference(_originalStart!);
    final newEndDateTime = newStartDateTime.add(duration);

    // Create updated event DTO
    final updatedEventData = _originalEvent!.copyWith(
      start: newStartDateTime,
      end: newEndDateTime,
    );

    // --- Re-process layout with the *potential* new position ---
    // Create a temporary list with the updated event data
    final tempEvents = List<CalendarEvent>.from(_packedEvents.map(
        (e) => e.event.id == _draggedEventId ? updatedEventData : e.event));

    // Reprocess layout using the manager, passing the broker instance
    final tempPackedLayouts = _renderingManager.processEvents(
      events: tempEvents,
      minEventSize: widget.minEventSize,
      minSecondarySize: widget.minSecondarySize,
      gridInfo: widget.broker, // Pass broker instance
    );

    // Update the state to show the dragged position visually
    // Check mounted before setState
    if (mounted) {
      setState(() {
        _packedEvents = tempPackedLayouts;
      });
    }
  }

  /// Handle resize operations - Updated for orientation
  void _handleResize(DragUpdateDetails details) {
    if (_resizedEventId == null ||
        _originalEvent == null ||
        _activeResizeHandle == null) return;

    // Find the layout info for the resized event to get orientation
    final eventLayout = _packedEvents.firstWhere(
      (e) => e.event.id == _resizedEventId,
      // orElse: () => null, // Should not happen if _resizedEventId is set
    );
    final orientation = eventLayout.orientation; // Get orientation

    // Convert position to date/time using the broker (needed for horizontal resize)
    final newPosition = details.localPosition;
    final newDateTime =
        widget.broker.getDateTimeForPosition(newPosition); // Use widget.broker

    // Create new event with updated times based on handle and orientation
    CalendarEvent updatedEventData = _originalEvent!; // Start with original

    if (orientation == Axis.vertical) {
      // --- Vertical Resizing: Calculate time delta from position delta ---
      if (_initialDragPosition == null) return; // Should not happen

      final dy = details.localPosition.dy - _initialDragPosition!.dy;
      final totalDurationMs = widget.broker.viewEnd
          .difference(widget.broker.viewStart)
          .inMilliseconds; // Use widget.broker
      final availableHeight =
          widget.broker.availableSpace.height; // Use widget.broker

      if (totalDurationMs <= 0 || availableHeight <= 0)
        return; // Avoid division by zero

      final pixelsPerMs = availableHeight / totalDurationMs;
      final durationDeltaMs = (dy / pixelsPerMs).round();
      final durationDelta = Duration(milliseconds: durationDeltaMs);

      // TODO: Add snapping logic for durationDelta if needed

      if (_activeResizeHandle == ResizeHandle.top) {
        final newStart = _originalStart!.add(durationDelta);
        // Prevent crossing end time (e.g., snap to 15 min before end)
        if (newStart
            .isBefore(_originalEnd!.subtract(const Duration(minutes: 1)))) {
          // Allow getting close
          updatedEventData = _originalEvent!.copyWith(start: newStart);
        } else {
          updatedEventData = _originalEvent!.copyWith(
              start: _originalEnd!.subtract(const Duration(minutes: 15)));
        }
      } else if (_activeResizeHandle == ResizeHandle.bottom) {
        final newEnd = _originalEnd!.add(durationDelta);
        // Prevent crossing start time (e.g., snap to 15 min after start)
        if (newEnd.isAfter(_originalStart!.add(const Duration(minutes: 1)))) {
          // Allow getting close
          updatedEventData = _originalEvent!.copyWith(end: newEnd);
        } else {
          updatedEventData = _originalEvent!
              .copyWith(end: _originalStart!.add(const Duration(minutes: 15)));
        }
      }
    } else {
      // Axis.horizontal
      // --- Horizontal Resizing: Use direct time conversion ---
      if (newDateTime == null) return; // Check if conversion failed

      // Note: getDateTimeForPosition converts based on the view's total duration.
      // This might need adjustment if horizontal resizing should snap differently (e.g., to days).
      if (_activeResizeHandle == ResizeHandle.left) {
        if (newDateTime.isBefore(_originalEnd!)) {
          updatedEventData = _originalEvent!.copyWith(start: newDateTime);
        } else {
          // Prevent crossing end time/date
          updatedEventData = _originalEvent!.copyWith(
              start: _originalEnd!
                  .subtract(const Duration(minutes: 15))); // Or adjust by days?
        }
      } else if (_activeResizeHandle == ResizeHandle.right) {
        if (newDateTime.isAfter(_originalStart!)) {
          updatedEventData = _originalEvent!.copyWith(end: newDateTime);
        } else {
          // Prevent crossing start time/date
          updatedEventData = _originalEvent!.copyWith(
              end: _originalStart!
                  .add(const Duration(minutes: 15))); // Or adjust by days?
        }
      }
    }

    // Update the event in the list visually
    final updatedEvents = List<CalendarEvent>.from(
      _packedEvents.map(
          (e) => e.event.id == _resizedEventId ? updatedEventData : e.event),
    );

    // Reprocess events for visual feedback, passing the broker instance
    final tempPackedLayouts = _renderingManager.processEvents(
      events: updatedEvents,
      minEventSize: widget.minEventSize,
      minSecondarySize: widget.minSecondarySize,
      gridInfo: widget.broker, // Pass broker instance
    );

    if (mounted) {
      setState(() {
        _packedEvents = tempPackedLayouts;
      });
    }
  }

  // Removed local _positionToDateTime method - use broker.getDateTimeForPosition instead
}
