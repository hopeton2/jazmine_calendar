import 'package:flutter/widgets.dart';

import 'package:jazmine_calendar/src/views/base_calendar_view.dart';
import 'package:jazmine_calendar/src/views/base_day_view.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class DayView extends BaseCalendarView {

  const DayView({
    super.key,
  });

  @override
  Widget buildCalendarView(BuildContext context, startDate, selectedDate) {
    final configuration = JazmineCalendar.of(context).dayConfiguration;
    return BaseDayView(
      configuration: configuration,
      days: [selectedDate],
      hourHeight: configuration.hourHeight,
      showCurrentTimeIndicator: configuration.showCurrentTimeIndicator,
    );
  }
}
