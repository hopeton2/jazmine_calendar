import 'package:flutter/widgets.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

/// Builder for calendar headers that provides context, date, orientation, width, and height
typedef CalendarHeaderBuilder = Widget Function(
  BuildContext context,
  DateTime date,
  bool isVertical,
  double width,
  double height,
);

/// Builder for date headers that provides context and date
typedef DateHeaderBuilder = Widget Function(
  BuildContext context,
  DateTime date,
  Size size,
);

/// Builder for calendar slots that provides context, date, row, and column
typedef CellBuilder = Widget Function(
  BuildContext context,
  DateTime date,
  int index,
  Axis orientation,
);

/// Callback for event creation
typedef EventCallback = Future<void> Function(CalendarEvent event);

/// Callback for event time-related operations (resize/reschedule)
typedef EventTimeCallback = Future<void> Function(
  CalendarEvent event,
  DateTime newStart,
  DateTime newEnd,
);
