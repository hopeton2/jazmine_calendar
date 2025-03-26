import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';

class CurrentTimeIndicator extends StatefulWidget {
  final Axis orientation;
  final double headerOffset;
  final double availableSpace;
  final Color? color;
  final double width;
  final DateTime startDate;
  final DateTime endDate;
  final JazmineCalendarController controller;
  final bool autoScroll;
  final ScrollController scrollController;
  final double intervalPixels; // New property
  final double slotWidth; // New property

  const CurrentTimeIndicator({
    super.key,
    required this.orientation,
    required this.headerOffset,
    required this.availableSpace,
    required this.startDate,
    required this.endDate,
    required this.controller,
    required this.scrollController,
    required this.intervalPixels,
    required this.slotWidth, // Add to constructor
    this.color,
    this.width = 2.0,
    this.autoScroll = true,
  });

  @override
  State<CurrentTimeIndicator> createState() => _CurrentTimeIndicatorState();
}

class _CurrentTimeIndicatorState extends State<CurrentTimeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late double _currentPosition;
  final double ballSize = 12.00;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // Initialize position correctly
    final currentTime = widget.controller.currentTimeNotifier.value;

    final totalMinutesSinceStart = (currentTime.hour * 60 + currentTime.minute);
    final interval = widget.controller.intervalNotifier.value;
    final position =
        (totalMinutesSinceStart / interval.inMinutes) * widget.intervalPixels -
            ballSize / 2;

    _currentPosition = position - widget.scrollController.offset;

    // Add scroll listener
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    // Force rebuild when grid scrolls
    if (mounted) setState(() {});
  }

  void _updatePosition(double newPosition) {
    _currentPosition = newPosition;
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<DateTime>(
          valueListenable: widget.controller.currentTimeNotifier,
          builder: (context, currentTime, _) {
            if (!_isInRange()) {
              return const SizedBox.shrink();
            }

            final calendarTheme =
                Theme.of(context).extension<JazmineCalendarTheme>();
            final indicatorColor = widget.color ??
                calendarTheme?.getCurrentTimeIndicatorColor(context);
            final interval = widget.controller.intervalNotifier.value;

            final columnWidth =
                widget.availableSpace / widget.controller.visibleTimeZones.length;

            final columnPosition = widget.orientation == Axis.horizontal
                ? widget.headerOffset +
                    (columnWidth *
                        widget.controller.visibleTimeZones
                            .indexOf('UTC'))
                : widget.headerOffset;

            final totalMinutesSinceStart =
                (currentTime.hour * 60 + currentTime.minute);
            final position = (totalMinutesSinceStart / interval.inMinutes) *
                    widget.intervalPixels -
                6;
            final adjustedPosition = position - widget.scrollController.offset;

            _updatePosition(adjustedPosition);

            return Stack(
              children: [
                Positioned(
                  left: widget.orientation == Axis.horizontal
                      ? columnPosition
                      : adjustedPosition,
                  top: widget.orientation == Axis.vertical
                      ? columnPosition
                      : adjustedPosition,
                  child: Flex(
                    direction: widget.orientation == Axis.horizontal
                        ? Axis.horizontal
                        : Axis.vertical,
                    children: [
                      Container(
                        width: ballSize,
                        height: ballSize,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(
                        width: _calculateWidth(),
                        height:
                            widget.orientation == Axis.horizontal ? widget.width : null,
                        child: Container(
                          color: indicatorColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isInRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = widget.startDate;
    final end = widget.endDate;

    return today.isAfter(start.subtract(const Duration(days: 1))) &&
        today.isBefore(end.add(const Duration(days: 1)));
  }

  double _calculateWidth() {
    if (widget.orientation == Axis.vertical) {
      return widget.width;
    }

    final today = DateTime.now().startOfDay;
    final daysDiff = today.difference(widget.startDate).inDays;
    return widget.slotWidth * (daysDiff + 1) - ballSize;
  }

  
}

