import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface.dart'; // Import for EventLayoutSurfaceState and callback
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/services/calendar_view_service.dart';
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
  late final GridLayoutInfo _gridInfo; // Local broker instance

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _gridInfo = GridLayoutInfo(); // Initialize local broker
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

  void _updateGridLayoutInfo(BoxConstraints constraints, Offset origin,
      double slotWidth, double slotHeight) {
    final viewStart = widget.dates.first.toUtc();
    final viewEnd = widget.dates.last.dayEnds.toUtc();
    final origin = Offset(widget.rowHeaderWidth, widget.columnHeaderHeight);
    final availableSpace = Size(
        constraints.maxWidth - widget.rowHeaderWidth - 5,
        constraints.maxHeight - widget.columnHeaderHeight);
    final cellWidth = slotWidth;
    final cellHeight = slotHeight;

    _gridInfo.updateGridLayout(
      viewStart: viewStart,
      viewEnd: viewEnd,
      origin: origin,
      availableSpace: availableSpace,
      orientation: widget.orientation,
      divisions: widget.dates.length,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
  }

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
    final scrollOffset = (totalMinutesSinceStart / (24 * 60)) * maxScrollExtent;

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
        final origin = Offset(widget.rowHeaderWidth, widget.columnHeaderHeight);

        _updateGridLayoutInfo(constraints, origin, slotWidth, slotHeight);

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
        // Reverted: Use full available height, clipping handles reserved space visually
        final double eventSurfaceHeight = availableHeight;

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
                              _buildHeader(
                                  index, isVertical, slotWidth, slotHeight),
                              ..._buildCells(index, isVertical),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: itemCount,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                ),
              ],
            ),

            // 2. Event Rendering Surface
            if (widget.showEvents)
              Positioned(
                left: origin.dx,
                top: widget.isAllDay
                    ? origin.dy + 5.0
                    : origin.dy, // Keep top margin logic
                width: availableWidth,
                height: eventSurfaceHeight, // Use calculated height
                child: RepaintBoundary(
                  child: ClipRect(
                    child: EventLayoutSurface(
                      key: widget.eventLayoutSurfaceKey, // Pass the key
                      controller: widget.controller,
                      scrollController: _scrollController,
                      gridInfo: _gridInfo,
                      isAllDay: widget.isAllDay,
                      visibleDates: widget.dates,
                      renderStyle: EventRenderStyle(
                        // Keep example style or pass from config
                        defaultEventColor: Theme.of(context).primaryColor,
                        titleStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight
                                          .bold, // Revert font weight if needed
                                    ) ??
                                const TextStyle(color: Colors.white),
                      ),
                      maxVisibleAllDayEvents:
                          widget.maxVisibleAllDayEvents, // Pass down
                      onOverflowStateChanged:
                          widget.onOverflowStateChanged, // Pass callback down
                      // Pass new parameters down
                      isCollapsed: widget.isCollapsed,
                      collapsedContentHeight: widget.collapsedContentHeight,
                    ),
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
                autoScroll: true,
                intervalPixels: isVertical ? slotHeight : slotWidth,
                slotWidth: slotWidth,
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
      int index, bool isVertical, double slotWidth, double slotHeight) {
    final cellsOfHeaderCount =
        isVertical ? widget.numberOfColumns : widget.numberOfRows;
    final headerDate = _gridInfo.viewStart.add(widget.intervalDuration * index);

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

  List<Widget> _buildCells(int index, bool isVertical) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final gridLineWidth = widget.gridLineWidth;

    final gridLineColor = calendarTheme?.getGridLineColor(context) ??
        (theme.brightness == Brightness.light
            ? Colors.grey.withOpacity(0.2)
            : Colors.grey.withOpacity(0.3));
    var slotCount = widget.numberOfColumns;
    if (slotCount == widget.dates.length) {
      slotCount = 1;
    }
    final dateIndexMultiplier = slotCount == widget.dates.length ? 0 : index;

    // TODO: Add logic to handle null dates or dates outside the given range
    return List.generate(slotCount, (slotIndex) {
      int dateIndex = dateIndexMultiplier * slotCount + slotIndex;
      dateIndex = slotCount == 1 ? index : dateIndex;
      if (dateIndex >= widget.dates.length) {
        dateIndex = widget.dates.length - 1;
      }
      DateTime slotDate = widget.dates[dateIndex];
      return Expanded(
        child: SizedBox.expand(
          child: widget.cellBuilder != null
              ? widget.cellBuilder!(
                  context,
                  slotDate,
                  slotIndex,
                  widget.orientation,
                )
              : CalendarTimeSlot(
                  controller: widget.controller,
                  showDate: false,
                  date: slotDate,
                  formatDate: widget.headerDateFormat,
                  isAllDay: widget.isAllDay,
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
                ),
        ),
      );
    });
  }
}
