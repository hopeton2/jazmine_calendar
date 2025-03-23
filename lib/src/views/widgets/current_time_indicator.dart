import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';

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
  final double intervalPixels;  // New property

  const CurrentTimeIndicator({
    super.key,
    required this.orientation,
    required this.headerOffset,
    required this.availableSpace,
    required this.startDate,
    required this.endDate,
    required this.controller,
    required this.scrollController,
    required this.intervalPixels,  // Add to constructor
    this.color,
    this.width = 2.0,
    this.autoScroll = true,
  });

  @override
  State<CurrentTimeIndicator> createState() => _CurrentTimeIndicatorState();
}

class _CurrentTimeIndicatorState extends State<CurrentTimeIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  late double _currentPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    
    // Initialize position correctly
    final currentTime = widget.controller.currentTimeNotifier.value;
    final startOfDay = DateTime(
      widget.startDate.year,
      widget.startDate.month,
      widget.startDate.day,
    );
    
    final totalMinutesSinceStart = (currentTime.hour * 60 + currentTime.minute);
    final interval = widget.controller.intervalNotifier.value;
    final position = (totalMinutesSinceStart / interval.inMinutes) * widget.intervalPixels - 6;
    
    _currentPosition = position - widget.scrollController.offset;
    _positionAnimation = Tween<double>(
      begin: _currentPosition,
      end: _currentPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
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
    _positionAnimation = Tween<double>(
      begin: _currentPosition,
      end: newPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _currentPosition = newPosition;
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: widget.controller.currentTimeNotifier,
      builder: (context, currentTime, _) {
        if (!_isInRange(currentTime)) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final indicatorColor = widget.color ?? theme.colorScheme.primary;
        final interval = widget.controller.intervalNotifier.value;

        // Calculate position based on hours and minutes since start of day
        final startOfDay = DateTime(
          widget.startDate.year,
          widget.startDate.month,
          widget.startDate.day,
        );
        
        // Calculate total minutes since start of day
        final totalMinutesSinceStart = (currentTime.hour * 60 + currentTime.minute);
        
        // Calculate position using interval pixels (pixels per interval)
        final position = (totalMinutesSinceStart / interval.inMinutes) * widget.intervalPixels - 6; // Subtract 6 pixels to align with time slots

        // Adjust position based on scroll offset
        final adjustedPosition = position - widget.scrollController.offset;

        _updatePosition(adjustedPosition);

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final animatedPosition = _positionAnimation.value;
            return Positioned(
              left: widget.orientation == Axis.vertical ? widget.headerOffset : animatedPosition,
              right: widget.orientation == Axis.vertical ? 0 : null,
              top: widget.orientation == Axis.vertical ? animatedPosition : widget.headerOffset,
              bottom: widget.orientation == Axis.horizontal ? 0 : null,
              child: child!,
            );
          },
          child: Flex(
            direction: widget.orientation == Axis.vertical ? Axis.horizontal : Axis.vertical,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: widget.orientation == Axis.horizontal ? widget.width : null,
                  height: widget.orientation == Axis.vertical ? widget.width : null,
                  color: indicatorColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isInRange(DateTime date) {
    return date.isAfter(widget.startDate) && date.isBefore(widget.endDate);
  }
}
