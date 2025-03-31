import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/constants/strings.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/utils/ui_helper.dart';
import 'package:jazmine_calendar/src/widgets/dual_view_date_picker.dart';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CalendarNavigationBar extends StatelessWidget {
  const CalendarNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarController>(
      builder: (context, controller, child) {
        final dateFormat = DateFormat.yMMMM();
        final shouldUseMobileLayout = UIHelper.shouldUseMobileLayout(context);
        final deviceSize = UIHelper.getDeviceSize(context);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _navigatePrevious(controller),
            ),
            if (deviceSize == DeviceSize.small || shouldUseMobileLayout)
              _buildCompactNavigation(context, controller, dateFormat)
            else
              _buildRegularNavigation(context, controller, dateFormat),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _navigateNext(controller),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactNavigation(BuildContext context,
      CalendarController controller, DateFormat dateFormat) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => _selectDate(context, controller),
            child: Text(
              dateFormat.format(controller.selectedDate),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => controller.navigateToDate(DateTime.now()),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
            ),
            child: Text(CalendarStrings.today(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularNavigation(BuildContext context,
      CalendarController controller, DateFormat dateFormat) {
    return Row(
      children: [
        TextButton(
          onPressed: () => _selectDate(context, controller),
          child: Text(dateFormat.format(controller.selectedDate)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => controller.navigateToDate(DateTime.now()),
          child: Text(CalendarStrings.today(context)),
        ),
      ],
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

  Future<void> _selectDate(
      BuildContext context, CalendarController controller) async {
    if (controller.currentView == CalendarViewType.month) {
      // For month view, show a combined month/day picker

      // Show the combined picker in a dialog
      final DateTime? picked = await showDialog<DateTime>(
        context: context,
        builder: (BuildContext context) {
          final theme = Theme.of(context);
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CalendarStrings.selectDate(context),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: theme.colorScheme.onSurface),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    // Use a much taller height to ensure all dates are visible
                    height:
                        850.0, // Much taller height to ensure all dates are visible
                    child: DualViewDatePicker(
                      initialDate: controller.startDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      onDateSelected: (date) => Navigator.of(context).pop(date),
                      controller: controller,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (picked != null) {
        controller.navigateToDate(picked);
      }
    } else {
      // For other views, show our custom date picker in a dialog
      final DateTime? picked = await showDialog<DateTime>(
        context: context,
        builder: (BuildContext context) {
          final theme = Theme.of(context);
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CalendarStrings.selectDate(context),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: theme.colorScheme.onSurface),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 400.0, // Reasonable height for date-only picker
                    child: DualViewDatePicker(
                      initialDate: controller.selectedDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      onDateSelected: (date) => Navigator.of(context).pop(date),
                      controller: controller,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (picked != null) {
        controller.navigateToDate(picked);
      }
    }
  }
}
