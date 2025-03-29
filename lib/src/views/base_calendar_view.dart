import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';

abstract class BaseCalendarView extends StatelessWidget {
  const BaseCalendarView({super.key});

  Widget buildCalendarView(
      BuildContext context, DateTime startDate, DateTime selectedDate);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<JazmineCalendarController>(context, listen: false);
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.startDateNotifier,
        controller.selectedDateNotifier,
      ]),
      builder: (context, _) {
        return buildCalendarView(
          context,
          controller.startDate,
          controller.selectedDate,
        );
      },
    );
  }
}
