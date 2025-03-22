import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/jazmine_calendar_theme.dart';

abstract class BaseCalendarView extends StatelessWidget {
  const BaseCalendarView({super.key});

  Widget buildEventTile(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final calendarTheme = theme.extension<JazmineCalendarTheme>();
    final brightness = theme.brightness;
    final primaryColor = theme.colorScheme.primary;
    
    final backgroundColor = brightness == Brightness.light
        ? calendarTheme?.getEventBackgroundColor(context) ?? primaryColor
        : calendarTheme?.getEventBackgroundColor(context) ?? primaryColor.withOpacity(0.7);
    
    final textColor = brightness == Brightness.light
        ? calendarTheme?.eventTextColor ?? Colors.white
        : calendarTheme?.eventTextColorDark ?? Colors.white;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Handle event tap
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            event.title,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
