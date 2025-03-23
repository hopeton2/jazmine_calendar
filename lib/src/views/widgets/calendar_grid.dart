import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_time_slot.dart';
import 'package:jazmine_calendar/src/views/widgets/current_time_indicator.dart';

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
  
  // Add header builder callback
  final Widget Function(BuildContext, DateTime, bool, double, double)? headerBuilder;
  
  // Appearance customization
  final Color? slotColor;
  final Color? slotBorderColor;
  final double slotBorderWidth;
  final TextStyle? headerTextStyle;
  final Color? headerBackgroundColor;

  // Header sizes
  final double headerWidth;
  final double headerHeight;

  final bool showCurrentTimeIndicator;
  final Color? currentTimeIndicatorColor;
  
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
    this.slotColor,
    this.slotBorderColor,
    this.slotBorderWidth = 1.0,
    this.headerTextStyle,
    this.headerBackgroundColor,
    this.headerWidth = 60.0,
    this.headerHeight = 40.0,
    this.showCurrentTimeIndicator = true,
    this.currentTimeIndicatorColor,
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
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      // Set initial scroll position directly in controller creation
      initialScrollOffset: _calculateInitialOffset(),
    );
    
    // Add scroll position listener
    _scrollController.addListener(_onScroll);
  }

  double _calculateInitialOffset() {
    // Check for stored scroll position
    final storedPosition = widget.controller.getScrollPosition(widget.controller.currentView);
    
    if (storedPosition != null) {
      return storedPosition;
    }

    // Fall back to current time position
    final time = DateTime.now();
    final isVertical = widget.orientation == Axis.vertical;
    final totalMinutesSinceStart = (time.hour * 60 + time.minute);
    final interval = widget.intervalDuration;
    
    final position = (totalMinutesSinceStart / interval.inMinutes) * 
        (isVertical ? interval.inMinutes.toDouble() : widget.headerWidth);

    // Add padding to center the time in the viewport
    // Note: Since we don't have viewport dimensions yet, use an estimated value
    final estimatedViewportDimension = isVertical ? 300.0 : 200.0;
    final viewportPadding = isVertical 
        ? estimatedViewportDimension / 2
        : estimatedViewportDimension / 3;
    
    return max(0, position - viewportPadding);
  }

  void _onScroll() {
    // Store current scroll position when user scrolls
    widget.controller.setScrollPosition(
      widget.controller.currentView,
      _scrollController.offset
    );
  }

  void scrollToTime(DateTime time) {
    if (!mounted) return;
    
    final isVertical = widget.orientation == Axis.vertical;
    final totalMinutesSinceStart = (time.hour * 60 + time.minute);
    final interval = widget.intervalDuration;
    
    final position = (totalMinutesSinceStart / interval.inMinutes) * 
        (isVertical ? interval.inMinutes.toDouble() : widget.headerWidth);

    // Add padding to center the time in the viewport
    final viewportDimension = isVertical 
        ? _scrollController.position.viewportDimension / 2
        : _scrollController.position.viewportDimension / 3;
    
    final offset = max(0, position - viewportDimension);
    
    // Replace animateTo with jumpTo for immediate scrolling
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
        
        final availableWidth = isVertical ? totalWidth - widget.headerWidth : totalWidth;
        final availableHeight = isVertical ? totalHeight : totalHeight - widget.headerHeight;
        
        final slotWidth = isVertical ? availableWidth / widget.numberOfColumns : availableWidth / widget.numberOfRows;
        final slotHeight = max(40.0, isVertical ? availableHeight / widget.numberOfRows : availableHeight / widget.numberOfColumns);
        
        final itemCount = isVertical ? widget.numberOfRows : widget.numberOfColumns;

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              scrollDirection: widget.orientation,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: isVertical ? slotWidth : null,
                  height: isVertical ? slotHeight : null,
                  child: Flex(
                    direction: isVertical ? Axis.horizontal : Axis.vertical,
                    children: [
                      _buildHeader(index, isVertical, slotWidth, slotHeight),
                      ..._buildSlots(index, isVertical),
                    ],
                  ),
                );
              },
            ),
            if (widget.showCurrentTimeIndicator)
              CurrentTimeIndicator(
                scrollController: _scrollController,
                orientation: widget.orientation,
                headerOffset: isVertical ? widget.headerWidth : widget.headerHeight,
                availableSpace: isVertical ? availableHeight : availableWidth,
                startDate: widget.startDate,
                endDate: widget.endDate,
                controller: widget.controller,
                color: widget.currentTimeIndicatorColor,
                autoScroll: true,
                intervalPixels: isVertical ? slotHeight : slotWidth
                    
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int index, bool isVertical, double slotWidth, double slotHeight) {
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

    // Default implementation if no headerBuilder provided
    return Container(
      width: isVertical ? widget.headerWidth : slotWidth,
      height: isVertical ? slotHeight : widget.headerHeight,
      color: widget.headerBackgroundColor,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.slotBorderColor ?? Colors.grey.withOpacity(0.2),
            width: .5,
          ),
          right: BorderSide(
            color: widget.slotBorderColor ?? Colors.grey.withOpacity(0.2),
            width: .5,
          ),
        ),
      ),
      child: Text(
        widget.headerDateFormat.format(headerTime),
        style: widget.headerTextStyle,
      ),
    );
  }

  List<Widget> _buildSlots(int index, bool isVertical) {
    final slotCount = isVertical ? widget.numberOfColumns : widget.numberOfRows;
    
    return List.generate(slotCount, (slotIndex) {
      final slotTime = widget
          .startDate
          .add(widget.slotDuration * index)
          .add(widget.slotDuration * slotIndex);
          
      return Expanded(
        child: CalendarTimeSlot(
          controller: widget.controller,
          showDate: false,
          date: slotTime,
          formatDate: widget.headerDateFormat,
          decoration: BoxDecoration(
            color: widget.slotColor,
            border: Border(
              bottom: BorderSide(
                color: widget.slotBorderColor ?? Colors.grey.withOpacity(0.2),
                width: .5, //slotBorderWidth,
              ),
              right: BorderSide(
                color: widget.slotBorderColor ?? Colors.grey.withOpacity(0.2),
                width: .5, //slotBorderWidth,
              ),
            ),
          ), 
        ),
      );
    });
  }
}
