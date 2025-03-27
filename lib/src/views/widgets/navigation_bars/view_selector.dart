import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/constants/strings.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/utils/ui_helper.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/popup_view_selector.dart';

class ViewSelector extends StatelessWidget {
  final bool showCheckmarks;

  const ViewSelector({
    super.key,
    this.showCheckmarks = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = JazmineCalendar.of(context).controller;
    return buildViewSelector(controller);
  }

  Widget buildViewSelector(JazmineCalendarController controller) {
    return ValueListenableBuilder<CalendarView>(
      valueListenable: controller.currentViewNotifier,
      builder: (context, currentView, child) {
        final deviceSize = UIHelper.getDeviceSize(context);
        if (deviceSize == DeviceSize.medium || deviceSize == DeviceSize.small) {
          return PopupViewSelector(
            showSelection: deviceSize == DeviceSize.medium,
          );
        }

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
              value: CalendarView.timeline,
              label: Text(CalendarStrings.timelineViewLabel),
            ),
            ButtonSegment(
              value: CalendarView.agenda,
              label: Text(CalendarStrings.agendaViewLabel),
            ),
          ],
          selected: {currentView},
          showSelectedIcon: showCheckmarks,
          onSelectionChanged: (Set<CalendarView> selected) {
            controller.changeView(selected.first);
          },
        );
      },
    );
  }
}
