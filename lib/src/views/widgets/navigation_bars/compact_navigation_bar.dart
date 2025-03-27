import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/theme/jazmine_calendar_theme.dart';
import 'package:jazmine_calendar/src/utils/ui_helper.dart';
import 'package:provider/provider.dart';
import 'package:jazmine_calendar/src/controller/jazmine_calendar_controller.dart';
import 'package:jazmine_calendar/src/views/widgets/navigation_bars/view_selector.dart';

class CompactNavigationBar extends StatelessWidget {
  const CompactNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarTheme = Theme.of(context).extension<JazmineCalendarTheme>();
    
    return Consumer<JazmineCalendarController>(
      builder: (context, controller, child) {
        final dateFormat = DateFormat.yMMMM();
        
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: calendarTheme?.getGridLineColor(context) ?? Theme.of(context).dividerColor,
              ),
            ),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              TextButton(
                onPressed: () => controller.navigateToDate(DateTime.now()),
                child: const Text('Today'),
              ),
              const SizedBox(width: 10),
              
              if (!UIHelper.isSmallDevice(context)) 
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => _navigatePrevious(controller),
              ),
              
              if (!UIHelper.isSmallDevice(context)) 
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _navigateNext(controller),
              ),
              const SizedBox(width: 10),
              
              TextButton(
                onPressed: () => _selectDate(context, controller),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateFormat.format(controller.selectedDate),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              
              const Spacer(),
              
              const ViewSelector(showCheckmarks: false),
            ],
          ),
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

  void _selectDate(BuildContext context, JazmineCalendarController controller) {
    showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    ).then((date) {
      if (date != null) {
        controller.navigateToDate(date);
      }
    });
  }

}
