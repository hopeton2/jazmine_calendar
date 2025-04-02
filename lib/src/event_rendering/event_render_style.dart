import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/enums/enums.dart'; // Import enums

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

  /// Horizontal spacing between packed events in pixels.
  final double horizontalSpacing;

  /// Margin on the right side of the event area in pixels.
  final double rightMargin;

  /// Whether to allow events to span multiple columns if space is available.
  // final bool allowColumnSpanning; // Removed in favor of spanningMode

  /// Defines the column spanning behavior for overlapping events.
  final EventSpanningMode spanningMode;

  /// Width of the indicator line shown on the left for vertical events.
  final double verticalIndicatorWidth;

  /// Color of the indicator line shown on the left for vertical events.
  /// If null, the event's primary color is used.
  final Color? verticalIndicatorColor;

  /// Specific padding for all-day (horizontal) events. If null, uses `contentPadding`.
  final EdgeInsets? allDayContentPadding;

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
    this.horizontalSpacing = 3.0,
    this.rightMargin = 10.0,
    this.spanningMode = EventSpanningMode.strict,
    this.verticalIndicatorWidth = 2.0, // Default width
    this.verticalIndicatorColor, // Default null (use event color)
    this.allDayContentPadding = const EdgeInsets.only(top: 5, bottom: 20, left: 4, right: 4), // Specific padding
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
    double? horizontalSpacing,
    double? rightMargin,
    EventSpanningMode? spanningMode,
    double? verticalIndicatorWidth,
    Color? verticalIndicatorColor,
    EdgeInsets? allDayContentPadding,
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
      horizontalSpacing: horizontalSpacing ?? this.horizontalSpacing,
      rightMargin: rightMargin ?? this.rightMargin,
      spanningMode: spanningMode ?? this.spanningMode,
      verticalIndicatorWidth: verticalIndicatorWidth ?? this.verticalIndicatorWidth,
      verticalIndicatorColor: verticalIndicatorColor ?? this.verticalIndicatorColor,
      allDayContentPadding: allDayContentPadding ?? this.allDayContentPadding,
    );
  }
}
