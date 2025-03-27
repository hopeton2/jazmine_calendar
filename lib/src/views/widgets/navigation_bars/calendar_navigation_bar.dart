import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/utils/ui_helper.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CalendarNavigationBar extends StatelessWidget {
  const CalendarNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JazmineCalendarController>(
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

  Widget _buildCompactNavigation(
    BuildContext context, 
    JazmineCalendarController controller, 
    DateFormat dateFormat
  ) {
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
            child: const Text('Today'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularNavigation(
    BuildContext context, 
    JazmineCalendarController controller, 
    DateFormat dateFormat
  ) {
    return Row(
      children: [
        TextButton(
          onPressed: () => _selectDate(context, controller),
          child: Text(dateFormat.format(controller.selectedDate)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => controller.navigateToDate(DateTime.now()),
          child: const Text('Today'),
        ),
      ],
    );
  }

  void _navigatePrevious(JazmineCalendarController controller) {
    final date = controller.currentView == CalendarView.day 
        ? controller.selectedDate
        : controller.displayDate;
        
    switch (controller.currentView) {
      case CalendarView.day:
        controller.selectDate(date.subtract(const Duration(days: 1)));
      case CalendarView.workWeek:
      case CalendarView.week:
        controller.navigateToDate(date.subtract(const Duration(days: 7)));
      case CalendarView.month:
        controller.navigateToDate(DateTime(date.year, date.month - 1));
      case CalendarView.timeline:
        controller.navigateToDate(date.subtract(const Duration(days: 1)));
      default:
        controller.navigateToDate(date.subtract(const Duration(days: 1)));
    }
  }

  void _navigateNext(JazmineCalendarController controller) {
    final date = controller.currentView == CalendarView.day 
        ? controller.selectedDate
        : controller.displayDate;
        
    switch (controller.currentView) {
      case CalendarView.day:
        controller.selectDate(date.add(const Duration(days: 1)));
      case CalendarView.workWeek:
      case CalendarView.week:
        controller.navigateToDate(date.add(const Duration(days: 7)));
      case CalendarView.month:
        controller.navigateToDate(DateTime(date.year, date.month + 1));
      case CalendarView.timeline:
        controller.navigateToDate(date.add(const Duration(days: 1)));
      default:
        controller.navigateToDate(date.add(const Duration(days: 1)));
    }
  }

  Future<void> _selectDate(BuildContext context, JazmineCalendarController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.navigateToDate(picked);
    }
  }
}
