import 'package:flutter/widgets.dart';

import '../../jazmine_calendar.dart';
import 'base_calendar_view.dart';
import 'base_day_view.dart';

class DayView extends BaseCalendarView {

  const DayView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller!;
    final configuration = JazmineCalendar.of(context).dayConfiguration;
    
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.selectedDateNotifier,
      builder: (context, selectedDate, _) {
        return BaseDayView(
          configuration: configuration,
          days: [selectedDate],
          hourHeight: configuration.hourHeight,
          showCurrentTimeIndicator: configuration.showCurrentTimeIndicator,
        );
      },
    );
  }
}
