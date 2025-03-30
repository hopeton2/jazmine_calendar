import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/widgets/enhanced_date_picker_new.dart';
import 'package:jazmine_calendar/src/widgets/month_selector.dart';

/// A date picker that combines month and day selection views with a toggle
/// and dynamically adjusts its height to show all dates without scrolling.
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
  
  // Height for the date view - will be adjusted dynamically
  double _dateViewHeight = 400.0; // Start with a reasonable default
  
  // Key for measuring the content
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    
    // Schedule a post-frame callback to measure and adjust height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adjustHeightIfNeeded();
    });
  }
  
  // Method to adjust height based on content size
  void _adjustHeightIfNeeded() {
    if (_contentKey.currentContext != null && !_showMonthPicker) {
      final RenderBox renderBox = _contentKey.currentContext!.findRenderObject() as RenderBox;
      final Size size = renderBox.size;
      
      // Get screen height
      final screenHeight = MediaQuery.of(context).size.height;
      
      // Calculate ideal height (80% of screen or minimum 600px)
      final idealHeight = screenHeight * 0.8;
      
      // If our content is taller than current height but less than ideal height
      if (size.height > _dateViewHeight && size.height < idealHeight) {
        setState(() {
          _dateViewHeight = size.height;
        });
      } else if (idealHeight > _dateViewHeight) {
        // If we can go taller based on screen size
        setState(() {
          _dateViewHeight = idealHeight;
        });
      }
    }
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
    
    // Use LayoutBuilder to get the available width and height
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        
        // Calculate heights for different components
        const headerHeight = 40.0; // Height for the header
        final contentHeight = availableHeight - headerHeight;
        
        return Column(
          children: [
            // Month view header with forward arrow to date view
            if (_showMonthPicker)
              SizedBox(
                height: headerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Year/month display
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          DateFormat.yMMMM().format(_currentDate),
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
                            // Schedule height adjustment after view change
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _adjustHeightIfNeeded();
                            });
                          });
                        },
                        icon: Text(
                          'Date',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        label: Icon(Icons.chevron_right, color: colorScheme.primary),
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
            SizedBox(
              height: contentHeight,
              child: _showMonthPicker
                  ? MonthPicker(
                      initialDate: _currentDate,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      onMonthSelected: _handleMonthSelected,
                    )
                  : SizedBox(
                      key: _contentKey,
                      height: _dateViewHeight,
                      child: EnhancedDatePicker(
                        initialDate: _currentDate,
                        firstDate: widget.firstDate,
                        lastDate: widget.lastDate,
                        onDateChanged: _handleDaySelected,
                        initialCalendarMode: DatePickerMode.day,
                        onBackToMonthView: _showMonthView,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
