import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface_viewmodel.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'dart:math'; // For max in ViewModel calculation

// Define callback type for overflow state
typedef OverflowStateCallback = void Function(bool hasOverflow, int hiddenCount, int maxLaneIndex);

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
  final int? maxVisibleAllDayEvents; // Needed for ViewModel -> Packer
  final OverflowStateCallback? onOverflowStateChanged; // New callback
  final bool isCollapsed; // New parameter for filtering
  final double? collapsedContentHeight; // New parameter for filtering
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
    this.onOverflowStateChanged, // Add to constructor
    this.isCollapsed = false, // Default to false
    this.collapsedContentHeight,
  });

  @override
  EventLayoutSurfaceState createState() => EventLayoutSurfaceState();
}

class EventLayoutSurfaceState extends State<EventLayoutSurface> {
  // ViewModel
  late EventLayoutSurfaceViewModel _viewModel;
  // Public getter to expose the ViewModel (still needed for height calculation in parent)
  EventLayoutSurfaceViewModel? get viewModelAccessor => _viewModel;

  // Track scroll offset for painting
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _viewModel = EventLayoutSurfaceViewModel(
      controller: widget.controller,
      minEventSize: widget.minEventSize,
      minSecondarySize: widget.minSecondarySize,
      isAllDay: widget.isAllDay,
      visibleDates: widget.visibleDates,
      gridInfo: widget.gridInfo,
      renderStyle: widget.renderStyle,
      maxVisibleAllDayEvents: widget.maxVisibleAllDayEvents, // Pass down
      // Pass the callback to the ViewModel
      onOverflowStateChanged: widget.onOverflowStateChanged,
      // Pass new parameters to ViewModel
      isCollapsed: widget.isCollapsed,
      collapsedContentHeight: widget.collapsedContentHeight,
    );

    // Listen for changes in the ViewModel
    _viewModel.addListener(_handleViewModelUpdate);

    // Listen to scroll events if a controller is provided
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_handleScroll);
      if (widget.scrollController!.hasClients) {
        _scrollOffset = widget.scrollController!.position.pixels;
      }
    }
     // Initial calculation after first frame (ViewModel handles this now)
     // WidgetsBinding.instance.addPostFrameCallback((_) => _notifyMaxLaneIndex());
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelUpdate);
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
      if (_scrollOffset != newOffset) {
        setState(() { _scrollOffset = newOffset; });
      }
    }
  }

  @override
  void didUpdateWidget(EventLayoutSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController?.removeListener(_handleScroll);
      widget.scrollController?.addListener(_handleScroll);
      _scrollOffset = widget.scrollController?.hasClients ?? false
          ? widget.scrollController!.position.pixels
          : 0.0;
    }
    // Update ViewModel with potentially new data
    _viewModel.updateVisibleDates(widget.visibleDates); // Add this line
    _viewModel.updateGridInfo(widget.gridInfo);
    _viewModel.updateMaxVisibleEvents(widget.maxVisibleAllDayEvents);
    // Update the callback reference in the ViewModel if it changed
    _viewModel.updateOverflowCallback(widget.onOverflowStateChanged);
    // Update ViewModel with new collapsed state if it changed
    _viewModel.updateCollapsedState(widget.isCollapsed, widget.collapsedContentHeight);
  }

  /// Handle updates from the ViewModel
  void _handleViewModelUpdate() {
    // Force a rebuild when the ViewModel changes
    // The ViewModel itself will now trigger the callback after processing
    setState(() {});
  }

  // Removed _notifyMaxLaneIndex helper method


  // Track current mouse cursor
  MouseCursor _currentCursor = SystemMouseCursors.basic;

  /// Update cursor based on what's under the mouse pointer
  void _updateCursorOnHover(PointerHoverEvent event) {
    final renderer = EventRenderer(
      events: _viewModel.events,
      style: widget.renderStyle,
      selectedEventId: _viewModel.selectedEventId,
      draggedEventId: _viewModel.draggedEventId,
      resizedEventId: _viewModel.resizedEventId,
      activeResizeHandle: _viewModel.activeResizeHandle,
      scrollOffset: _scrollOffset,
    );

    final resizeHandleHit = renderer.findResizeHandleAt(event.localPosition);
    if (resizeHandleHit != null) {
      if (resizeHandleHit.event.orientation == Axis.vertical) {
        if (resizeHandleHit.handle == ResizeHandle.top || resizeHandleHit.handle == ResizeHandle.bottom) {
          setState(() { _currentCursor = SystemMouseCursors.resizeUpDown; }); return;
        }
      } else {
        if (resizeHandleHit.handle == ResizeHandle.left || resizeHandleHit.handle == ResizeHandle.right) {
          setState(() { _currentCursor = SystemMouseCursors.resizeLeftRight; }); return;
        }
      }
    }

    final eventHit = renderer.findEventAt(event.localPosition);
    if (eventHit != null) {
      setState(() { _currentCursor = SystemMouseCursors.grab; }); return;
    }

    setState(() { _currentCursor = SystemMouseCursors.basic; });
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
          margin: const EdgeInsets.only(right: 10.0),
          child: CustomPaint(
            painter: EventRenderer(
              events: _viewModel.events,
              style: widget.renderStyle,
              selectedEventId: _viewModel.selectedEventId,
              draggedEventId: _viewModel.draggedEventId,
              resizedEventId: _viewModel.resizedEventId,
              activeResizeHandle: _viewModel.activeResizeHandle,
              scrollOffset: _scrollOffset,
              // Pass new parameters to Renderer
              isCollapsed: widget.isCollapsed,
              collapsedContentHeight: widget.collapsedContentHeight,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  /// Handle tap events
  void _handleTap(TapUpDetails details) {
    // Regular event tap handling
    _viewModel.handleTap(details.localPosition, _scrollOffset);
  }

  // ... other handlers remain the same ...
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
