import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/calendar_navigation_bar.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_view_switcher.dart';
import 'package:jazmine_calendar/src/views/widgets/event_editor.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/compact_navigation_bar.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/view_selector.dart';

import 'package:provider/provider.dart';

class JazmineCalendar extends StatelessWidget {
  final JazmineCalendarController controller;  // Not nullable anymore
  final Widget Function(BuildContext, Event)? eventBuilder;
  final bool showNavigationBar;
  final bool showViewSelector;
  final NavigationBarStyle navigationBarStyle;  // New property
  final JazmineCalendarTheme? theme;
  
  final DayViewConfiguration dayConfiguration;
  final WeekViewConfiguration weekConfiguration;
  final MonthViewConfiguration monthConfiguration;
  final AgendaViewConfiguration agendaConfiguration;
  final TimelineConfiguration timelineConfiguration;

  JazmineCalendar({
    super.key,
    JazmineCalendarController? controller,  // Accept nullable controller
    this.eventBuilder,
    this.showNavigationBar = true,
    this.showViewSelector = true,
    this.navigationBarStyle = NavigationBarStyle.standard,  // Default to standard
    this.theme,
    this.dayConfiguration = const DayViewConfiguration(),
    this.weekConfiguration = const WeekViewConfiguration(),
    this.monthConfiguration = const MonthViewConfiguration(),
    this.agendaConfiguration = const AgendaViewConfiguration(),
    this.timelineConfiguration = const TimelineConfiguration(),
  }) : controller = controller ?? JazmineCalendarController(
         initialView: CalendarView.month,
         initialDate: DateTime.now(),
         scrollToCurrentTimeOnLoad: true,
         interval: const Duration(minutes: 30),
       );

  static JazmineCalendar of(BuildContext context) {
    final widget = context.findAncestorWidgetOfExactType<JazmineCalendar>();
    if (widget == null) {
      throw FlutterError('JazmineCalendar.of() called with a context that does not contain a JazmineCalendar.');
    }
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final effectiveTheme = theme ?? const JazmineCalendarTheme();  // Use base theme as fallback

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: controller),
      ],
      child: Theme(
        data: currentTheme.copyWith(
          extensions: [
            ...?currentTheme.extensions.values,  // Preserve existing extensions
            effectiveTheme,  // Add our calendar theme
          ],
        ),
        child: Column(
          children: [
            if (showNavigationBar)
              _buildNavigationBar(),
            if (showViewSelector && navigationBarStyle == NavigationBarStyle.standard)
              const ViewSelector(),
            const Expanded(child: CalendarViewSwitcher()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return switch (navigationBarStyle) {
      NavigationBarStyle.standard => const CalendarNavigationBar(),
      NavigationBarStyle.compact => const CompactNavigationBar(),
    };
  }

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
