import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';

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
  final CalendarController? controller;

  const EnhancedDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    this.initialCalendarMode = DatePickerMode.day,
    this.selectableDayPredicate,
    this.onBackToMonthView,
    this.controller,
  });

  @override
  State<EnhancedDatePicker> createState() => _EnhancedDatePickerState();
}

class _EnhancedDatePickerState extends State<EnhancedDatePicker>
    with SingleTickerProviderStateMixin {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  late DatePickerMode _currentView;
  late PageController _pageController;
  late AnimationController _animationController;

  // Calculate the number of months between two dates
  int _monthDelta(DateTime startDate, DateTime endDate) {
    return (endDate.year - startDate.year) * 12 +
        endDate.month -
        startDate.month;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _currentView = widget.initialCalendarMode;

    // Initialize the page controller with the initial month index
    // We calculate the month delta from firstDate to initialDate
    final initialPage = _monthDelta(widget.firstDate, _currentMonth);
    _pageController = PageController(initialPage: initialPage);

    // Initialize the animation controller for smooth transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
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
                  CalendarLocalization.of(context).monthLabel,
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
                    tooltip: CalendarLocalization.of(context).previousMonth,
                  ),

                  // Next month button
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                    tooltip: CalendarLocalization.of(context).nextMonth,
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
    // Use localized month and year format
    return CalendarLocalization.of(context).formatMonthYear(_currentMonth);
  }

  void _previousMonth() {
    // Animate to the previous page
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMonth() {
    // Animate to the next page
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Handle page change
  void _handlePageChanged(int page) {
    // Calculate the new month based on the page index
    final monthsToAdd = page - _monthDelta(widget.firstDate, _currentMonth);
    final newMonth =
        DateTime(_currentMonth.year, _currentMonth.month + monthsToAdd);

    setState(() {
      _currentMonth = newMonth;
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

    // Calculate the total number of months between firstDate and lastDate
    final monthCount = _monthDelta(widget.firstDate, widget.lastDate) + 1;

    // Use LayoutBuilder to get available height
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate ideal row height based on available space
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
                        // Get localized weekday abbreviations
                        // For Spanish (es), the order should be: L M X J V S D
                        // For English (en), the order should be: S M T W T F S
                        for (int i = 0; i < 7; i++)
                          SizedBox(
                            width: cellWidth,
                            child: Center(
                              child: Text(
                                // Get the weekday abbreviation based on locale and firstDayOfWeek
                                () {
                                  // Get the first day of week from controller or use locale-based default
                                  int firstDayOfWeek;
                                  if (widget.controller != null) {
                                    // Use the controller's firstDayOfWeek if available
                                    firstDayOfWeek =
                                        widget.controller!.firstDayOfWeek;
                                  } else {
                                    // Otherwise, determine based on locale
                                    final locale =
                                        CalendarLocalization.of(context)
                                            .locale
                                            .languageCode;
                                    firstDayOfWeek = CalendarController
                                        .getFirstDayOfWeekForLocale(locale);
                                  }

                                  final locale =
                                      CalendarLocalization.of(context)
                                          .locale
                                          .languageCode;

                                  // Get the appropriate weekday abbreviations for the locale
                                  List<String> weekdays;
                                  if (locale == 'es') {
                                    // Spanish weekday abbreviations
                                    weekdays = [
                                      'L',
                                      'M',
                                      'X',
                                      'J',
                                      'V',
                                      'S',
                                      'D'
                                    ];
                                  } else if (locale == 'fr') {
                                    // French weekday abbreviations
                                    weekdays = [
                                      'L',
                                      'M',
                                      'M',
                                      'J',
                                      'V',
                                      'S',
                                      'D'
                                    ];
                                  } else if (locale == 'de') {
                                    // German weekday abbreviations
                                    weekdays = [
                                      'M',
                                      'D',
                                      'M',
                                      'D',
                                      'F',
                                      'S',
                                      'S'
                                    ];
                                  } else if (locale == 'hi') {
                                    // Hindi weekday abbreviations
                                    weekdays = [
                                      'सो',
                                      'मं',
                                      'बु',
                                      'गु',
                                      'शु',
                                      'श',
                                      'र'
                                    ];
                                  } else if (locale == 'zh') {
                                    // Chinese weekday abbreviations
                                    weekdays = [
                                      '一',
                                      '二',
                                      '三',
                                      '四',
                                      '五',
                                      '六',
                                      '日'
                                    ];
                                  } else {
                                    // English weekday abbreviations
                                    weekdays = [
                                      'M',
                                      'T',
                                      'W',
                                      'T',
                                      'F',
                                      'S',
                                      'S'
                                    ];
                                    // For English, we need special handling since the default is Sunday-first
                                    if (firstDayOfWeek == DateTime.sunday) {
                                      weekdays = [
                                        'S',
                                        'M',
                                        'T',
                                        'W',
                                        'T',
                                        'F',
                                        'S'
                                      ];
                                    }
                                  }

                                  // Reorder the weekdays based on firstDayOfWeek
                                  // For non-English locales with Sunday-first, we need to move the last item to the front
                                  if (locale != 'en' &&
                                      firstDayOfWeek == DateTime.sunday) {
                                    // Move the last item (Sunday) to the front
                                    final sunday = weekdays.removeLast();
                                    weekdays.insert(0, sunday);
                                  }

                                  return weekdays[i];
                                }(),
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

            // Calendar grid with horizontal scrolling
            SizedBox(
              height: gridHeight,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _handlePageChanged,
                itemCount: monthCount,
                itemBuilder: (context, pageIndex) {
                  // Calculate the month for this page
                  final pageMonth = DateTime(
                    widget.firstDate.year,
                    widget.firstDate.month + pageIndex,
                  );

                  // Calculate the first day of the month
                  final firstDayOfMonth =
                      DateTime(pageMonth.year, pageMonth.month, 1);

                  // Get the first day of week from controller or use locale-based default
                  int firstDayOfWeek;
                  if (widget.controller != null) {
                    // Use the controller's firstDayOfWeek if available
                    firstDayOfWeek = widget.controller!.firstDayOfWeek;
                  } else {
                    // Otherwise, determine based on locale
                    final locale =
                        CalendarLocalization.of(context).locale.languageCode;
                    firstDayOfWeek =
                        CalendarController.getFirstDayOfWeekForLocale(locale);
                  }

                  // Calculate the first weekday of month based on the first day of week
                  // Convert from 1-7 (Monday=1, Sunday=7) to 0-6 (firstDayOfWeek=0)
                  int firstWeekdayOfMonth =
                      (firstDayOfMonth.weekday - firstDayOfWeek) % 7;
                  if (firstWeekdayOfMonth < 0) firstWeekdayOfMonth += 7;

                  // Calculate days in month
                  final daysInMonth =
                      DateTime(pageMonth.year, pageMonth.month + 1, 0).day;

                  return GridView.builder(
                    // Disable scrolling since we're using PageView for horizontal scrolling
                    physics: const NeverScrollableScrollPhysics(),
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
                      final date =
                          DateTime(pageMonth.year, pageMonth.month, day);

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
                                // Use locale-aware date formatting
                                DateFormat.d(CalendarLocalization.of(context)
                                        .locale
                                        .languageCode)
                                    .format(date),
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
