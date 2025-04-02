import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface_viewmodel.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart';

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

  /// Creates a new EventLayoutSurface
  const EventLayoutSurface({
    super.key,
    required this.controller,
    this.renderStyle = const EventRenderStyle(),
    this.minEventSize = 20.0,
    this.minSecondarySize = 20.0,
    this.scrollController,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTap,
      onDoubleTapDown: _handleDoubleTap,
      onLongPressStart: _handleLongPress,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        // Removed debug background color
        child: CustomPaint(
          painter: EventRenderer(
            events: _viewModel.events,
            style: widget.renderStyle,
            selectedEventId: _viewModel.selectedEventId,
            draggedEventId: _viewModel.draggedEventId,
            resizedEventId: _viewModel.resizedEventId,
            activeResizeHandle: _viewModel.activeResizeHandle,
            scrollOffset: _scrollOffset, // Pass the scroll offset to the renderer
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  /// Handle tap events
  void _handleTap(TapUpDetails details) {
    _viewModel.handleTap(details.localPosition);
  }

  /// Handle double tap events
  void _handleDoubleTap(TapDownDetails details) {
    _viewModel.handleDoubleTap(details.localPosition);
  }

  /// Handle long press events
  void _handleLongPress(LongPressStartDetails details) {
    _viewModel.handleLongPress(details.localPosition);
  }

  /// Handle pan start for drag and resize
  void _handlePanStart(DragStartDetails details) {
    _viewModel.handlePanStart(details.localPosition);
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
