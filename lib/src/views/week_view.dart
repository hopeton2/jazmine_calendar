import 'package:flutter/widgets.dart';
import 'base_day_view.dart';
import '../extensions/date_extensions.dart';
import 'configurations.dart';
import '../../jazmine_calendar.dart';

class WeekView extends StatelessWidget {
  const WeekView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller!;
    final configuration = JazmineCalendar.of(context).weekConfiguration;

    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.displayDateNotifier,
      builder: (context, displayDate, _) {
        final weekStartDate = displayDate.getWeekStartDate(false);

        return BaseDayView(
          configuration: configuration,
          days: List.generate(
              7, (index) => weekStartDate.add(Duration(days: index))),
          hourHeight: configuration.hourHeight,
          showCurrentTimeIndicator: configuration.showCurrentTimeIndicator,
        );
      },
    );
  }
}
