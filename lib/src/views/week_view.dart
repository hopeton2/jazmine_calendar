import 'package:flutter/widgets.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/base_day_view.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class WeekView extends BaseCalendarView {
  const WeekView({
    super.key,
  });

  @override
  Widget buildCalendarView(
      BuildContext context, DateTime startDate, DateTime selectedDate) {
    final configuration = JazmineCalendar.of(context).weekConfiguration;

    final weekStartDate = startDate.getWeekStartDate(configuration.firstDayOfWeek);

    return BaseDayView(
      configuration: configuration,
      days:
          List.generate(7, (index) => weekStartDate.add(Duration(days: index))),
      hourHeight: configuration.hourHeight,
      showCurrentTimeIndicator: configuration.showCurrentTimeIndicator,
    );
  }
}
