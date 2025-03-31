import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';

class DateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;
  final bool isCompact;
  final DateFormat? dateFormat;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final PopupMenuPosition position;
  final String? caption; // New caption property
  final CalendarController? controller; // Add controller property

  const DateSelector({
    super.key,
    required this.date,
    required this.onDateSelected,
    this.isCompact = false,
    this.dateFormat,
    this.firstDate,
    this.lastDate,
    this.position = PopupMenuPosition.under,
    this.caption, // Add caption to constructor
    this.controller, // Add controller to constructor
  });

  @override
  Widget build(BuildContext context) {
    final format = dateFormat ?? DateFormat.yMMMM();

    return PopupMenuButton<DateTime>(
      position: position,
      tooltip: '', // Remove default 'Show menu' tooltip
      onSelected: onDateSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false, // Prevents menu from closing on calendar interaction
          child: SizedBox(
            width: 400, // Fixed width to accommodate Chinese characters
            height: 400, // Fixed height to show the calendar properly
            child: CalendarDatePicker(
              initialDate: date,
              firstDate: firstDate ?? DateTime(1900),
              lastDate: lastDate ?? DateTime(2100),
              onDateChanged: (date) {
                // Close the popup menu and notify the parent
                Navigator.pop(context, date);
              },
            ),
          ),
        ),
      ],
      child: Builder(
        builder: (context) => isCompact
            ? IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () {
                  PopupMenuButtonState<DateTime> button =
                      context.findAncestorStateOfType<
                          PopupMenuButtonState<DateTime>>()!;
                  button.showButtonMenu();
                },
              )
            : TextButton(
                onPressed: () {
                  PopupMenuButtonState<DateTime> button =
                      context.findAncestorStateOfType<
                          PopupMenuButtonState<DateTime>>()!;
                  button.showButtonMenu();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(caption ?? format.format(date)),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
      ),
    );
  }
}
