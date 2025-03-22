import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/jazmine_calendar_controller.dart';

class ViewSelector extends StatelessWidget {
  const ViewSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JazmineCalendarController>(
      builder: (context, controller, child) {
        return SegmentedButton<CalendarView>(
          segments: const [
            ButtonSegment(
              value: CalendarView.day,
              label: Text('Day'),
            ),
            ButtonSegment(
              value: CalendarView.workWeek,
              label: Text('Work Week'),
            ),
            ButtonSegment(
              value: CalendarView.week,
              label: Text('Week'),
            ),
            ButtonSegment(
              value: CalendarView.month,
              label: Text('Month'),
            ),
            ButtonSegment(
              value: CalendarView.agenda,
              label: Text('Agenda'),
            ),
          ],
          selected: {controller.currentView},
          onSelectionChanged: (Set<CalendarView> selected) {
            controller.changeView(selected.first);
          },
        );
      },
    );
  }
}