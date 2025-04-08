import 'dart:math';
import 'dart:io' show Platform; // For platform check
import 'package:flutter/foundation.dart' show kIsWeb; // For web check

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface.dart'; // Import for EventLayoutSurfaceState and callback
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/services/calendar_view_service.dart';
// Removed PointerRelayService import
import 'package:jazmine_calendar/src/utils/typedefs.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_time_slot.dart';
import 'package:jazmine_calendar/src/views/widgets/current_time_indicator.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';

class _CalendarGridItem extends StatefulWidget {
  final int index;
  final bool isVertical;
  final double slotWidth;
  final double slotHeight;
  final Widget Function(int, bool, double, double) buildHeader;
  final List<Widget> Function(int, bool) buildSlots;

  const _CalendarGridItem({
    required this.index,
    required this.isVertical,
    required this.slotWidth,
    required this.slotHeight,
    required this.buildHeader,
    required this.buildSlots,
  });

  @override
  State<_CalendarGridItem> createState() => _CalendarGridItemState();
}

class _CalendarGridItemState extends State<_CalendarGridItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RepaintBoundary(
      child: SizedBox(
        width: widget.isVertical ? widget.slotWidth : null,
        height: widget.isVertical ? widget.slotHeight : null,
        child: Flex(
          direction: widget.isVertical ? Axis.horizontal : Axis.vertical,
          children: [
            widget.buildHeader(widget.index, widget.isVertical,
                widget.slotWidth, widget.slotHeight),
            ...widget.buildSlots(widget.index, widget.isVertical),
          ],
        ),
      ),
    );
  }
}

class CalendarGrid extends StatefulWidget {
  final Duration slotDuration;
  final Duration intervalDuration;
  final Axis orientation;
  final int numberOfColumns;
  final int numberOfRows;
  final double minCellWidth = 60;
  final double minCellHeight = 40;
  final DateFormat headerDateFormat;
  final CalendarController controller;
  final Widget Function(BuildContext, DateTime, bool, double, double)?
      headerBuilder;
  final CellBuilder? cellBuilder;
  final double rowHeaderWidth;
  final double columnHeaderHeight;
  final bool showCurrentTimeIndicator;
  final double gridLineWidth;
  final bool isAllDay;
  final bool showEvents;
  final List<DateTime> dates;
  final int? maxVisibleAllDayEvents; // Keep for passing down
  final GlobalKey? eventLayoutSurfaceKey; // Keep key
  final OverflowStateCallback? onOverflowStateChanged; // Add callback
  final bool isCollapsed; // New parameter for filtering
  final double? collapsedContentHeight; // New parameter for filtering
  final void Function(DateTime startTime)?
      onTimeSlotCreateInteraction; // Callback from JazmineCalendar

  const CalendarGrid({
    super.key,
    required this.controller,
    required this.dates,
    required this.headerDateFormat,
    this.slotDuration = const Duration(days: 1),
    this.intervalDuration = const Duration(minutes: 30),
    this.orientation = Axis.vertical,
    required this.numberOfColumns,
    required this.numberOfRows,
    this.headerBuilder,
    this.cellBuilder,
    this.rowHeaderWidth = 0.0,
    this.columnHeaderHeight = 0.0,
    this.showCurrentTimeIndicator = true,
    this.gridLineWidth = 1.0,
    this.isAllDay = false,
    this.showEvents = true,
    this.maxVisibleAllDayEvents,
    this.eventLayoutSurfaceKey,
    this.onOverflowStateChanged, // Add to constructor
    this.isCollapsed = false, // Default to false (not collapsed)
    this.collapsedContentHeight,
    this.onTimeSlotCreateInteraction, // Add this line
  });

  get startDate => dates.first;
  get endDate => dates.last;

  /// Scrolls the grid to show the specified time
  static void scrollToTime(BuildContext context, DateTime time) {
    final state = context.findAncestorStateOfType<CalendarGridState>();
    state?._scrollToTime(time);
  }

