import 'package:flutter/widgets.dart';

import '../../jazmine_calendar.dart';
import 'base_calendar_view.dart';
import 'base_day_view.dart';

class DayView extends BaseCalendarView {
  final DateTime? date;

  const DayView({
    super.key,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller!;
    final configuration = JazmineCalendar.of(context).dayConfiguration;
    final displayDate = date ?? controller.displayDate;
    
    return BaseDayView(
      configuration: configuration,
      days: [displayDate],
      interval: configuration.interval,
      hourHeight: configuration.hourHeight,
      showCurrentTimeIndicator: configuration.showCurrentTimeIndicator,
    );
  }
}
