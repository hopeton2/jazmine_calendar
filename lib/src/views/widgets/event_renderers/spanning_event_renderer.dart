import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import '../../../models/event.dart';
import 'event_renderer.dart';

class SpanningEventRenderer implements EventRenderer {
  @override
  Widget buildEventWidget({
    required BuildContext context,
    required Event event,
    required DateTime cellDate,
    required Size availableSpace,
  }) {
    final isFirstDay = event.start.isSameDay(cellDate);
    final isLastDay = event.end.isSameDay(cellDate);

    return Container(
      height: 20,
      margin: EdgeInsets.only(
        left: isFirstDay ? 2 : 0,
        right: isLastDay ? 2 : 0,
      ),
      decoration: BoxDecoration(
        color: event.color ?? Colors.blue,
        borderRadius: BorderRadius.horizontal(
          left: isFirstDay ? const Radius.circular(4) : Radius.zero,
          right: isLastDay ? const Radius.circular(4) : Radius.zero,
        ),
      ),
      child: isFirstDay
          ? Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }
}