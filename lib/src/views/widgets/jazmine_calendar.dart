import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_navigation_bar.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_view_switcher.dart';
import 'package:jazmine_calendar/src/views/widgets/event_editor.dart';
import 'package:jazmine_calendar/src/views/widgets/view_selector.dart';

import 'package:provider/provider.dart';

class JazmineCalendar extends StatelessWidget {
  final JazmineCalendarController controller;  // Not nullable anymore
  final Widget Function(BuildContext, Event)? eventBuilder;
  final bool showNavigationBar;
  final bool showViewSelector;
  final JazmineCalendarTheme? theme;
  
  final DayViewConfiguration dayConfiguration;
  final WeekViewConfiguration weekConfiguration;
  final MonthViewConfiguration monthConfiguration;
  final AgendaViewConfiguration agendaConfiguration;
  final TimelineConfiguration timelineConfiguration;

  JazmineCalendar({  // Remove const since we're creating controller
    super.key,
    JazmineCalendarController? controller,  // Accept nullable controller
    this.eventBuilder,
    this.showNavigationBar = true,
    this.showViewSelector = true,
    this.theme,
    this.dayConfiguration = const DayViewConfiguration(),
    this.weekConfiguration = const WeekViewConfiguration(),
    this.monthConfiguration = const MonthViewConfiguration(),
    this.agendaConfiguration = const AgendaViewConfiguration(),
    this.timelineConfiguration = const TimelineConfiguration(),
  }) : controller = controller ?? JazmineCalendarController(
         initialView: CalendarView.week,
         initialDate: DateTime.now(),
       );  // Create if null

  static JazmineCalendar of(BuildContext context) {
    final widget = context.findAncestorWidgetOfExactType<JazmineCalendar>();
    if (widget == null) {
      throw FlutterError('JazmineCalendar.of() called with a context that does not contain a JazmineCalendar.');
    }
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    return _buildCalendarContent(context, controller);
  }

  Widget _buildCalendarContent(BuildContext context, JazmineCalendarController controller) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Builder(
        builder: (context) {
          return Theme(
            data: Theme.of(context).copyWith(
              extensions: [
                ...Theme.of(context).extensions.values.where(
                  (extension) => extension is! JazmineCalendarTheme,
                ),
                theme ?? const JazmineCalendarTheme(),
              ],
            ),
            child: Scaffold(
              body: Column(
                children: [
                  if (showNavigationBar) const CalendarNavigationBar(),
                  if (showViewSelector) const ViewSelector(),
                  const Expanded(child: CalendarViewSwitcher()),
                ],
              ),
              floatingActionButton: controller.showFloatingActionButton
                  ? FloatingActionButton(
                      onPressed: () => _showAddEventDialog(context, controller),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Icon(Icons.add),
                    )
                  : null,
            ),
          );
        },
      ),
    );  }

  Future<void> _showAddEventDialog(
    BuildContext context,
    JazmineCalendarController controller,
  ) async {
    final result = await showDialog<Event>(
      context: context,
      builder: (context) => EventEditor(
        onSave: (event) => Navigator.of(context).pop(event),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );

    if (result != null) {
      await controller.addEvent(result);
      if (controller.onEventCreated != null) {
        await controller.onEventCreated!(result);
      }
    }
  }
}
