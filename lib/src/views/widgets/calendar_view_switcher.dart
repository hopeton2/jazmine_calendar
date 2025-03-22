import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/views/day_view.dart';
import 'package:jazmine_calendar/src/views/week_view.dart';
import 'package:jazmine_calendar/src/views/work_week_view.dart';
import 'package:jazmine_calendar/src/views/agenda_view.dart';
import 'package:jazmine_calendar/src/views/month_view.dart';
import 'package:jazmine_calendar/src/views/timeline_view.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class CalendarViewSwitcher extends StatelessWidget {
  const CalendarViewSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller!;
    
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          controller.navigateToPreviousPage();
        } else if (details.primaryVelocity! < 0) {
          controller.navigateToNextPage();
        }
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([
          controller.currentViewNotifier,
          controller,  // For displayDate and selectedDate changes
        ]),
        builder: (context, _) {
          return switch (controller.currentView) {
            CalendarView.day => DayView(
                date: controller.displayDate,
              ),
            CalendarView.workWeek => const WorkWeekView(
                interval: Duration(minutes: 30),
              ),
            CalendarView.week => WeekView(
                startDate: controller.displayDate,
                interval: const Duration(minutes: 30),
              ),
            CalendarView.month => const MonthView(),
            CalendarView.agenda => const AgendaView(),
            CalendarView.timeline => const TimelineView(),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
