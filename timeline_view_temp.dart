import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/timeline_view_impl.dart';

/// A timeline view that displays events across multiple time zones.
/// This is a wrapper around TimelineViewImpl to maintain backward compatibility.
class TimelineView extends BaseCalendarView {
  const TimelineView({super.key});

  @override
  Widget buildCalendar(BuildContext context, CalendarController controller,
      DateTime startDate, DateTime selectedDate) {
    return const TimelineViewImpl();
  }
}
