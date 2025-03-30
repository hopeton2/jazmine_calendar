import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';

abstract class BaseCalendarView extends StatelessWidget {
  const BaseCalendarView({super.key});

  Widget buildCalendar(BuildContext context, CalendarController controller,
      DateTime startDate, DateTime selectedDate);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<CalendarController>(context, listen: false);
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.startDateNotifier,
        controller.selectedDateNotifier,
        controller,
      ]),
      builder: (context, _) {
        return buildCalendar(
          context,
          controller,
          controller.startDate,
          controller.selectedDate,
        );
      },
    );
  }
}
