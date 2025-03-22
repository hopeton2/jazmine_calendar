import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import 'package:jazmine_calendar/src/views/base_day_view.dart';


class WorkWeekView extends StatelessWidget {
  final Duration interval;

  const WorkWeekView({
    super.key,
    this.interval = const Duration(minutes: 30),
  });

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller!;
    final configuration = JazmineCalendar.of(context).weekConfiguration;
    
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.displayDateNotifier,
      builder: (context, displayDate, _) {
        final weekStartDate = displayDate.getWeekStartDate(true); // true for work week
        
        return BaseDayView(
          configuration: configuration,
          days: List.generate(5, (index) => 
            weekStartDate.add(Duration(days: index))
          ),
          interval: interval,
        );
      },
    );
  }
}
