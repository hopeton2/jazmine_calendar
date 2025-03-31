import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/utils/date_helper.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/base_timeline_view.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

/// A timeline view that displays events horizontally with time on the top.
///
/// This view shows a horizontal timeline with time displayed at the top.
class TimelineView extends BaseCalendarView {
  /// Creates a timeline view.
  const TimelineView({super.key});

  @override
  Widget buildCalendar(BuildContext context, CalendarController controller,
      DateTime startDate, DateTime selectedDate) {
    final configuration = JazmineCalendar.of(context).dayConfiguration;
    return BaseTimelineView(
      configuration: configuration,
      dates: DateHelper.intervalDatesForTimelineDay(selectedDate),
      showCurrentTimeIndicator: configuration.showCurrentTimeIndicator,
    );
  }
}
