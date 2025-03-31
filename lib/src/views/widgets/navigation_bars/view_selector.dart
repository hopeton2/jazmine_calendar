import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/constants/strings.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/utils/ui_helper.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/dropdown_view_selector.dart';

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

  Widget buildViewSelector(CalendarController controller) {
    return ValueListenableBuilder<CalendarViewType>(
      valueListenable: controller.currentViewNotifier,
      builder: (context, currentView, child) {
        final deviceSize = UIHelper.getDeviceSize(context);
        if (deviceSize == DeviceSize.medium || deviceSize == DeviceSize.small) {
          return DropdownViewSelector(
            showSelection: deviceSize == DeviceSize.medium,
          );
        }

        return SegmentedButton<CalendarViewType>(
          segments: [
            ButtonSegment(
              value: CalendarViewType.day,
              label: Text(CalendarStrings.dayViewLabel(context)),
            ),
            ButtonSegment(
              value: CalendarViewType.workWeek,
              label: Text(CalendarStrings.workWeekViewLabel(context)),
            ),
            ButtonSegment(
              value: CalendarViewType.week,
              label: Text(CalendarStrings.weekViewLabel(context)),
            ),
            ButtonSegment(
              value: CalendarViewType.month,
              label: Text(CalendarStrings.monthViewLabel(context)),
            ),
            ButtonSegment(
              value: CalendarViewType.timeline,
              label: Text(CalendarStrings.timelineViewLabel(context)),
            ),
            ButtonSegment(
              value: CalendarViewType.agenda,
              label: Text(CalendarStrings.agendaViewLabel(context)),
            ),
          ],
          selected: {currentView},
          showSelectedIcon: showCheckmarks,
          onSelectionChanged: (Set<CalendarViewType> selected) {
            controller.changeView(selected.first);
          },
        );
      },
    );
  }
}
