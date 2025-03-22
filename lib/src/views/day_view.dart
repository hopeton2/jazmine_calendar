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
    
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.displayDateNotifier,
      builder: (context, displayDate, _) {
        final effectiveDate = date ?? displayDate;
        
        return BaseDayView(
          configuration: configuration,
          days: [effectiveDate],
          interval: configuration.interval,
          hourHeight: configuration.hourHeight,
          showCurrentTimeIndicator: configuration.showCurrentTimeIndicator,
        );
      },
    );
  }
}
