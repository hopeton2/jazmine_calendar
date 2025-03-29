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

  double _calculateTodayColumnPosition() {
    final today = DateTime.now().dayStarts;
    final daysDiff = today.difference(widget.startDate).inDays;
    return widget.orientation == Axis.horizontal
        ? widget.headerOffset + (widget.slotWidth * daysDiff)
        : widget.headerOffset;
  }

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

            final columnPosition = _calculateTodayColumnPosition();

            final totalMinutesSinceStart =
                (currentTime.hour * 60 + currentTime.minute);
            final position = (totalMinutesSinceStart / interval.inMinutes) *
                    widget.intervalPixels -
                6;
            final adjustedPosition = position - widget.scrollController.offset;

            _updatePosition(adjustedPosition);

            return Stack(
              children: [
                // Dotted line extending from left
                if (widget.orientation == Axis.horizontal)
                  Positioned(
                    left: widget.headerOffset,
                    top: adjustedPosition + ballSize / 2,
                    child: CustomPaint(
                      size: Size(
                          columnPosition - widget.headerOffset, widget.width),
                      painter: DottedLinePainter(
                        color: (indicatorColor ?? Colors.blue)
                            .withOpacity(0.5), // Made semi-transparent
                        strokeWidth: widget.width / 2,
                      ),
                    ),
                  ),
                // Main time indicator
                Positioned(
                  left: widget.orientation == Axis.vertical
                      ? adjustedPosition
                      : columnPosition,
                  top: widget.orientation == Axis.horizontal
                      ? adjustedPosition
                      : columnPosition,
                  child: Flex(
                    direction: widget.orientation == Axis.vertical
                        ? Axis.vertical
                        : Axis.horizontal,
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
                        width: widget.orientation == Axis.vertical
                            ? widget.width
                            : _calculateWidth(),
                        height: widget.orientation == Axis.vertical
                            ? _calculateWidth()
                            : widget.width,
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
      return widget.availableSpace;
    }
    return widget.slotWidth - ballSize;
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DottedLinePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 4;
    double distance = 0;

    while (distance < size.width) {
      canvas.drawLine(
        Offset(distance, 0),
        Offset(distance + dashWidth, 0),
        paint,
      );
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DottedLinePainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}
