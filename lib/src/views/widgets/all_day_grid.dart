import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';
import 'package:jazmine_calendar/src/views/widgets/calendar_grid.dart';

class AllDayGrid extends StatelessWidget {
  final List<DateTime> dates;
  final CalendarController controller;
  final double headerWidth;
  final double allDayRegionHeight;
  final Color? borderColor;

  const AllDayGrid({
    super.key,
    required this.dates,
    required this.controller,
    this.headerWidth = 0.0,
    this.allDayRegionHeight = 80.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _buildAllDayHeader(
          context, DateTime.now(), true, headerWidth, allDayRegionHeight),
      Expanded(
        child: SizedBox(
          height: allDayRegionHeight,
          child: CalendarGrid(
            dates: dates,
            controller: controller,
            headerDateFormat: DateFormat(''),
            numberOfColumns: dates.length,
            numberOfRows: 1,
            slotDuration: const Duration(days: 1),
            intervalDuration: const Duration(days: 1),
            orientation: Axis.horizontal,
            rowHeaderWidth: 0,
            columnHeaderHeight: 0.0,
            showCurrentTimeIndicator: false,
            isAllDay: true,
            //physics: const NeverScrollableScrollPhysics(),
            //slotColor: Theme.of(context).extension<JazmineCalendarTheme>()?.getAllDayBackgroundColor(context),
          ),
        ),
      )
    ]);
  }

  Widget _buildAllDayHeader(BuildContext context, DateTime date,
      bool isVertical, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(
          CalendarLocalization.of(context).allDay,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}
