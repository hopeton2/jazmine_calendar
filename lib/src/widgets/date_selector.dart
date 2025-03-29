import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;
  final bool isCompact;
  final DateFormat? dateFormat;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final PopupMenuPosition position;
  final String? caption;  // New caption property

  const DateSelector({
    super.key,
    required this.date,
    required this.onDateSelected,
    this.isCompact = false,
    this.dateFormat,
    this.firstDate,
    this.lastDate,
    this.position = PopupMenuPosition.under,
    this.caption,  // Add caption to constructor
  });

  @override
  Widget build(BuildContext context) {
    final format = dateFormat ?? DateFormat.yMMMM();

    return PopupMenuButton<DateTime>(
      position: position,
      onSelected: onDateSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false, // Prevents menu from closing on calendar interaction
          child: SizedBox(
            width: 300,
            child: CalendarDatePicker(
              initialDate: date,
              firstDate: firstDate ?? DateTime(1900),
              lastDate: lastDate ?? DateTime(2100),
              onDateChanged: (date) {
                Navigator.pop(context, date);
              },
            ),
          ),
        ),
      ],
      child: Builder(
        builder: (context) => _DateSelectorButton(
          date: date,
          dateFormat: format,
          isCompact: isCompact,
          caption: caption,  // Pass caption to button
          onPressed: () {
            PopupMenuButtonState<DateTime> button = 
                context.findAncestorStateOfType<PopupMenuButtonState<DateTime>>()!;
            button.showButtonMenu();
          },
        ),
      ),
    );
  }
}

class _DateSelectorButton extends StatelessWidget {
  final DateTime date;
  final DateFormat dateFormat;
  final bool isCompact;
  final VoidCallback onPressed;
  final String? caption;  // Add caption property

  const _DateSelectorButton({
    required this.date,
    required this.dateFormat,
    required this.isCompact,
    required this.onPressed,
    this.caption,  // Add caption to constructor
  });

  @override
  Widget build(BuildContext context) {
    return isCompact
        ? IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: onPressed,
          )
        : TextButton(
            onPressed: onPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(caption ?? dateFormat.format(date)),  // Use caption if available
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          );
  }
}
