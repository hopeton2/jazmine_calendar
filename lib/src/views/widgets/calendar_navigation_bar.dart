import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CalendarNavigationBar extends StatelessWidget {
  const CalendarNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JazmineCalendarController>(
      builder: (context, controller, child) {
        final dateFormat = DateFormat.yMMMM();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _navigatePrevious(controller),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => _selectDate(context, controller),
                  child: Text(dateFormat.format(controller.selectedDate)),
                ),
                TextButton(
                  onPressed: () => controller.navigateToDate(DateTime.now()),
                  child: const Text('Today'),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _navigateNext(controller),
            ),
          ],
        );
      },
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
