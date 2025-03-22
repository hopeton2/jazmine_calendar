import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../jazmine_calendar.dart';
import '../day_view.dart';
import '../week_view.dart';
import '../work_week_view.dart';
import '../agenda_view.dart';
import '../month_view.dart';
import '../timeline_view.dart';

class CalendarViewSwitcher extends StatelessWidget {
  const CalendarViewSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JazmineCalendarController>(
      builder: (context, controller, child) {
        final displayDate = controller.displayDate;
        
        switch (controller.currentView) {
          case CalendarView.day:
            return DayView(date: displayDate);
          case CalendarView.workWeek:
            return WorkWeekView(
              startDate: displayDate,
              interval: const Duration(minutes: 30),
            );
          case CalendarView.week:
            return WeekView(
              startDate: displayDate,
              interval: const Duration(minutes: 30),
            );
          case CalendarView.month:
            return const MonthView();
          case CalendarView.agenda:
            return const AgendaView(configuration: AgendaViewConfiguration());
          case CalendarView.timeline:
            return const TimelineView();
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
