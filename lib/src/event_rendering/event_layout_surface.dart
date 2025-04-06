import 'package:flutter/material.dart';
import 'dart:async'; // Import async for StreamSubscription
import 'package:flutter/gestures.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface_viewmodel.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/event_renderer.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/services/pointer_relay_service.dart'; // Import the relay service
import 'dart:math';

// Define callback type for overflow state
typedef OverflowStateCallback = void Function(
    bool hasOverflow, int hiddenCount, int maxLaneIndex);

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
  final int? maxVisibleAllDayEvents;
  final OverflowStateCallback? onOverflowStateChanged;
  final bool isCollapsed;
  final double? collapsedContentHeight;

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
  });

  @override
  EventLayoutSurfaceState createState() => EventLayoutSurfaceState();
}

class EventLayoutSurfaceState extends State<EventLayoutSurface> {
  // ViewModel
  late EventLayoutSurfaceViewModel _viewModel;

  // Public getter to expose the ViewModel (for height calculation in parent)
  EventLayoutSurfaceViewModel? get viewModelAccessor => _viewModel;

  // Track scroll offset for painting
  double _scrollOffset = 0.0;

  // State for handling relayed pointer events
  StreamSubscription<PointerEvent>? _pointerSubscription;
  int? _activePointerId;
  Object? _dragTarget; // CalendarEvent or ResizeHandleHit
  bool _isDragging = false;
  PointerDownEvent? _pendingTapDown; // Store potential tap start
  DateTime? _tapDownTime; // Store time of potential tap start
  static const Duration _kTapTimeout =
      Duration(milliseconds: 300); // Max duration for a tap
  static const double _kTapSlop = kTouchSlop; // Max movement for a tap

  @override
  void initState() {
    super.initState();

    // Initialize the ViewModel
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
    );

    // Listen for changes in the ViewModel
    _viewModel.addListener(_handleViewModelUpdate);

    // Listen to scroll events (still needed for offset calculation)
    widget.scrollController?.addListener(_handleScroll);
    if (widget.scrollController?.hasClients ?? false) {
      _scrollOffset = widget.scrollController!.position.pixels;
    }

