import 'package:flutter/widgets.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/base_day_view.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/utils/date_helper.dart';

class WeekView extends BaseCalendarView {
  const WeekView({
    super.key,
  });

  @override
  Widget buildCalendar(BuildContext context, CalendarController controller,
      DateTime startDate, DateTime selectedDate) {
    final configuration = JazmineCalendar.of(context).weekConfiguration;

    return BaseDayView(
      configuration: configuration,
      dates: DateHelper.intervalDatesForWeek(startDate),
      hourHeight: configuration.hourHeight,
      showCurrentTimeIndicator: configuration.showCurrentTimeIndicator,
    );
  }
}
