import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/event_rendering/grid_layout_info.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

/// A widget that draws horizontal lines at specific positions
/// and adjusts them based on scroll position
class EventLinesIndicator extends StatefulWidget {
  /// The scroll controller to listen to
  final ScrollController scrollController;

  /// Creates a new EventLinesIndicator
  const EventLinesIndicator({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<EventLinesIndicator> createState() => _EventLinesIndicatorState();
}

class _EventLinesIndicatorState extends State<EventLinesIndicator> {
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
    if (widget.scrollController.hasClients) {
      _scrollOffset = widget.scrollController.offset;
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (widget.scrollController.hasClients) {
      setState(() {
        _scrollOffset = widget.scrollController.offset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EventLinesPainter(scrollOffset: _scrollOffset),
      size: Size.infinite,
    );
  }
}

class _EventLinesPainter extends CustomPainter {
  final double scrollOffset;

  const _EventLinesPainter({required this.scrollOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5;

    // Draw a line at 100px - adjusted for scroll
    canvas.drawLine(
      Offset(0, 100 - scrollOffset),
      Offset(size.width, 100 - scrollOffset),
      paint,
    );

    // Draw a line at 200px - adjusted for scroll
    paint.color = Colors.blue;
    canvas.drawLine(
      Offset(0, 200 - scrollOffset),
      Offset(size.width, 200 - scrollOffset),
      paint,
    );

    // Draw a line at 300px - adjusted for scroll
    paint.color = Colors.green;
    canvas.drawLine(
      Offset(0, 300 - scrollOffset),
      Offset(size.width, 300 - scrollOffset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EventLinesPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset;
  }
}