    // Subscribe to the pointer relay service
    _pointerSubscription =
        PointerRelayService.instance.events.listen(_handlePointerEvent);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelUpdate);
    widget.scrollController?.removeListener(_handleScroll);
    _pointerSubscription?.cancel(); // Cancel subscription
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
    }

    // Update ViewModel with new data
    _viewModel.updateVisibleDates(widget.visibleDates);
    _viewModel.updateGridInfo(widget.gridInfo);
    _viewModel.updateMaxVisibleEvents(widget.maxVisibleAllDayEvents);
    _viewModel.updateOverflowCallback(widget.onOverflowStateChanged);
    _viewModel.updateCollapsedState(
        widget.isCollapsed, widget.collapsedContentHeight);
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
    // Use the same renderer setup as in build method for consistency
    final renderer = EventRenderer(
      events: _viewModel.events,
      style: widget.renderStyle,
      selectedEventId: _viewModel.selectedEventId,
      draggedEventId: _viewModel.draggedEventId,
      resizedEventId: _viewModel.resizedEventId,
      activeResizeHandle: _viewModel.activeResizeHandle,
      scrollOffset: _scrollOffset,
      currentDragPosition: _viewModel.currentDragPosition, // Pass drag position
      dragOffset: _viewModel.dragOffset, // Pass drag offset
    );

    final resizeHandleHit = renderer.findResizeHandleAt(event.localPosition);
    if (resizeHandleHit != null) {
      if (resizeHandleHit.event.orientation == Axis.vertical) {
        if (resizeHandleHit.handle == ResizeHandle.top ||
            resizeHandleHit.handle == ResizeHandle.bottom) {
          setState(() {
            _currentCursor = SystemMouseCursors.resizeUpDown;
          });
          return;
        }
      } else {
        if (resizeHandleHit.handle == ResizeHandle.left ||
            resizeHandleHit.handle == ResizeHandle.right) {
          setState(() {
            _currentCursor = SystemMouseCursors.resizeLeftRight;
          });
          return;
        }
      }
    }

    final eventHit = renderer.findEventAt(event.localPosition);
    if (eventHit != null) {
      setState(() {
        _currentCursor = SystemMouseCursors.grab;
      });
      return;
    }

    setState(() {
      _currentCursor = SystemMouseCursors.basic;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Removed MouseRegion and GestureDetector. Events are handled via PointerRelayService.
    // The CustomPaint is now the direct child.
    return CustomPaint(
      painter: EventRenderer(
        events: _viewModel.events,
        style: widget.renderStyle,
        selectedEventId: _viewModel.selectedEventId,
        draggedEventId: _viewModel.draggedEventId,
        resizedEventId: _viewModel.resizedEventId,
        activeResizeHandle: _viewModel.activeResizeHandle,
        scrollOffset: _scrollOffset,
        isCollapsed: widget.isCollapsed,
        collapsedContentHeight: widget.collapsedContentHeight,
        currentDragPosition: _viewModel.currentDragPosition,
        dragOffset: _viewModel.dragOffset,
      ),
      // Ensure the CustomPaint takes up the necessary space
      size: Size.infinite,
    );
  }

  // --- Central Pointer Event Handler ---

  void _handlePointerEvent(PointerEvent event) {
    // Calculate position relative to the EventLayoutSurface's top-left corner,
    // then adjust for scroll offset.
    final Offset surfaceLocalPosition = event.localPosition - widget.gridInfo.origin;
    final Offset adjustedPosition = surfaceLocalPosition + Offset(0, _scrollOffset);

    if (event is PointerDownEvent) {
      // Only handle primary button and if no other pointer is active
      if (event.buttons == kPrimaryMouseButton && _activePointerId == null) {
        // Perform hit test
        final renderer = EventRenderer(
          events: _viewModel.events,
          style: widget.renderStyle,
          selectedEventId: _viewModel.selectedEventId,
          draggedEventId: _viewModel.draggedEventId,
          resizedEventId: _viewModel.resizedEventId,
          activeResizeHandle: _viewModel.activeResizeHandle,
          scrollOffset: _scrollOffset,
          currentDragPosition: _viewModel.currentDragPosition,
          dragOffset: _viewModel.dragOffset,
        );
        final resizeHandleHit = renderer.findResizeHandleAt(adjustedPosition);
        final eventHit = renderer.findEventAt(adjustedPosition);

        if (resizeHandleHit != null || eventHit != null) {
          // Potential drag/resize start
          _activePointerId = event.pointer;
          _dragTarget = resizeHandleHit ?? eventHit;
          _isDragging = false;
          // Record potential tap start
          _pendingTapDown = event;
          _tapDownTime = DateTime.now();
        } else {
          // Click on empty space, clear potential tap
          _pendingTapDown = null;
          _tapDownTime = null;
        }
      }
    } else if (event is PointerMoveEvent) {
      if (event.pointer == _activePointerId) {
        // Check if movement exceeds tap slop, invalidating tap
        if (_pendingTapDown != null) {
          final Offset delta = event.position - _pendingTapDown!.position;
          if (delta.distanceSquared > _kTapSlop * _kTapSlop) {
            // Movement exceeded slop, not a tap
            _pendingTapDown = null;
            _tapDownTime = null;
          }
        }

        // Handle drag/resize
        if (_dragTarget != null) {
          if (!_isDragging) {
            // First move after down on target, start drag/resize
            _isDragging = true;
            // Use the initial down position (adjusted relative to surface) for starting the drag
            final Offset startSurfaceLocalPosition = _pendingTapDown!.localPosition - widget.gridInfo.origin;
            final Offset startPosition = startSurfaceLocalPosition + Offset(0, _scrollOffset);
            _viewModel.handlePanStart(startPosition, _scrollOffset);
            // Update cursor (might need refinement based on target type)
            // TODO: Set grabbing or resize cursor based on _dragTarget type
            // setState(() { _currentCursor = SystemMouseCursors.grabbing; });
          }
          // Continue updating drag/resize
          _viewModel.handlePanUpdate(adjustedPosition, _scrollOffset);
        }
      }
    } else if (event is PointerUpEvent) {
      if (event.pointer == _activePointerId) {
        if (_isDragging) {
          // End drag/resize
          _viewModel.handlePanEnd();
        } else if (_pendingTapDown != null && _tapDownTime != null) {
          // Check if it qualifies as a tap (within time and slop)
          // Use the surface-local position for tap slop calculation
          final Offset downSurfaceLocalPosition = _pendingTapDown!.localPosition - widget.gridInfo.origin;
          final Offset upSurfaceLocalPosition = event.localPosition - widget.gridInfo.origin;
          final Offset delta = upSurfaceLocalPosition - downSurfaceLocalPosition;
          final Duration timeSinceDown = DateTime.now().difference(_tapDownTime!);

          if (timeSinceDown < _kTapTimeout && delta.distanceSquared <= _kTapSlop * _kTapSlop) {
            // It's a tap!
            _viewModel.handleTap(adjustedPosition, _scrollOffset);
          }
        }
        // Reset state
        _resetInteractionState();
      }
    } else if (event is PointerCancelEvent) {
      if (event.pointer == _activePointerId) {
        if (_isDragging) {
          // Cancel drag/resize
          _viewModel.handlePanEnd(); // Or a specific cancel method if available
        }
        // Reset state
        _resetInteractionState();
      }
    } else if (event is PointerHoverEvent) {
      // Update cursor based on hover position if not actively dragging
      if (!_isDragging) {
        _updateCursorOnHover(event);
      }
    }
  }

  void _resetInteractionState() {
    _activePointerId = null;
    _dragTarget = null;
    _isDragging = false;
    _pendingTapDown = null;
    _tapDownTime = null;
    // Reset cursor (MouseRegion would normally handle this, but we removed it)
    // We might need to explicitly set it back based on a final hover check or default
    // setState(() { _currentCursor = SystemMouseCursors.basic; });
    // For now, let _updateCursorOnHover handle subsequent hover events
  }

  // _updateCursorOnHover remains mostly the same, but is now called from _handlePointerEvent
  // Ensure it uses the PointerHoverEvent's localPosition directly
  // void _updateCursorOnHover(PointerHoverEvent event) { ... }

  // Removed old gesture handlers:
  // _handleTap, _handleDoubleTap, _handleLongPress
  // _handlePanStart, _handlePanUpdate, _handlePanEnd
}
