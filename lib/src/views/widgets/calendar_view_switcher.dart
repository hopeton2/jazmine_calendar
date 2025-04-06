import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/views/calendar_views.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class CalendarViewSwitcher extends StatelessWidget {
  final void Function(DateTime startTime)? onTimeSlotCreateInteraction;

  const CalendarViewSwitcher({
     super.key,
     this.onTimeSlotCreateInteraction,
  });

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
          // Pass the callback to views that support grid interaction
          CalendarViewType.day => DayView(onTimeSlotCreateInteraction: onTimeSlotCreateInteraction),
          CalendarViewType.workWeek => WorkWeekView(onTimeSlotCreateInteraction: onTimeSlotCreateInteraction),
          CalendarViewType.week => WeekView(onTimeSlotCreateInteraction: onTimeSlotCreateInteraction),
          CalendarViewType.month => const MonthView(),
          CalendarViewType.agenda => const AgendaView(),
          CalendarViewType.timeline => const TimelineView(),
        };
      },
    );
  }
}
