import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/event_rendering/event_layout_surface.dart';
import 'package:jazmine_calendar/src/event_rendering/event_render_style.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_broker.dart';
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
    this.rowHeaderWidth = 60.0,
    this.columnHeaderHeight = 60.0,
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

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

  void _updateGridLayoutBroker(BoxConstraints constraints, Offset origin,
      double slotWidth, double slotHeight) { // Add slotWidth, slotHeight params
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
    final availableSpace = Size(constraints.maxWidth - widget.rowHeaderWidth,
        constraints.maxHeight - widget.columnHeaderHeight);

    // Use the passed slot dimensions (which account for min sizes) as the cell dimensions
    final cellWidth = slotWidth;
    final cellHeight = slotHeight;

    // Update the broker
    GridLayoutBroker().updateGridLayout(
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
        _updateGridLayoutBroker(constraints, origin, slotWidth, slotHeight);

        // Perform initial scroll *after* layout is known and broker is updated
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
                      debugPrint('Building item $index of $itemCount');
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

            // Add direct event rendering
            // Position the EventLayoutSurface correctly within the Stack,
            // offset by the headers and sized to the available content area.
            // Add direct event rendering
            // Position the EventLayoutSurface correctly within the Stack,
            // offset by the headers and sized to the available content area.
            // Position the EventLayoutSurface correctly within the Stack,
            // offset by the headers and sized to the available content area.
            if (widget.showEvents)
              Positioned(
                left: origin.dx, // Use calculated origin.dx
                top: 0, // Position surface at the top of the Stack
                width: availableWidth, // Use calculated available width
                height: availableHeight, // Use calculated available height
                child: RepaintBoundary(
                  child: ClipRect( // Clip to the bounds of the available space
                    child: EventLayoutSurface(
                      controller: widget.controller,
                      scrollController: _scrollController,
                      renderStyle: EventRenderStyle(
                        defaultEventColor: Theme.of(context).primaryColor,
                        titleStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ) ??
                                const TextStyle(color: Colors.white),
                      ),
                      // Background color added inside EventLayoutSurface's build method
                    ),
                  ),
                ),
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
    // Calculate headerDate based on the UTC viewStart from the broker
    final headerDate = GridLayoutBroker()
        .viewStart
        .add(widget.intervalDuration * index); // Access singleton

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
