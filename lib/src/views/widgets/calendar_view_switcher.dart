import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/views/calendar_views.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class CalendarViewSwitcher extends StatelessWidget {
  const CalendarViewSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller;

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.currentViewNotifier,
        controller, // For displayDate and selectedDate changes
      ]),
      builder: (context, _) {
        return switch (controller.currentView) {
          CalendarViewType.day => const DayView(),
          CalendarViewType.workWeek => const WorkWeekView(),
          CalendarViewType.week => const WeekView(),
          CalendarViewType.month => const MonthView(),
          CalendarViewType.agenda => const AgendaView(),
          CalendarViewType.timeline => const TimelineView(),
        };
      },
    );
  }
}
