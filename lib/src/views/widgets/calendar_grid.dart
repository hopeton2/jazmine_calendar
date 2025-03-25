import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
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

class _CalendarGridItemState extends State<_CalendarGridItem> with AutomaticKeepAliveClientMixin {
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
            widget.buildHeader(widget.index, widget.isVertical, widget.slotWidth, widget.slotHeight),
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
  final bool isAllDay; // New property

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
    this.isAllDay = false, // Default value
  });

  /// Scrolls the grid to show the specified time
  static void scrollToTime(BuildContext context, DateTime time) {
    context.findAncestorStateOfType<_CalendarGridState>()?.scrollToTime(time);
  }

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> {
  late final ScrollController _scrollController;
  static bool _isFirstLoad = true;  // Keep this for CurrentTimeIndicator

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _calculateInitialOffset(),
    );
    _scrollController.addListener(_onScroll);

    if (_isFirstLoad && widget.showCurrentTimeIndicator) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollBasedOnTime();
        _isFirstLoad = false;
      });
    }
  }

  @override
  void didUpdateWidget(CalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Commenting out old scroll position restoration logic
    /*
    if (_scrollController.hasClients) {
      _previousMaxScroll = _scrollController.position.maxScrollExtent;
      _previousScrollPosition = _scrollController.offset;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      if (_previousMaxScroll != null && _previousScrollPosition != null) {
        final currentMaxScroll = _scrollController.position.maxScrollExtent;
        if (_previousMaxScroll! > 0 && currentMaxScroll > 0) {
          final scrollRatio = _previousScrollPosition! / _previousMaxScroll!;
          final newOffset = currentMaxScroll * scrollRatio;
          
          _scrollController.jumpTo(newOffset.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ));
        }
        
        _previousMaxScroll = null;
        _previousScrollPosition = null;
      }
    });
    */
  }

  void _scrollBasedOnTime() {
    if (!mounted) return;

    final now = DateTime.now();
    final isBeforeNoon = now.hour < 12;
    final isVertical = widget.orientation == Axis.vertical;

    // Calculate max scroll extent based on orientation
    final maxScroll = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      isBeforeNoon ? 0 : maxScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  double _calculateInitialOffset() {
    if (!_isFirstLoad) {
      final storedPosition = widget.controller.getScrollPosition(widget.controller.currentView);
      if (storedPosition != null) {
        return storedPosition.clamp(
          0.0,
          double.infinity,
        );
      }
    }
    return 0.0;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    widget.controller.setScrollPosition(
      widget.controller.currentView,
      _scrollController.offset,
    );
  }

  void scrollToTime(DateTime time) {
    if (!mounted) return;

    final isVertical = widget.orientation == Axis.vertical;
    final totalMinutesSinceStart = (time.hour * 60 + time.minute);
    final interval = widget.intervalDuration;

    final position = (totalMinutesSinceStart / interval.inMinutes) *
        (isVertical ? interval.inMinutes.toDouble() : widget.headerWidth);

    final viewportDimension = isVertical
        ? _scrollController.position.viewportDimension / 2
        : _scrollController.position.viewportDimension / 3;

    final offset = max(0, position - viewportDimension);

    _scrollController.jumpTo(offset.toDouble());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
              key: PageStorageKey(CalendarViewService().getScrollStorageKey(widget.controller.currentView)),
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
                            direction: isVertical ? Axis.horizontal : Axis.vertical,
                            children: [
                              _buildHeader(index, isVertical, slotWidth, slotHeight),
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
                orientation: widget.orientation,
                headerOffset:
                    isVertical ? widget.headerWidth : widget.headerHeight,
                availableSpace: isVertical ? availableHeight : availableWidth,
                startDate: widget.startDate,
                endDate: widget.endDate,
                controller: widget.controller,
                autoScroll: true,
                intervalPixels: isVertical ? slotHeight : slotWidth,
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
      final slotTime = widget.startDate
          .add(widget.slotDuration * index)
          .add(widget.slotDuration * slotIndex);

      return Expanded(
        child: CalendarTimeSlot(
          controller: widget.controller,
          showDate: false,
          date: slotTime,
          formatDate: widget.headerDateFormat,
          isAllDay: widget.isAllDay, // Pass through the isAllDay property
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
