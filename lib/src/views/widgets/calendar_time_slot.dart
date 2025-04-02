import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';

import 'package:intl/intl.dart';

class CalendarTimeSlot extends StatelessWidget {
  final DateTime date;
  final CalendarController controller;
  final bool showDate;
  final DateFormat formatDate;
  final String? formatDatePrefix;
  final BoxDecoration? decoration;
  final BoxDecoration? todayDecoration;
  final Decoration? selectedDecoration;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final Alignment dateAlignment;
  final double todayCircleSize;
  final EdgeInsets datePadding;
  final bool isAllDay;
  final GlobalKey _key = GlobalKey();

  CalendarTimeSlot({
    super.key,
    required this.date,
    required this.controller,
    required this.showDate,
    required this.formatDate,
    this.formatDatePrefix,
    this.decoration,
    this.todayDecoration,
    this.selectedDecoration,
    this.textStyle,
    this.padding = EdgeInsets.zero,
    this.dateAlignment = Alignment.center,
    this.todayCircleSize = 50,
    this.datePadding = const EdgeInsets.only(top: 8),
    this.isAllDay = false,
  });

  /// Returns the render box offset of this time slot relative to the global position
  Offset? getOffset() {
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox.localToGlobal(Offset.zero);
  }

  /// Returns the size of the time slot
  Size? getSize() {
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final isSelected = date.isSameDay(controller.selectedDate);
    final isToday = date.isSameDay(DateTime.now());
    final gridLineColor = calendarTheme?.getGridLineColor(context) ??
        (theme.brightness == Brightness.light
            ? Colors.grey.withOpacity(0.2)
            : Colors.grey.withOpacity(0.3));

    // Get the appropriate background color based on whether it's an all-day slot
    Color? backgroundColor;
    if (isAllDay) {
      backgroundColor = calendarTheme?.getAllDayBackgroundColor(context);
    } else {
      backgroundColor = calendarTheme?.getSlotBackgroundColor(context);
    }

    return Container(
        key: _key,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            right: BorderSide(
              color: gridLineColor,
              width: 1.0, // Use full pixel border
            ),
            bottom: BorderSide(
              color: gridLineColor,
              width: 1.0, // Use full pixel border
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          // Use a ClipRect to ensure the InkWell effect is contained within the bounds
          child: ClipRect(
            child: InkWell(
              // Make sure the InkWell takes up the entire available space
              splashFactory: InkRipple.splashFactory,
              onTap: () => controller.selectDate(date),
              hoverColor: calendarTheme?.getHoverColor(context),
              child: Container(
                padding: padding,
                // Use a Column with MainAxisAlignment.start to align dates at the top
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDate)
                      Align(
                        alignment: dateAlignment,
                        child: Padding(
                          padding: datePadding,
                          child: _buildDateIndicator(context, isSelected,
                              isToday, calendarTheme, theme),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildDateIndicator(
    BuildContext context,
    bool isSelected,
    bool isToday,
    JazmineCalendarTheme? calendarTheme,
    ThemeData theme,
  ) {
    // Get the formatted date text to determine its length
    final String dateText = formatDate.format(date);

    // Use a rounded rectangle for dates with formats other than just the day number
    // or when the date text is longer than 2 characters
    final bool useRoundedRectangle = formatDate.pattern != 'd' ||
        dateText.length > 2 ||
        formatDatePrefix != null;

    // Calculate the width needed for the container based on text length
    final double containerWidth = useRoundedRectangle
        ? (dateText.length * 10.0 + 16.0)
            .clamp(todayCircleSize, 40.0) // Min width = circle size, max = 40
        : todayCircleSize;

    return Container(
      width: isToday || isSelected ? containerWidth : null,
      height: isToday || isSelected ? todayCircleSize : null,
      decoration: isSelected
          ? BoxDecoration(
              color: calendarTheme?.getSelectedDayColor(context) ??
                  theme.colorScheme.primary,
              shape: useRoundedRectangle ? BoxShape.rectangle : BoxShape.circle,
              borderRadius:
                  useRoundedRectangle ? BorderRadius.circular(16) : null,
            )
          : isToday
              ? BoxDecoration(
                  border: Border.all(
                    color: calendarTheme?.getTodayIndicatorColor(context) ??
                        theme.colorScheme.primary,
                    width: 1,
                  ),
                  shape: useRoundedRectangle
                      ? BoxShape.rectangle
                      : BoxShape.circle,
                  borderRadius:
                      useRoundedRectangle ? BorderRadius.circular(16) : null,
                )
              : null,
      child: Container(
        padding: useRoundedRectangle
            ? const EdgeInsets.symmetric(horizontal: 8)
            : null,
        child: Center(
          child: Text(
            '${formatDatePrefix ?? ''}$dateText',
            style: isSelected
                ? TextStyle(
                    color: theme.colorScheme.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  )
                : isToday
                    ? TextStyle(
                        color: calendarTheme?.getTodayIndicatorColor(context) ??
                            theme.colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      )
                    : calendarTheme?.getDateTextStyle(context),
          ),
        ),
      ),
    );
  }
}
