import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';

import 'package:intl/intl.dart';

class CalendarTimeSlot extends StatelessWidget {
  final DateTime date;
  final JazmineCalendarController controller;
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
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox.localToGlobal(Offset.zero);
  }

  /// Returns the size of the time slot
  Size? getSize() {
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final isSelected = date.isSameDay(controller.selectedDate);
    final isToday = date.isSameDay(DateTime.now());

    return Material(
      key: _key,
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.selectDate(date),
        hoverColor: calendarTheme?.getHoverColor(context),
        child: Container(
          decoration: decoration,
          child: Column(
            children: [
              if (showDate) ...[
                Padding(
                  padding: datePadding,
                  child: Align(
                    alignment: dateAlignment,
                    child: Container(
                      width: isToday || isSelected ? todayCircleSize : null,
                      height: isToday || isSelected ? todayCircleSize : null,
                      decoration: isSelected
                          ? BoxDecoration(
                              color:
                                  calendarTheme?.getSelectedDayColor(context) ??
                                      theme.colorScheme.primary,
                              shape: formatDatePrefix != null
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: formatDatePrefix != null
                                  ? BorderRadius.circular(25)
                                  : null,
                            )
                          : isToday
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: calendarTheme
                                            ?.getTodayIndicatorColor(context) ??
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
                                        color: calendarTheme
                                                ?.getTodayIndicatorColor(
                                                    context) ??
                                            theme.colorScheme.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      )
                                    : calendarTheme?.getDateTextStyle(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
