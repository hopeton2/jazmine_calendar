import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/base_day_view.dart';

class WorkWeekView extends BaseCalendarView {
  const WorkWeekView({
    super.key,
  });

  @override
  Widget buildCalendarView(
      BuildContext context, DateTime startDate, DateTime selectedDate) {
    final configuration = JazmineCalendar.of(context).weekConfiguration;

    final weekStartDate = startDate.getWeekStartDate(configuration.firstDayOfWeek);

    return BaseDayView(
      configuration: configuration,
      days:List.generate(5, (index) => weekStartDate.add(Duration(days: index))),
    );
  }
}
