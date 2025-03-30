import 'package:flutter/material.dart';

/// A calendar date picker with enhanced styling for larger selection circles
/// that better matches the standard Material Design date picker
class EnhancedDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;
  final DatePickerMode initialCalendarMode;
  final bool Function(DateTime)? selectableDayPredicate;
  final VoidCallback? onBackToMonthView;

  const EnhancedDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    this.initialCalendarMode = DatePickerMode.day,
    this.selectableDayPredicate,
    this.onBackToMonthView,
  });

  @override
  State<EnhancedDatePicker> createState() => _EnhancedDatePickerState();
}

class _EnhancedDatePickerState extends State<EnhancedDatePicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  late DatePickerMode _currentView;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _currentView = widget.initialCalendarMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Theme(
      // Apply a theme that enhances the date picker appearance
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme,
      ),
      child: Column(children: [
        // Back to month view button (if provided)
        if (widget.onBackToMonthView != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
              child: TextButton.icon(
                onPressed: widget.onBackToMonthView,
                icon: Icon(Icons.chevron_left, color: colorScheme.primary),
                label: Text(
                  'Month',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  minimumSize: const Size(0, 30),
                ),
              ),
            ),
          ),

        // Add space between back button and navigation header
        const SizedBox(height: 4.0),

        // Month navigation header
        _buildHeader(),

        // Calendar grid
        Expanded(child: _buildCalendar()),
      ]),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Month/year display as simple text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  _getMonthYearText(),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previous month button
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                    tooltip: 'Previous month',
                  ),

                  // Next month button
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                    tooltip: 'Next month',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthYearText() {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  Widget _buildCalendar() {
    if (_currentView == DatePickerMode.year) {
      return _buildYearPicker();
    } else {
      return _buildMonthView();
    }
  }

  Widget _buildYearPicker() {
    // Implement year picker if needed
    return Container(); // Placeholder
  }

  Widget _buildMonthView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate the first day of the month
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);

    // Calculate the day of week (0 = Sunday, 1 = Monday, etc.)
    int firstWeekdayOfMonth = firstDayOfMonth.weekday % 7;

    // Calculate days in month
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    // Use LayoutBuilder to get available height
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate ideal row height based on available space
        // We need space for weekday headers + 6 rows of dates
        final availableHeight = constraints.maxHeight;
        const weekdayHeaderHeight = 30.0; // Reduced height for weekday header
        final gridHeight = availableHeight - weekdayHeaderHeight;

        return Column(
          children: [
            // Weekday headers
            SizedBox(
              height: weekdayHeaderHeight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2.0, top: 2.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final cellWidth =
                        availableWidth / 7; // Divide available width by 7 days

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                          SizedBox(
                            width: cellWidth,
                            child: Center(
                              child: Text(
                                day,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Calendar grid
            SizedBox(
              height: gridHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // We're using fixed sizes, so we don't need to calculate based on constraints

                  // Use a fixed aspect ratio that ensures all dates fit
                  // We don't need to calculate dynamically since we're using a fixed height
                  return GridView.builder(
                    // Allow scrolling if needed
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      // Use a fixed aspect ratio that ensures all dates fit
                      childAspectRatio:
                          1.0, // Square cells for a more compact layout
                      mainAxisSpacing: 2.0, // Minimal spacing between rows
                      crossAxisSpacing: 2.0, // Minimal spacing between columns
                    ),
                    itemCount: 42, // 6 weeks * 7 days
                    itemBuilder: (context, index) {
                      // Calculate the day number
                      final int day = index - firstWeekdayOfMonth + 1;

                      // Check if the day is within the current month
                      final bool isCurrentMonth = day > 0 && day <= daysInMonth;

                      if (!isCurrentMonth) {
                        return const SizedBox.shrink();
                      }

                      // Create the date for this cell
                      final date = DateTime(
                          _currentMonth.year, _currentMonth.month, day);

                      // Check if this date is selectable
                      final bool isSelectable =
                          widget.selectableDayPredicate == null ||
                              widget.selectableDayPredicate!(date);

                      // Check if this is the selected date
                      final bool isSelected = _selectedDate.year == date.year &&
                          _selectedDate.month == date.month &&
                          _selectedDate.day == date.day;

                      // Check if this is today
                      final now = DateTime.now();
                      final bool isToday = now.year == date.year &&
                          now.month == date.month &&
                          now.day == date.day;

                      // Use a fixed circle size that works well with the grid
                      const circleSize =
                          36.0; // Larger fixed size for better visibility

                      return GestureDetector(
                        onTap: isSelectable ? () => _selectDate(date) : null,
                        child: Center(
                          child: Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? colorScheme.primary
                                  : isToday
                                      ? colorScheme.primary.withOpacity(0.12)
                                      : Colors.transparent,
                              // Add border for today's date to match Flutter date picker
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: colorScheme.primary, width: 1.0)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                day.toString(),
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : !isSelectable
                                          ? colorScheme.onSurface
                                              .withOpacity(0.38)
                                          : isToday
                                              ? colorScheme.primary
                                              : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateChanged(date);
  }
}
