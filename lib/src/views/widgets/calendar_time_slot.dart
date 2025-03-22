import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/extensions/date_extensions.dart';
import '../../../jazmine_calendar.dart';
import 'event_tile_builder.dart';
import 'package:intl/intl.dart';

class CalendarTimeSlot extends StatelessWidget {
  final DateTime date;
  final List<Event> events;
  final List<Event> allDayEvents;
  final JazmineCalendarController controller;
  final bool showDate;
  final bool Function(Event) isFirstDayOfEvent;
  final bool Function(Event) isLastDayOfEvent;
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

  const CalendarTimeSlot({
    super.key,
    required this.date,
    required this.events,
    required this.allDayEvents,
    required this.controller,
    required this.showDate,
    required this.isFirstDayOfEvent,
    required this.isLastDayOfEvent,
    required this.formatDate,
    this.formatDatePrefix,
    this.decoration,
    this.todayDecoration,
    this.selectedDecoration,
    this.textStyle,
    this.padding = EdgeInsets.zero,
    this.dateAlignment = Alignment.center,
    this.todayCircleSize = 50,  // Increased from 40 to 50
    this.datePadding = const EdgeInsets.only(top: 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final isSelected = date.isSameDay(controller.selectedDate);
    final isToday = date.isSameDay(DateTime.now());

    return Material(
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
                              color: calendarTheme?.getSelectedDayColor(context) ?? theme.colorScheme.primary,
                              shape: formatDatePrefix != null ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: formatDatePrefix != null ? BorderRadius.circular(25) : null,
                            )
                          : isToday
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: calendarTheme?.getTodayIndicatorColor(context) ?? theme.colorScheme.primary,
                                    width: 1,
                                  ),
                                  shape: formatDatePrefix != null ? BoxShape.rectangle : BoxShape.circle,
                                  borderRadius: formatDatePrefix != null ? BorderRadius.circular(25) : null,
                                )
                              : null,
                      child: Container(
                        padding: formatDatePrefix != null ? const EdgeInsets.symmetric(horizontal: 8) : null,
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
                                        color: calendarTheme?.getTodayIndicatorColor(context) ?? theme.colorScheme.primary,
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
              Expanded(
                child: ListView.builder(
                  padding: padding,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return EventTileBuilder().buildEventTile(context, events[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
