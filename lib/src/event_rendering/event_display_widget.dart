import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_info.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart';
import 'package:jazmine_calendar/src/event_rendering/event_rendering_manager.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_broker.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

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

  /// Whether events can be dragged
  final bool enableDrag;

  /// Whether events can be resized
  final bool enableResize;

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
    this.onEventResize,
    this.enableDrag = true,
    this.enableResize = true,
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
  ResizeHandle? _activeResizeHandle;

  /// Drag offset for calculating position
  Offset? _dragOffset;

  /// Event rendering manager
  final EventRenderingManager _renderingManager = EventRenderingManager();

  /// Grid layout broker
  final GridLayoutBroker _broker = GridLayoutBroker();

  @override
  void initState() {
    super.initState();
    print('EventDisplayWidget: initState');
    widget.controller.addListener(_handleControllerUpdate);
    // Check if broker is ready
    print('EventDisplayWidget: Broker ready: ${_broker.isReady}');
    if (_broker.isReady) {
      print(
          'EventDisplayWidget: Broker viewStart: ${_broker.viewStart}, viewEnd: ${_broker.viewEnd}');
    }
    _fetchAndProcessEvents();
  }

  @override
  void didUpdateWidget(EventDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerUpdate);
      widget.controller.addListener(_handleControllerUpdate);
    }

    if (oldWidget.renderStyle != widget.renderStyle ||
        oldWidget.minEventSize != widget.minEventSize ||
        oldWidget.minSecondarySize != widget.minSecondarySize) {
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
    print('EventDisplayWidget: Controller update received');
    print(
        'EventDisplayWidget: Events changed: ${widget.controller.eventsChanged}');

    // Only reprocess events if the events have changed
    if (widget.controller.eventsChanged) {
      print(
          'EventDisplayWidget: Events changed, clearing cache and fetching events');
      _renderingManager.clearCache();
      _fetchAndProcessEvents();
    } else {
      print('EventDisplayWidget: Events not changed, skipping fetch');
    }
  }

  /// Fetch and process events
  Future<void> _fetchAndProcessEvents() async {
    if (_isLoading) {
      print('EventDisplayWidget: Loading in progress');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get events from the rendering manager
      print('EventDisplayWidget: Fetching events from rendering manager');
      final packedEvents = await _renderingManager.fetchAndProcessEvents(
        controller: widget.controller,
        minEventSize: widget.minEventSize,
        minSecondarySize: widget.minSecondarySize,
      );


      if (mounted) {
        setState(() {
          _packedEvents = packedEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('EventDisplayWidget: Error fetching events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('EventDisplayWidget: Building with ${_packedEvents.length} events');
    return LayoutBuilder(
      builder: (context, constraints) {
        print('EventDisplayWidget: LayoutBuilder constraints: $constraints');
        // If size changed significantly, reprocess events with new size
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_broker.isReady) {
            print(
                'EventDisplayWidget: Broker not ready in post-frame callback');
            _fetchAndProcessEvents();
          } else {
            print('EventDisplayWidget: Broker is ready in post-frame callback');
          }
        });

        return GestureDetector(
          onTapUp: _handleTap,
          onDoubleTapDown: _handleDoubleTap,
          onLongPressStart: _handleLongPress,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: Stack(
            children: [
              // Debug overlay
              Container(
                color: Colors.yellow.withOpacity(0.1),
                child: Center(
                  child: Text('Events: ${_packedEvents.length}'),
                ),
              ),
              // Event renderer
              CustomPaint(
                painter: EventRenderer(
                  events: _packedEvents,
                  style: widget.renderStyle,
                  selectedEventId: _selectedEventId,
                  draggedEventId: _draggedEventId,
                  resizedEventId: _resizedEventId,
                  activeResizeHandle: _activeResizeHandle,
                  timeFormat: widget.timeFormat,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handle tap events
  void _handleTap(TapUpDetails details) {
    final renderer = EventRenderer(
      events: _packedEvents,
      style: widget.renderStyle,
    );

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

    final renderer = EventRenderer(
      events: _packedEvents,
      style: widget.renderStyle,
    );

    final eventAtPosition = renderer.findEventAt(details.localPosition);

    if (eventAtPosition != null) {
      widget.onEventDoubleTap?.call(eventAtPosition.event);
    }
  }

  /// Handle long press events
  void _handleLongPress(LongPressStartDetails details) {
    if (widget.onEventLongPress == null) return;

    final renderer = EventRenderer(
      events: _packedEvents,
      style: widget.renderStyle,
    );

    final eventAtPosition = renderer.findEventAt(details.localPosition);

    if (eventAtPosition != null) {
      widget.onEventLongPress
          ?.call(eventAtPosition.event, details.globalPosition);
    }
  }

  /// Handle pan start events (for drag and resize)
  void _handlePanStart(DragStartDetails details) {
    if (!widget.enableDrag && !widget.enableResize) return;

    final renderer = EventRenderer(
      events: _packedEvents,
      style: widget.renderStyle,
      selectedEventId: _selectedEventId,
    );

    // Check if we're on a resize handle
    if (widget.enableResize && _selectedEventId != null) {
      final resizeHandleHit =
          renderer.findResizeHandleAt(details.localPosition);

      if (resizeHandleHit != null) {
        setState(() {
          _resizedEventId = resizeHandleHit.event.event.id;
          _activeResizeHandle = resizeHandleHit.handle;
          _originalEvent = resizeHandleHit.event.event;
        });
        return;
      }
    }

    // Check if we're on an event for dragging
    if (widget.enableDrag) {
      final eventAtPosition = renderer.findEventAt(details.localPosition);

      if (eventAtPosition != null) {
        setState(() {
          _draggedEventId = eventAtPosition.event.id;
          _originalEvent = eventAtPosition.event;
          _dragOffset =
              details.localPosition - eventAtPosition.finalRect.topLeft;
        });
      }
    }
  }

  /// Handle pan update events (for drag and resize)
  void _handlePanUpdate(DragUpdateDetails details) {
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

  /// Handle pan end events (for drag and resize)
  void _handlePanEnd(DragEndDetails details) {
    if (_resizedEventId != null &&
        _originalEvent != null &&
        widget.enableResize) {
      // Finalize resize
      final event = _packedEvents
          .firstWhere(
            (e) => e.event.id == _resizedEventId,
            orElse: () => _packedEvents.first,
          )
          .event;

      widget.onEventResize?.call(_originalEvent!, event.start, event.end);

      setState(() {
        _resizedEventId = null;
        _activeResizeHandle = null;
        _originalEvent = null;
      });
    } else if (_draggedEventId != null &&
        _originalEvent != null &&
        widget.enableDrag) {
      // Finalize drag
      final event = _packedEvents
          .firstWhere(
            (e) => e.event.id == _draggedEventId,
            orElse: () => _packedEvents.first,
          )
          .event;

      widget.onEventMove?.call(_originalEvent!, event.start, event.end);

      setState(() {
        _draggedEventId = null;
        _originalEvent = null;
        _dragOffset = null;
      });
    }
  }

  /// Handle drag operations
  void _handleDrag(DragUpdateDetails details) {
    if (_draggedEventId == null ||
        _originalEvent == null ||
        _dragOffset == null) return;

    // Find the dragged event
    final eventIndex =
        _packedEvents.indexWhere((e) => e.event.id == _draggedEventId);
    if (eventIndex == -1) return;

    // Calculate new position
    final newPosition = details.localPosition - _dragOffset!;

    // Convert position to date/time
    final newDateTime = _positionToDateTime(newPosition);
    if (newDateTime == null) return;

    // Calculate duration
    final duration = _originalEvent!.end.difference(_originalEvent!.start);

    // Create new event with updated times
    final updatedEvent = CalendarEvent(
      id: _originalEvent!.id,
      title: _originalEvent!.title,
      description: _originalEvent!.description,
      start: newDateTime,
      end: newDateTime.add(duration),
      color: _originalEvent!.color,
      location: _originalEvent!.location,
      timeZone: _originalEvent!.timeZone,
      isAllDay: _originalEvent!.isAllDay,
      recurrenceType: _originalEvent!.recurrenceType,
      recurrenceRule: _originalEvent!.recurrenceRule,
      resourceIds: _originalEvent!.resourceIds,
    );

    // Update the event in the list
    final updatedEvents = List<CalendarEvent>.from(
      _packedEvents
          .map((e) => e.event.id == _draggedEventId ? updatedEvent : e.event),
    );

    // Reprocess events
    final packedEvents = _renderingManager.processEvents(
      events: updatedEvents,
      minEventSize: widget.minEventSize,
      minSecondarySize: widget.minSecondarySize,
    );

    setState(() {
      _packedEvents = packedEvents;
    });
  }

  /// Handle resize operations
  void _handleResize(DragUpdateDetails details) {
    if (_resizedEventId == null ||
        _originalEvent == null ||
        _activeResizeHandle == null) return;

    // Find the resized event
    final eventIndex =
        _packedEvents.indexWhere((e) => e.event.id == _resizedEventId);
    if (eventIndex == -1) return;

    // Calculate new position
    final newPosition = details.localPosition;

    // Convert position to date/time
    final newDateTime = _positionToDateTime(newPosition);
    if (newDateTime == null) return;

    // Create new event with updated times
    CalendarEvent updatedEvent;

    if (_activeResizeHandle == ResizeHandle.top) {
      // Resizing from the top (changing start time)
      updatedEvent = CalendarEvent(
        id: _originalEvent!.id,
        title: _originalEvent!.title,
        description: _originalEvent!.description,
        start: newDateTime,
        end: _originalEvent!.end,
        color: _originalEvent!.color,
        location: _originalEvent!.location,
        timeZone: _originalEvent!.timeZone,
        isAllDay: _originalEvent!.isAllDay,
        recurrenceType: _originalEvent!.recurrenceType,
        recurrenceRule: _originalEvent!.recurrenceRule,
        resourceIds: _originalEvent!.resourceIds,
      );
    } else {
      // Resizing from the bottom (changing end time)
      updatedEvent = CalendarEvent(
        id: _originalEvent!.id,
        title: _originalEvent!.title,
        description: _originalEvent!.description,
        start: _originalEvent!.start,
        end: newDateTime,
        color: _originalEvent!.color,
        location: _originalEvent!.location,
        timeZone: _originalEvent!.timeZone,
        isAllDay: _originalEvent!.isAllDay,
        recurrenceType: _originalEvent!.recurrenceType,
        recurrenceRule: _originalEvent!.recurrenceRule,
        resourceIds: _originalEvent!.resourceIds,
      );
    }

    // Update the event in the list
    final updatedEvents = List<CalendarEvent>.from(
      _packedEvents
          .map((e) => e.event.id == _resizedEventId ? updatedEvent : e.event),
    );

    // Reprocess events
    final packedEvents = _renderingManager.processEvents(
      events: updatedEvents,
      minEventSize: widget.minEventSize,
      minSecondarySize: widget.minSecondarySize,
    );

    setState(() {
      _packedEvents = packedEvents;
    });
  }

  /// Convert a position to a date/time
  DateTime? _positionToDateTime(Offset position) {
    if (!_broker.isReady) return null;

    final totalDuration =
        _broker.viewEnd.difference(_broker.viewStart).inMilliseconds;

    if (_broker.orientation == Axis.vertical) {
      // For vertical orientation, Y position determines time
      final availableHeight = _broker.availableSpace.height;
      final relativeY = position.dy - _broker.origin.dy;

      if (relativeY < 0 || relativeY > availableHeight) return null;

      final fraction = relativeY / availableHeight;
      final milliseconds = (fraction * totalDuration).round();

      return _broker.viewStart.add(Duration(milliseconds: milliseconds));
    } else {
      // For horizontal orientation, X position determines time
      final availableWidth = _broker.availableSpace.width;
      final relativeX = position.dx - _broker.origin.dx;

      if (relativeX < 0 || relativeX > availableWidth) return null;

      final fraction = relativeX / availableWidth;
      final milliseconds = (fraction * totalDuration).round();

      return _broker.viewStart.add(Duration(milliseconds: milliseconds));
    }
  }
}
