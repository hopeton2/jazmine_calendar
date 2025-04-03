import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/services/calendar_view_service.dart';
import 'package:jazmine_calendar/src/utils/typedefs.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_time_slot.dart';
import 'package:jazmine_calendar/src/views/widgets/current_time_indicator.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart'; // Added import

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

    // Initial scroll logic moved to build method after layout is known
  }

  @override
  void didUpdateWidget(CalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update broker if relevant properties changed
    // Broker update logic moved to build method's LayoutBuilder
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Broker update logic moved to build method's LayoutBuilder
  }

  @override
  void dispose() {
    _viewService.markInitialScrollApplied(widget.controller.currentView);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateGridLayoutInfo(BoxConstraints constraints, Offset origin,
      double slotWidth, double slotHeight) {
    // Add slotWidth, slotHeight params
    // Use constraints provided by LayoutBuilder and calculated slot dimensions

    // Calculate view start and end times
    // Ensure viewStart and viewEnd are in UTC for consistent calculations
    final viewStart = widget.dates.first.toUtc();
    // Use dayEnds extension and convert to UTC
    final viewEnd = widget.dates.last.dayEnds.toUtc();

    // Calculate origin and available space
    // Origin is the top-left corner of the actual grid area, offset by headers.
    final origin = Offset(widget.rowHeaderWidth, widget.columnHeaderHeight);
    // Available space is derived from constraints minus header dimensions.
    final availableSpace = Size(
        constraints.maxWidth - widget.rowHeaderWidth - 5,
        constraints.maxHeight - widget.columnHeaderHeight);

    // Use the passed slot dimensions (which account for min sizes) as the cell dimensions
    final cellWidth = slotWidth;
    final cellHeight = slotHeight;

    // Update the local broker instance
    _gridInfo.updateGridLayout(
      viewStart: viewStart, // Now in UTC
      viewEnd: viewEnd, // Now in UTC
      origin: origin,
      availableSpace: availableSpace,
      orientation: widget.orientation,
      divisions: widget.dates.length,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
    // Removed debug print
    // Removed debug print
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
        // Calculate sizes needed for both broker and layout *first*
        final isVertical = widget.orientation == Axis.vertical;
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        final availableWidth =
            isVertical ? totalWidth - widget.rowHeaderWidth : totalWidth;
        final availableHeight =
            isVertical ? totalHeight : totalHeight - widget.columnHeaderHeight;
        // Calculate the actual slot dimensions used by the Sliver list
        final slotWidth =
            max(widget.minCellWidth, availableWidth / widget.numberOfColumns);
        final slotHeight =
            max(widget.minCellHeight, availableHeight / widget.numberOfRows);

        // Calculate origin based on header sizes
        final origin = Offset(widget.rowHeaderWidth, widget.columnHeaderHeight);

        // Update the broker *before* building the rest of the UI, passing the actual slot dimensions
        _updateGridLayoutInfo(constraints, origin, slotWidth, slotHeight);

        // Perform initial scroll *after* layout is known and gridoker is updated
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
            // Mark scroll as applied *after* attempting it
            _viewService
                .markInitialScrollApplied(widget.controller.currentView);
          }
        });
        // Sizes already calculated above

        final itemCount =
            isVertical ? widget.numberOfRows : widget.numberOfColumns;
        // Use the pre-calculated slot dimensions for the itemExtent
        final itemExtent = isVertical ? slotHeight : slotWidth;

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
                      // debugPrint('Building item $index of $itemCount'); // Keep for debugging if needed
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
                    addAutomaticKeepAlives:
                        false, // Consider performance implications
                    addRepaintBoundaries:
                        true, // Consider performance implications
                  ),
                ),
              ],
            ),

            // 2. Event Rendering Surface (drawn below time indicator)
            if (widget.showEvents)
              Positioned(
                left: origin.dx,
                // Apply top margin only for all-day events
                top: widget.isAllDay ? origin.dy + 5.0 : origin.dy,
                width: availableWidth,
                // Adjust height for horizontal orientation to reserve space at the bottom
                height: widget.orientation == Axis.horizontal
                    ? (availableHeight - 30.0).clamp(0.0, double.infinity) // Subtract 30px reserved space
                    : availableHeight,
                child: RepaintBoundary(
                  child: ClipRect(
                    // Wrap with Padding for all-day events (alternative approach, keeping Positioned adjustment for now)
                    // child: widget.isAllDay
                    //     ? Padding(
                    //         padding: const EdgeInsets.only(top: 5.0),
                    //         child: EventLayoutSurface(...),
                    //       )
                    //     : EventLayoutSurface(...),
                    child: EventLayoutSurface(
                      controller: widget.controller,
                      scrollController: _scrollController,
                      gridInfo: _gridInfo, // Pass local broker instance
                      isAllDay: widget.isAllDay,
                      visibleDates: widget.dates,
                      renderStyle: EventRenderStyle(
                        // Example style - consider passing from config
                        defaultEventColor: Theme.of(context).primaryColor,
                        titleStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ) ??
                                const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

            // 3. Current Time Indicator (drawn last, on top)
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
        );
      },
    );
  }

  Widget _buildHeader(
      int index, bool isVertical, double slotWidth, double slotHeight) {
    final cellsOfHeaderCount =
        isVertical ? widget.numberOfColumns : widget.numberOfRows;
    // Calculate headerDate based on the UTC viewStart from the local broker
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
        // Convert headerDate (UTC) to local time before formatting for display
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
      // If the number of slots matches the number of dates, we don't need to multiply the index
      slotCount = 1; //-- let the default behavior to create a full row
    }
    final dateIndexMultiplier = slotCount == widget.dates.length ? 0 : index;

    return List.generate(slotCount, (slotIndex) {
      int dateIndex = dateIndexMultiplier * slotCount + slotIndex;
      DateTime slotDate = widget.dates[slotCount == 1 ? index : dateIndex];

      // Use a SizedBox with Expanded to ensure proper sizing in both orientations
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
