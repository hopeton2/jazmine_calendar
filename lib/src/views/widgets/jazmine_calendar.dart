import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/calendar_navigation_bar.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_view_switcher.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/compact_navigation_bar.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/view_selector.dart';

import 'package:provider/provider.dart';

class JazmineCalendar extends StatelessWidget {
  final CalendarController controller; // Not nullable anymore
  final Widget Function(BuildContext, CalendarEvent)? eventBuilder;
  final bool showNavigationBar;
  final bool showViewSelector;
  final NavigationBarStyle navigationBarStyle; // New property
  final JazmineCalendarTheme? theme;

  final DayViewConfiguration dayConfiguration;
  final WeekViewConfiguration weekConfiguration;
  final MonthViewConfiguration monthConfiguration;
  final AgendaViewConfiguration agendaConfiguration;
  final TimelineConfiguration timelineConfiguration;

  JazmineCalendar({
    super.key,
    CalendarController? controller, // Accept nullable controller
    this.eventBuilder,
    this.showNavigationBar = true,
    this.showViewSelector = true,
    this.navigationBarStyle =
        NavigationBarStyle.standard, // Default to standard
    this.theme,
    this.dayConfiguration = const DayViewConfiguration(),
    this.weekConfiguration = const WeekViewConfiguration(),
    this.monthConfiguration = const MonthViewConfiguration(),
    this.agendaConfiguration = const AgendaViewConfiguration(),
    this.timelineConfiguration = const TimelineConfiguration(),
  }) : controller = controller ?? _createDefaultController();

  // Create a default controller that uses the same defaults as the CalendarController.create method
  static CalendarController _createDefaultController() {
    return CalendarController(
      initialView: CalendarViewType.day, // Use day as default view
      initialDate: DateTime.now(),
      scrollToCurrentTimeOnLoad: true,
      interval: const Duration(minutes: 30),
    );
  }

  static JazmineCalendar of(BuildContext context) {
    final widget = context.findAncestorWidgetOfExactType<JazmineCalendar>();
    if (widget == null) {
      throw FlutterError(
          'JazmineCalendar.of() called with a context that does not contain a JazmineCalendar.');
    }
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final effectiveTheme =
        theme ?? const JazmineCalendarTheme(); // Use base theme as fallback

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: controller),
      ],
      child: Theme(
        data: currentTheme.copyWith(
          extensions: [
            ...currentTheme.extensions.values, // Preserve existing extensions
            effectiveTheme, // Add our calendar theme
          ],
        ),
        child: Column(
          children: [
            if (showNavigationBar) _buildNavigationBar(),
            if (showViewSelector &&
                navigationBarStyle == NavigationBarStyle.standard)
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
}
