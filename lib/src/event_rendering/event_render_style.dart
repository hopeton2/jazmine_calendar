import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';

/// Style configuration for event rendering
class EventRenderStyle {
  /// Corner radius for event rectangles
  final double cornerRadius;

  /// Padding inside events
  final EdgeInsets contentPadding;

  /// Style for event title text
  final TextStyle titleStyle;

  /// Style for event time text
  final TextStyle timeStyle;

  /// Style for event location text
  final TextStyle locationStyle;

  /// Default color for events
  final Color defaultEventColor;

  /// Map of category names to colors
  final Map<String, Color> categoryColors;

  /// Whether to show event time
  final bool showTime;

  /// Whether to show event location
  final bool showLocation;

  /// Resize handle size
  final double resizeHandleSize;

  /// Resize handle color
  final Color resizeHandleColor;

  /// Creates a new EventRenderStyle
  const EventRenderStyle({
    this.cornerRadius = 4.0,
    this.contentPadding = const EdgeInsets.all(4.0),
    this.titleStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
    this.timeStyle = const TextStyle(
      color: Colors.white,
      fontSize: 10,
    ),
    this.locationStyle = const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontStyle: FontStyle.italic,
    ),
    this.defaultEventColor = Colors.blue,
    this.categoryColors = const {},
    this.showTime = true,
    this.showLocation = true,
    this.resizeHandleSize = 6.0,
    this.resizeHandleColor = Colors.white,
  });

  /// Get the color for an event
  Color getColorForEvent(CalendarEvent event) {
    // Use event's color if provided
    if (event.color != null) {
      return event.color!;
    }

    // Fall back to default color
    return defaultEventColor;
  }

  /// Create a copy with some properties changed
  EventRenderStyle copyWith({
    double? cornerRadius,
    EdgeInsets? contentPadding,
    TextStyle? titleStyle,
    TextStyle? timeStyle,
    TextStyle? locationStyle,
    Color? defaultEventColor,
    Map<String, Color>? categoryColors,
    bool? showTime,
    bool? showLocation,
    double? resizeHandleSize,
    Color? resizeHandleColor,
  }) {
    return EventRenderStyle(
      cornerRadius: cornerRadius ?? this.cornerRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      titleStyle: titleStyle ?? this.titleStyle,
      timeStyle: timeStyle ?? this.timeStyle,
      locationStyle: locationStyle ?? this.locationStyle,
      defaultEventColor: defaultEventColor ?? this.defaultEventColor,
      categoryColors: categoryColors ?? this.categoryColors,
      showTime: showTime ?? this.showTime,
      showLocation: showLocation ?? this.showLocation,
      resizeHandleSize: resizeHandleSize ?? this.resizeHandleSize,
      resizeHandleColor: resizeHandleColor ?? this.resizeHandleColor,
    );
  }
}
