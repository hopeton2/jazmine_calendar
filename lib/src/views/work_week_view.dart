import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'base_day_view.dart';
import '../extensions/date_extensions.dart';

class WorkWeekView extends StatelessWidget {
  final DateTime startDate;
  final Duration interval;

  const WorkWeekView({
    super.key,
    required this.startDate,
    this.interval = const Duration(minutes: 30),
  });

  @override
  Widget build(BuildContext context) {
    final weekStartDate = startDate.getWeekStartDate(true); // true for work week view
    return BaseDayView(
      configuration: const DayViewConfiguration(
        interval: Duration(minutes: 30),
        showCurrentTimeIndicator: true,
        hourHeight: 60,
      ),
      days: List.generate(5, (index) => 
        weekStartDate.add(Duration(days: index))
      ),
      interval: interval,
    );
  }
}
