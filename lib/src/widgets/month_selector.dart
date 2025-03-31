import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';
import 'package:jazmine_calendar/src/widgets/dual_view_date_picker.dart';

/// A widget that displays a button which opens a month picker when pressed.
class MonthSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onMonthSelected;
  final bool isCompact;
  final DateFormat? dateFormat;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final PopupMenuPosition position;
  final String? caption;
  final bool allowDaySelection; // New property to allow day selection

  const MonthSelector({
    super.key,
    required this.date,
    required this.onMonthSelected,
    this.isCompact = false,
    this.dateFormat,
    this.firstDate,
    this.lastDate,
    this.position = PopupMenuPosition.under,
    this.caption,
    this.allowDaySelection = true, // Default to combined month/day selection
  });

  @override
  Widget build(BuildContext context) {
    final format = dateFormat ?? DateFormat.yMMMM();

    return PopupMenuButton<DateTime>(
      position: position,
      tooltip: '', // Remove default 'Show menu' tooltip
      onSelected: onMonthSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false, // Prevents menu from closing on calendar interaction
          child: SizedBox(
            width: 400, // Fixed width to accommodate Chinese characters
            child: allowDaySelection
                ? DualViewDatePicker(
                    initialDate: date,
                    firstDate: firstDate ?? DateTime(1900),
                    lastDate: lastDate ?? DateTime(2100),
                    onDateSelected: (date) {
                      // Safely pop the context with the selected date
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, date);
                      }
                    },
                  )
                : MonthPicker(
                    initialDate: date,
                    firstDate: firstDate ?? DateTime(1900),
                    lastDate: lastDate ?? DateTime(2100),
                    onMonthSelected: (date) {
                      // Safely pop the context with the selected date
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, date);
                      }
                    },
                  ),
          ),
        ),
      ],
      child: Builder(
        builder: (context) => _MonthSelectorButton(
          date: date,
          dateFormat: format,
          isCompact: isCompact,
          caption: caption,
          onPressed: () {
            // Find the popup menu button state safely
            final PopupMenuButtonState<DateTime>? button = context
                .findAncestorStateOfType<PopupMenuButtonState<DateTime>>();
            if (button != null) {
              button.showButtonMenu();
            }
          },
        ),
      ),
    );
  }
}

class _MonthSelectorButton extends StatelessWidget {
  final DateTime date;
  final DateFormat dateFormat;
  final bool isCompact;
  final VoidCallback onPressed;
  final String? caption;

  const _MonthSelectorButton({
    required this.date,
    required this.dateFormat,
    required this.isCompact,
    required this.onPressed,
    this.caption,
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
                Text(caption ?? dateFormat.format(date)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          );
  }
}

/// A widget that allows selecting a month and year.
class MonthPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onMonthSelected;

  const MonthPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onMonthSelected,
  });

  @override
  State<MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker>
    with SingleTickerProviderStateMixin {
  late DateTime _currentDisplayedYear;
  late PageController _pageController;
  late AnimationController _animationController;

  // Get localized month names based on the current locale
  List<String> _getLocalizedMonthNames(BuildContext context,
      {bool abbreviated = false}) {
    final locale = CalendarLocalization.of(context).locale.languageCode;
    final months = <String>[];

    // Generate month names using DateFormat for the current locale
    for (int i = 0; i < 12; i++) {
      final date = DateTime(2023, i + 1, 1); // Use any year
      // Use MMM for abbreviated month names, MMMM for full month names
      final format = abbreviated ? 'MMM' : 'MMMM';
      months.add(DateFormat(format, locale).format(date));
    }

    return months;
  }

  @override
  void initState() {
    super.initState();
    _currentDisplayedYear = DateTime(widget.initialDate.year);

    // Initialize the page controller with the initial year index
    // We use a large initial page number to allow for "infinite" scrolling
    _pageController = PageController(
      initialPage: widget.initialDate.year - widget.firstDate.year,
    );

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

  bool _isYearInRange(int year) {
    return year >= widget.firstDate.year && year <= widget.lastDate.year;
  }

  bool _isMonthInRange(int year, int month) {
    if (year == widget.firstDate.year && month < widget.firstDate.month) {
      return false;
    }
    if (year == widget.lastDate.year && month > widget.lastDate.month) {
      return false;
    }
    return true;
  }

  void _previousYear() {
    if (_isYearInRange(_currentDisplayedYear.year - 1)) {
      // Animate to the previous page
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextYear() {
    if (_isYearInRange(_currentDisplayedYear.year + 1)) {
      // Animate to the next page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Handle page change
  void _handlePageChanged(int page) {
    final year = widget.firstDate.year + page;
    if (_isYearInRange(year)) {
      setState(() {
        _currentDisplayedYear = DateTime(year);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Year selector
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          color: colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: _isYearInRange(_currentDisplayedYear.year - 1)
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.38),
                ),
                onPressed: _isYearInRange(_currentDisplayedYear.year - 1)
                    ? _previousYear
                    : null,
              ),
              GestureDetector(
                onTap: () {
                  // Could add year picker here in the future
                },
                child: Text(
                  // Use localized year format
                  DateFormat('y',
                          CalendarLocalization.of(context).locale.languageCode)
                      .format(_currentDisplayedYear),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _isYearInRange(_currentDisplayedYear.year + 1)
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.38),
                ),
                onPressed: _isYearInRange(_currentDisplayedYear.year + 1)
                    ? _nextYear
                    : null,
              ),
            ],
          ),
        ),

        // Month grid with horizontal scrolling
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            itemCount: widget.lastDate.year - widget.firstDate.year + 1,
            itemBuilder: (context, pageIndex) {
              final year = widget.firstDate.year + pageIndex;

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate ideal row height based on available height
                  final availableHeight = constraints.maxHeight;
                  final rowHeight = availableHeight / 4; // 4 rows of months
                  final cellWidth = constraints.maxWidth / 3; // 3 columns
                  final aspectRatio = cellWidth / rowHeight;

                  return GridView.builder(
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable grid scrolling
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: aspectRatio.clamp(1.0, 2.0),
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final isEnabled = _isMonthInRange(year, month);
                      final isSelected = widget.initialDate.year == year &&
                          widget.initialDate.month == month;

                      // Match the style of the standard date picker
                      const double itemSize =
                          36.0; // Standard size for selected circle

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(itemSize / 2),
                          onTap: isEnabled
                              ? () {
                                  final selectedDate = DateTime(
                                    year,
                                    month,
                                    1,
                                  );
                                  widget.onMonthSelected(selectedDate);
                                }
                              : null,
                          child: Center(
                            child: Container(
                              width: itemSize,
                              height: itemSize,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getLocalizedMonthNames(context,
                                      abbreviated: true)[index],
                                  style: isSelected
                                      ? textTheme.labelLarge?.copyWith(
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : textTheme.labelLarge?.copyWith(
                                          color: isEnabled
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurface
                                                  .withOpacity(0.38),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