  @override
  State<CalendarGrid> createState() => CalendarGridState();
}

class CalendarGridState extends State<CalendarGrid> {
  late ScrollController _scrollController;
  final _viewService = CalendarViewService();
  // Removed _gridInfo field, it will be created within LayoutBuilder

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Removed _gridInfo initialization
  }

  @override
  void didUpdateWidget(CalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _viewService.markInitialScrollApplied(widget.controller.currentView);
    _scrollController.dispose();
    super.dispose();
  }

  // Removed _updateGridLayoutInfo method

  void _scrollToTime(DateTime time, {bool? animate}) {
    if (!mounted || !_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTime(time, animate: animate);
      });
      return;
    }

    final shouldAnimate = animate ?? widget.controller.animateTimeScroll;
    final totalMinutesSinceStart = (time.hour * 60 + time.minute);
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    // Avoid division by zero if maxScrollExtent is 0
    final scrollOffset = maxScrollExtent > 0
        ? (totalMinutesSinceStart / (24 * 60)) * maxScrollExtent
        : 0.0;

    if (shouldAnimate) {
      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(scrollOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVertical = widget.orientation == Axis.vertical;
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        final availableWidth =
            isVertical ? totalWidth - widget.rowHeaderWidth : totalWidth;
        final availableHeight =
            isVertical ? totalHeight : totalHeight - widget.columnHeaderHeight;
        final slotWidth =
            max(widget.minCellWidth, availableWidth / widget.numberOfColumns);
        final slotHeight =
            max(widget.minCellHeight, availableHeight / widget.numberOfRows);
        final gridOrigin = Offset(widget.rowHeaderWidth, widget.columnHeaderHeight); // Renamed to avoid conflict

        // Create immutable GridLayoutInfo instance here
        final gridInfo = GridLayoutInfo(
          viewStart: widget.dates.first, // Use local time for view boundaries
          viewEnd: widget.dates.last.dayEnds,
          origin: gridOrigin,
          availableSpace: Size(availableWidth, availableHeight), // Use calculated available space
          orientation: widget.orientation,
          divisions: widget.dates.length, // Assuming divisions match dates length
          cellWidth: slotWidth,
          cellHeight: slotHeight,
          intervalDuration: widget.intervalDuration,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              widget.controller.currentView != CalendarViewType.month &&
              !_viewService
                  .hasInitialScrollBeenApplied(widget.controller.currentView)) {
            if (widget.controller.scrollToCurrentTimeOnLoad) {
              _scrollToTime(DateTime.now(),
                  animate: widget.controller.animateTimeScroll);
            } else {
              final defaultTime =
                  widget.controller.getStartTimeForDay(widget.startDate);
              final scrollTime = DateTime(
                widget.startDate.year,
                widget.startDate.month,
                widget.startDate.day,
                defaultTime.hour,
                defaultTime.minute,
              );
              _scrollToTime(scrollTime,
                  animate: widget.controller.animateTimeScroll);
            }
            _viewService
                .markInitialScrollApplied(widget.controller.currentView);
          }
        });

        final itemCount =
            isVertical ? widget.numberOfRows : widget.numberOfColumns;
        final itemExtent = isVertical ? slotHeight : slotWidth;

        // Calculate the height for the Positioned EventLayoutSurface
        final double eventSurfaceHeight = availableHeight;

        // Return the Stack directly, as DragTarget/LongPressDraggable are in EventLayoutSurface
        return Stack(
          children: [
            // 1. Scrollable Grid Content
            CustomScrollView(
              key: PageStorageKey(CalendarViewService()
                  .getScrollStorageKey(widget.controller.currentView)),
              controller: _scrollController,
              scrollDirection: widget.orientation,
              slivers: [
                SliverFixedExtentList(
                  itemExtent: itemExtent,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return RepaintBoundary(
                        child: SizedBox(
                          width: isVertical ? slotWidth : null,
                          height: isVertical ? slotHeight : null,
                          child: Flex(
                            direction:
                                isVertical ? Axis.horizontal : Axis.vertical,
                            children: [
                              _buildHeader(gridInfo, // Pass gridInfo
                                  index, isVertical, slotWidth, slotHeight),
                              ..._buildCells(gridInfo, index, isVertical), // Pass gridInfo
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: itemCount,
                    addAutomaticKeepAlives: false, // Consider performance
                    addRepaintBoundaries: true, // Consider performance
                  ),
                ),
              ],
            ),

            // 2. Event Rendering Surface
            if (widget.showEvents)
              Positioned(
                left: gridOrigin.dx, // Corrected: Use gridOrigin
                top: widget.isAllDay
                    ? gridOrigin.dy + 5.0 // Corrected: Use gridOrigin
                    : gridOrigin.dy, // Corrected: Use gridOrigin
                width: availableWidth,
                height: eventSurfaceHeight,
                child: RepaintBoundary(
                  child: EventLayoutSurface(
                    key: widget.eventLayoutSurfaceKey,
                    controller: widget.controller,
                    scrollController: _scrollController,
                    gridInfo: gridInfo, // Pass the new immutable instance
                    isAllDay: widget.isAllDay,
                    visibleDates: widget.dates,
                    renderStyle: EventRenderStyle( // Example style
                      defaultEventColor: Theme.of(context).primaryColor,
                      titleStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ) ??
                              const TextStyle(color: Colors.white),
                    ),
                    maxVisibleAllDayEvents: widget.maxVisibleAllDayEvents,
                    onOverflowStateChanged: widget.onOverflowStateChanged,
                    isCollapsed: widget.isCollapsed,
                    collapsedContentHeight: widget.collapsedContentHeight,
                    snapToIntervalOnDrop: true, // Pass flag
                  ),
                ),
              ),

            // 3. Current Time Indicator
            if (widget.showCurrentTimeIndicator)
              CurrentTimeIndicator(
                scrollController: _scrollController,
                orientation: widget.orientation == Axis.vertical
                    ? Axis.horizontal
                    : Axis.vertical,
                headerOffset: isVertical
                    ? widget.rowHeaderWidth
                    : widget.columnHeaderHeight,
                availableSpace: isVertical ? availableHeight : availableWidth,
                startDate: widget.startDate,
                endDate: widget.endDate,
                controller: widget.controller,
                autoScroll: true, // Consider making this configurable
                intervalPixels: isVertical ? slotHeight : slotWidth,
                slotWidth: slotWidth,
              ),
          ],
        ); // End Stack
      }, // End LayoutBuilder builder
    ); // End LayoutBuilder
  } // End build method

  Widget _buildHeader(GridLayoutInfo gridInfo, // Accept gridInfo
      int index, bool isVertical, double slotWidth, double slotHeight) {

    // Use the passed gridInfo instance
    final headerDate = gridInfo.viewStart.add(widget.intervalDuration * index);

    if (widget.headerBuilder != null) {
      return widget.headerBuilder!(
        context,
        headerDate,
        isVertical,
        isVertical ? widget.rowHeaderWidth : slotWidth,
        isVertical ? slotHeight : widget.columnHeaderHeight,
      );
    }

    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final gridLineWidth = widget.gridLineWidth;

    return Container(
      width: isVertical ? widget.rowHeaderWidth : slotWidth,
      height: isVertical ? slotHeight : widget.columnHeaderHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: calendarTheme?.getSlotBackgroundColor(context),
        border: Border(
          bottom: BorderSide(
            color: calendarTheme?.getGridLineColor(context) ??
                Colors.grey.withOpacity(0.2),
            width: gridLineWidth,
          ),
          right: BorderSide(
            color: calendarTheme?.getGridLineColor(context) ??
                Colors.grey.withOpacity(0.2),
            width: gridLineWidth,
          ),
        ),
      ),
      child: Text(
        widget.headerDateFormat.format(headerDate.toLocal()),
        style: calendarTheme?.getTimeTextStyle(context),
      ),
    );
  }

  List<Widget> _buildCells(GridLayoutInfo gridInfo, int index, bool isVertical) { // Accept gridInfo
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final gridLineWidth = widget.gridLineWidth;

    final gridLineColor = calendarTheme?.getGridLineColor(context) ??
        (theme.brightness == Brightness.light
            ? Colors.grey.withOpacity(0.2)
            : Colors.grey.withOpacity(0.3));
    var slotCount = widget.numberOfColumns;
    // This logic seems potentially problematic if numberOfColumns != dates.length
    // Let's assume numberOfColumns represents the divisions for the current view axis
    // if (slotCount == widget.dates.length) {
    //   slotCount = 1;
    // }
    // final dateIndexMultiplier = slotCount == widget.dates.length ? 0 : index;

    // Simplified logic: Assume each cell corresponds to a date index if vertical
    final int columnsToGenerate = isVertical ? widget.numberOfColumns : 1;

    return List.generate(columnsToGenerate, (slotIndex) {
      // Determine the date for this cell/column
      int dateIndex = isVertical
          ? slotIndex
          : index; // If horizontal, index is the date index
      if (dateIndex >= widget.dates.length) {
        // Handle potential index out of bounds if logic is complex
        dateIndex = widget.dates.length - 1;
        if (dateIndex < 0)
          return const Expanded(child: SizedBox.shrink()); // No dates
      }
      DateTime slotDate = widget.dates[dateIndex];

      // Calculate the start time for this specific slot (relevant for vertical)
      DateTime? startTimeForSlot;
      // Use passed gridInfo
      if (isVertical) {
        final timeForRow =
            gridInfo.viewStart.add(widget.intervalDuration * index);
        startTimeForSlot = DateTime(slotDate.year, slotDate.month, slotDate.day,
            timeForRow.hour, timeForRow.minute);
      }

      // Build the actual cell content (either custom or default)
      final cellContent = widget.cellBuilder != null
          ? widget.cellBuilder!(
              context,
              slotDate, // Pass the date for the column/day
              slotIndex, // Pass the column index
              widget.orientation,
            )
          : Container(
              // Use a simple Container for the background if no cellBuilder
              decoration: BoxDecoration(
                color: calendarTheme?.getSlotBackgroundColor(context),
                border: Border(
                  bottom: BorderSide(
                    color: gridLineColor,
                    width: gridLineWidth,
                  ),
                  right: BorderSide(
                    color: gridLineColor,
                    width: gridLineWidth,
                  ),
                ),
              ),
            );

      // Wrap the cell content with GestureDetector
      return Expanded(
        child: GestureDetector(
          onDoubleTap: () {
            bool isDesktopOrWeb = false;
            if (kIsWeb) {
              isDesktopOrWeb = true;
            } else {
              try {
                isDesktopOrWeb =
                    Platform.isLinux || Platform.isMacOS || Platform.isWindows;
              } catch (e) {
                isDesktopOrWeb = false;
              }
            }
            if (isDesktopOrWeb &&
                widget.onTimeSlotCreateInteraction != null &&
                startTimeForSlot != null) {
              print("Double tap detected at: $startTimeForSlot"); // Debug print
              widget.onTimeSlotCreateInteraction!(startTimeForSlot);
            }
          },
          onLongPressStart: (details) {
            // Use onLongPressStart for better feedback potentially
            if (!kIsWeb &&
                !Platform.isLinux &&
                !Platform.isMacOS &&
                !Platform.isWindows &&
                widget.onTimeSlotCreateInteraction != null &&
                startTimeForSlot != null) {
              print("Long press detected at: $startTimeForSlot"); // Debug print
              widget.onTimeSlotCreateInteraction!(startTimeForSlot);
            }
          },
          child: cellContent,
        ),
      );
    });
  }
}
