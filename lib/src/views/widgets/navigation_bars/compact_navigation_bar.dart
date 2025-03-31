import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/constants/strings.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/utils/ui_helper.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/view_selector.dart';
import 'package:jazmine_calendar/src/widgets/date_selector.dart';
import 'package:jazmine_calendar/src/widgets/month_selector.dart';
import 'package:intl/intl.dart';

class CompactNavigationBar extends StatelessWidget {
  const CompactNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarTheme = Theme.of(context).extension<JazmineCalendarTheme>();

    final controller = JazmineCalendar.of(context).controller;
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.selectedDateNotifier,
        controller.startDateNotifier,
        controller.currentViewNotifier,
      ]),
      builder: (context, child) {
        final dateFormat = DateFormat.yMMMM();

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: calendarTheme?.getGridLineColor(context) ??
                    Theme.of(context).dividerColor,
              ),
            ),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              TextButton(
                onPressed: () => controller.navigateToDate(DateTime.now()),
                child: Text(CalendarStrings.today(context)),
              ),
              if (!UIHelper.isSmallDevice(context))
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _navigatePrevious(controller),
                ),
              if (!UIHelper.isSmallDevice(context))
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navigateNext(controller),
                ),
              // Use MonthSelector for month view, DateSelector for other views
              controller.currentView == CalendarViewType.month
                  ? MonthSelector(
                      date: controller.startDate,
                      caption: _getDateRangeCaption(controller),
                      onMonthSelected: (date) =>
                          controller.navigateToDate(date),
                      isCompact: UIHelper.isSmallDevice(context),
                      dateFormat: dateFormat,
                      allowDaySelection:
                          true, // Enable combined month/day selection
                    )
                  : DateSelector(
                      date: controller.startDate,
                      caption: _getDateRangeCaption(controller),
                      onDateSelected: (date) => controller.navigateToDate(date),
                      isCompact: UIHelper.isSmallDevice(context),
                      dateFormat: dateFormat,
                    ),
              const Spacer(),
              const ViewSelector(showCheckmarks: false),
            ],
          ),
        );
      },
    );
  }

  void _navigatePrevious(CalendarController controller) {
    final date = controller.currentView == CalendarViewType.day
        ? controller.selectedDate
        : controller.startDate;

    switch (controller.currentView) {
      case CalendarViewType.day:
        controller.selectDate(date.subtract(const Duration(days: 1)));
      case CalendarViewType.workWeek:
      case CalendarViewType.week:
        controller.navigateToDate(date.subtract(const Duration(days: 7)));
      case CalendarViewType.month:
        controller.navigateToDate(DateTime(date.year, date.month - 1));
      case CalendarViewType.timeline:
        controller.navigateToDate(date.subtract(const Duration(days: 1)));
      default:
        controller.navigateToDate(date.subtract(const Duration(days: 1)));
    }
  }

  void _navigateNext(CalendarController controller) {
    final date = controller.currentView == CalendarViewType.day
        ? controller.selectedDate
        : controller.startDate;

    switch (controller.currentView) {
      case CalendarViewType.day:
        controller.selectDate(date.add(const Duration(days: 1)));
      case CalendarViewType.workWeek:
      case CalendarViewType.week:
        controller.navigateToDate(date.add(const Duration(days: 7)));
      case CalendarViewType.month:
        controller.navigateToDate(DateTime(date.year, date.month + 1));
      case CalendarViewType.timeline:
        controller.navigateToDate(date.add(const Duration(days: 1)));
      default:
        controller.navigateToDate(date.add(const Duration(days: 1)));
    }
  }

  String _getDateRangeCaption(CalendarController controller) {
    if (controller.visibleDateRange.isEmpty) {
      return '';
    }
    final startDate = controller.visibleDateRange.first;
    final endDate = controller.visibleDateRange.last;

    if (controller.currentView == CalendarViewType.month) {
      return DateFormat('yMMM').format(startDate);
    }

    if (startDate == endDate) {
      return DateFormat('MMM d, y').format(startDate);
    }

    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('d, y').format(endDate)}';
    }

    return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, y').format(endDate)}';
  }
}
