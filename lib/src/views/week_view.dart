import 'package:flutter/widgets.dart';
import 'base_day_view.dart';
import '../extensions/date_extensions.dart';
import 'configurations.dart';

class WeekView extends StatelessWidget {
  final DateTime startDate;
  final Duration interval;

  const WeekView({
    super.key,
    required this.startDate,
    this.interval = const Duration(minutes: 30),
  });

  @override
  Widget build(BuildContext context) {
    final weekStartDate = startDate.getWeekStartDate(false); // false for full week view
    return BaseDayView(
      configuration: const WeekViewConfiguration(
        interval: Duration(minutes: 30),
        showWeekends: true,
        weekdayFormat: 'EEE',
        showCurrentTimeIndicator: true,
        hourHeight: 60,
      ),
      days: List.generate(7, (index) => 
        weekStartDate.add(Duration(days: index))
      ),
      interval: interval,
    );
  }
}
