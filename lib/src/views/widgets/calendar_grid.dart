import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/services/calendar_view_service.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_time_slot.dart';
import 'package:jazmine_calendar/src/views/widgets/current_time_indicator.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

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
  final DateTime startDate;
  final DateTime endDate;
  final Duration slotDuration;
  final Duration intervalDuration;
  final Axis orientation;
  final int numberOfColumns;
  final int numberOfRows;
  final int startOfWeek;
  final DateFormat headerDateFormat;
  final JazmineCalendarController controller;
  final Widget Function(BuildContext, DateTime, bool, double, double)?
      headerBuilder;
  final double headerWidth;
  final double headerHeight;
  final bool showCurrentTimeIndicator;
  final double gridLineWidth;
  final bool isAllDay;

  const CalendarGrid({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.controller,
    required this.headerDateFormat,
    this.slotDuration = const Duration(days: 1),
    this.intervalDuration = const Duration(minutes: 30),
    this.orientation = Axis.vertical,
    required this.numberOfColumns,
    required this.numberOfRows,
    this.startOfWeek = DateTime.monday,
    this.headerBuilder,
    this.headerWidth = 60.0,
    this.headerHeight = 40.0,
    this.showCurrentTimeIndicator = true,
    this.gridLineWidth = 1.0,
    this.isAllDay = false,
  });

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only apply initial scroll if it hasn't been done for day-based views
      if (!_viewService
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
      }
    });
  }

  @override
  void dispose() {
    _viewService.markInitialScrollApplied(widget.controller.currentView);
    _scrollController.dispose();
    super.dispose();
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
            isVertical ? totalWidth - widget.headerWidth : totalWidth;
        final availableHeight =
            isVertical ? totalHeight : totalHeight - widget.headerHeight;

        final slotWidth = isVertical
            ? availableWidth / widget.numberOfColumns
            : availableWidth / widget.numberOfRows;
        final slotHeight = max(
            40.0,
            isVertical
                ? availableHeight / widget.numberOfRows
                : availableHeight / widget.numberOfColumns);

        final itemCount =
            isVertical ? widget.numberOfRows : widget.numberOfColumns;
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
                              ..._buildSlots(index, isVertical),
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
                orientation: widget.orientation == Axis.vertical ? Axis.horizontal : Axis.vertical,
                headerOffset:
                    isVertical ? widget.headerWidth : widget.headerHeight,
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
    final headerTime = widget.startDate.add(widget.intervalDuration * index);

    if (widget.headerBuilder != null) {
      return widget.headerBuilder!(
        context,
        headerTime,
        isVertical,
        isVertical ? widget.headerWidth : slotWidth,
        isVertical ? slotHeight : widget.headerHeight,
      );
    }

    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final gridLineWidth = widget.gridLineWidth;

    return Container(
      width: isVertical ? widget.headerWidth : slotWidth,
      height: isVertical ? slotHeight : widget.headerHeight,
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
        widget.headerDateFormat.format(headerTime),
        style: calendarTheme?.getTimeTextStyle(context),
      ),
    );
  }

  List<Widget> _buildSlots(int index, bool isVertical) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final gridLineWidth = widget.gridLineWidth;

    final gridLineColor = calendarTheme?.getGridLineColor(context) ??
        (theme.brightness == Brightness.light
            ? Colors.grey.withOpacity(0.2)
            : Colors.grey.withOpacity(0.3));
    final slotCount = isVertical ? widget.numberOfColumns : widget.numberOfRows;

    return List.generate(slotCount, (slotIndex) {
      final DateTime slotTime = widget.startDate
          .add(widget.slotDuration * slotIndex)
          .add(widget.intervalDuration * index);

      return Expanded(
        child: CalendarTimeSlot(
          controller: widget.controller,
          showDate: false,
          date: slotTime,
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
      );
    });
  }
}
