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
            width: 0.5,
          ),
          bottom: BorderSide(
            color: gridLineColor,
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.selectDate(date),
          hoverColor: calendarTheme?.getHoverColor(context),
          child: Container(
            padding: padding,
            child: Column(
              children: [
                if (showDate) ...[
                  Padding(
                    padding: datePadding,
                    child: _buildDateIndicator(
                        context, isSelected, isToday, calendarTheme, theme),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateIndicator(
    BuildContext context,
    bool isSelected,
    bool isToday,
    JazmineCalendarTheme? calendarTheme,
    ThemeData theme,
  ) {
    return Align(
      alignment: dateAlignment,
      child: Container(
        width: isToday || isSelected ? todayCircleSize : null,
        height: isToday || isSelected ? todayCircleSize : null,
        decoration: isSelected
            ? BoxDecoration(
                color: calendarTheme?.getSelectedDayColor(context) ??
                    theme.colorScheme.primary,
                shape: formatDatePrefix != null
                    ? BoxShape.rectangle
                    : BoxShape.circle,
                borderRadius:
                    formatDatePrefix != null ? BorderRadius.circular(25) : null,
              )
            : isToday
                ? BoxDecoration(
                    border: Border.all(
                      color: calendarTheme?.getTodayIndicatorColor(context) ??
                          theme.colorScheme.primary,
                      width: 1,
                    ),
                    shape: formatDatePrefix != null
                        ? BoxShape.rectangle
                        : BoxShape.circle,
                    borderRadius: formatDatePrefix != null
                        ? BorderRadius.circular(25)
                        : null,
                  )
                : null,
        child: Container(
          padding: formatDatePrefix != null
              ? const EdgeInsets.symmetric(horizontal: 8)
              : null,
          child: Center(
            child: Text(
              '${formatDatePrefix ?? ''}${formatDate.format(date)}',
              style: isSelected
                  ? TextStyle(
                      color: theme.colorScheme.surface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )
                  : isToday
                      ? TextStyle(
                          color:
                              calendarTheme?.getTodayIndicatorColor(context) ??
                                  theme.colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        )
                      : calendarTheme?.getDateTextStyle(context),
            ),
          ),
        ),
      ),
    );
  }
}
