import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/constants/strings.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class ViewSelector extends StatelessWidget {
  const ViewSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller!;
    
    return ValueListenableBuilder<CalendarView>(
      valueListenable: controller.currentViewNotifier,
      builder: (context, currentView, child) {
        return SegmentedButton<CalendarView>(
          segments: const [
            ButtonSegment(
              value: CalendarView.day,
              label: Text(CalendarStrings.dayViewLabel),
            ),
            ButtonSegment(
              value: CalendarView.workWeek,
              label: Text(CalendarStrings.workWeekViewLabel),
            ),
            ButtonSegment(
              value: CalendarView.week,
              label: Text(CalendarStrings.weekViewLabel),
            ),
            ButtonSegment(
              value: CalendarView.month,
              label: Text(CalendarStrings.monthViewLabel),
            ),
            ButtonSegment(
              value: CalendarView.agenda,
              label: Text(CalendarStrings.agendaViewLabel),
            ),
          ],
          selected: {currentView},
          onSelectionChanged: (Set<CalendarView> selected) {
            controller.changeView(selected.first);
          },
        );
      },
    );
  }
}
