import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface_viewmodel.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';

/// Widget that renders calendar events using a CustomPainter
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

  /// Creates a new EventLayoutSurface
  const EventLayoutSurface({
    super.key,
    required this.controller,
    this.renderStyle = const EventRenderStyle(),
    this.minEventSize = 20.0,
    this.minSecondarySize = 20.0,
    this.scrollController,
    this.isAllDay = false, // Default to false for the main grid
    required this.visibleDates,
    required this.gridInfo, // Add orientation parameter
  });

  @override
  EventLayoutSurfaceState createState() => EventLayoutSurfaceState();
}

class EventLayoutSurfaceState extends State<EventLayoutSurface> {
  // ViewModel
  late EventLayoutSurfaceViewModel _viewModel;

  // Track scroll offset for painting
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _viewModel = EventLayoutSurfaceViewModel(
      controller: widget.controller,
      minEventSize: widget.minEventSize,
      minSecondarySize: widget.minSecondarySize,
      isAllDay: widget.isAllDay, // Pass from widget
      visibleDates: widget.visibleDates,
      gridInfo: widget.gridInfo, // Pass from widget
// Pass orientation to ViewModel
    );

    // Listen for changes in the ViewModel
    _viewModel.addListener(_handleViewModelUpdate);

    // Listen to scroll events if a controller is provided
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_handleScroll);
      // Initialize with current scroll position if available
      if (widget.scrollController!.hasClients) {
        _scrollOffset = widget.scrollController!.position.pixels;
      }
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelUpdate);

    // Remove scroll listener
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_handleScroll);
    }

    _viewModel.dispose();
    super.dispose();
  }

  /// Handle scroll events
  void _handleScroll() {
    if (widget.scrollController != null &&
        widget.scrollController!.hasClients) {
      final newOffset = widget.scrollController!.position.pixels;

      // Only update if the offset has changed
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

    // Update scroll controller if it changed
    if (widget.scrollController != oldWidget.scrollController) {
      if (oldWidget.scrollController != null) {
        oldWidget.scrollController!.removeListener(_handleScroll);
      }
      if (widget.scrollController != null) {
        widget.scrollController!.addListener(_handleScroll);
        // Initialize with current scroll position if available
        if (widget.scrollController!.hasClients) {
          _scrollOffset = widget.scrollController!.position.pixels;
        }
      }
    }
  }

  /// Handle updates from the ViewModel
  void _handleViewModelUpdate() {
    // Force a rebuild when the ViewModel changes
    setState(() {});
  }

  // Track current mouse cursor
  MouseCursor _currentCursor = SystemMouseCursors.basic;

  /// Update cursor based on what's under the mouse pointer
  void _updateCursorOnHover(PointerHoverEvent event) {
    // Get the event renderer from the CustomPaint
    final renderer = EventRenderer(
      events: _viewModel.events,
      style: widget.renderStyle,
      selectedEventId: _viewModel.selectedEventId,
      draggedEventId: _viewModel.draggedEventId,
      resizedEventId: _viewModel.resizedEventId,
      activeResizeHandle: _viewModel.activeResizeHandle,
      scrollOffset: _scrollOffset,
    );

    // Check if we're hovering over a resize handle
    final resizeHandleHit = renderer.findResizeHandleAt(event.localPosition);

    if (resizeHandleHit != null) {
      // Set cursor based on the orientation and handle type
      if (resizeHandleHit.event.orientation == Axis.vertical) {
        // Vertical orientation: top/bottom handles
        if (resizeHandleHit.handle == ResizeHandle.top ||
            resizeHandleHit.handle == ResizeHandle.bottom) {
          setState(() {
            _currentCursor = SystemMouseCursors.resizeUpDown;
          });
          return;
        }
      } else {
        // Horizontal orientation: left/right handles
        if (resizeHandleHit.handle == ResizeHandle.left ||
            resizeHandleHit.handle == ResizeHandle.right) {
          setState(() {
            _currentCursor = SystemMouseCursors.resizeLeftRight;
          });
          return;
        }
      }
    }

    // Check if we're hovering over an event (for dragging)
    final eventHit = renderer.findEventAt(event.localPosition);
    if (eventHit != null) {
      setState(() {
        _currentCursor = SystemMouseCursors.grab;
      });
      return;
    }

    // Default cursor
    setState(() {
      _currentCursor = SystemMouseCursors.basic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _updateCursorOnHover,
      cursor: _currentCursor,
      child: GestureDetector(
        onTapUp: _handleTap,
        onDoubleTapDown: _handleDoubleTap,
        onLongPressStart: _handleLongPress,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: Container(
          // Add right margin of 10 pixels
          margin: const EdgeInsets.only(right: 10.0),
          child: CustomPaint(
            painter: EventRenderer(
              events: _viewModel.events,
              style: widget.renderStyle,
              selectedEventId: _viewModel.selectedEventId,
              draggedEventId: _viewModel.draggedEventId,
              resizedEventId: _viewModel.resizedEventId, // Restore parameter
              activeResizeHandle:
                  _viewModel.activeResizeHandle, // Restore parameter
              scrollOffset:
                  _scrollOffset, // Pass the scroll offset to the renderer
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  /// Handle tap events
  void _handleTap(TapUpDetails details) {
    _viewModel.handleTap(details.localPosition, _scrollOffset);
  }

  /// Handle double tap events
  void _handleDoubleTap(TapDownDetails details) {
    _viewModel.handleDoubleTap(details.localPosition, _scrollOffset);
  }

  /// Handle long press events
  void _handleLongPress(LongPressStartDetails details) {
    _viewModel.handleLongPress(details.localPosition, _scrollOffset);
  }

  /// Handle pan start for drag and resize
  void _handlePanStart(DragStartDetails details) {
    _viewModel.handlePanStart(details.localPosition, _scrollOffset);
  }

  /// Handle pan update for drag and resize
  void _handlePanUpdate(DragUpdateDetails details) {
    _viewModel.handlePanUpdate(details.localPosition);
  }

  /// Handle pan end for drag and resize
  void _handlePanEnd(DragEndDetails details) {
    _viewModel.handlePanEnd();
  }
}
