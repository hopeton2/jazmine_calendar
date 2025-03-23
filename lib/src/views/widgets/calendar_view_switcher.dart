import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/views/day_view.dart';
import 'package:jazmine_calendar/src/views/week_view.dart';
import 'package:jazmine_calendar/src/views/work_week_view.dart';
import 'package:jazmine_calendar/src/views/agenda_view.dart';
import 'package:jazmine_calendar/src/views/month_view.dart';
import 'package:jazmine_calendar/src/views/timeline_view.dart';

import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class CalendarViewSwitcher extends StatelessWidget {
  const CalendarViewSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller!;
    
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.currentViewNotifier,
        controller,  // For displayDate and selectedDate changes
      ]),
      builder: (context, _) {
        return switch (controller.currentView) {
          CalendarView.day => const DayView(),
          CalendarView.workWeek => const WorkWeekView(),
          CalendarView.week => const WeekView(),
          CalendarView.month => const MonthView(),
          CalendarView.agenda => const AgendaView(),
          CalendarView.timeline => const TimelineView(),
        };
      },
    );
  }
}
