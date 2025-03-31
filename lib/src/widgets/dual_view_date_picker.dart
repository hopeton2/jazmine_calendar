import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';
import 'package:jazmine_calendar/src/widgets/enhanced_date_picker.dart';
import 'package:jazmine_calendar/src/widgets/month_selector.dart';

/// A date picker that combines month and day selection views with a toggle
class DualViewDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const DualViewDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  State<DualViewDatePicker> createState() => _DualViewDatePickerState();
}

class _DualViewDatePickerState extends State<DualViewDatePicker> {
  late DateTime _currentDate;
  bool _showMonthPicker = true; // Start with month picker

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
  }

  void _handleMonthSelected(DateTime date) {
    setState(() {
      _currentDate = date;
      // If we're in month-only mode (toggle is off), directly select the month
      if (_showMonthPicker) {
        // We're in month view, so directly select the month
        widget.onDateSelected(DateTime(date.year, date.month, 1));
      } else {
        // We're in day view, so just update the current date
        // (user will need to select a specific day)
        _currentDate = date;
      }
    });
  }

  void _handleDaySelected(DateTime date) {
    widget.onDateSelected(date);
  }

  void _showMonthView() {
    setState(() {
      _showMonthPicker = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Use a simple Column layout
    return Column(
      children: [
        // Month view header with forward arrow to date view
        if (_showMonthPicker)
          SizedBox(
            height: 40.0, // Fixed header height
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Year/month display
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      CalendarLocalization.of(context)
                          .formatMonthYear(_currentDate),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  // Forward to date view button - styled like back button
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showMonthPicker = false;
                      });
                    },
                    icon: Text(
                      CalendarLocalization.of(context).dateLabel,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    label:
                        Icon(Icons.chevron_right, color: colorScheme.primary),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minimumSize: const Size(0, 30),
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Content area - use all remaining space
        Expanded(
          child: _showMonthPicker
              ? MonthPicker(
                  initialDate: _currentDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onMonthSelected: _handleMonthSelected,
                )
              : EnhancedDatePicker(
                  initialDate: _currentDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onDateChanged: _handleDaySelected,
                  initialCalendarMode: DatePickerMode.day,
                  onBackToMonthView: _showMonthView,
                ),
        ),
      ],
    );
  }
}
