import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/base_day_view.dart';
import 'package:jazmine_calendar/src/utils/date_helper.dart';

class WorkWeekView extends BaseCalendarView {
  const WorkWeekView({super.key});

  @override
  Widget buildCalendar(
    BuildContext context,
    CalendarController controller,
    DateTime startDate,
    DateTime selectedDate,
  ) {
    final jazmine = JazmineCalendar.of(context);
    return BaseDayView(
      configuration: jazmine.weekConfiguration,
      dates: DateHelper.intervalDatesForWeek(startDate, true),
    );
  }
}
