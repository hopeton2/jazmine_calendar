import 'package:flutter/material.dart';

/// Interface for time calculation services
abstract class TimeCalculationService {
  /// Calculate the position for a specific time
  double calculateTimePosition(DateTime time, DateTime viewStart, DateTime viewEnd, Size availableSpace);
  
  /// Calculate the size for a duration
  double calculateSizeForDuration(Duration duration, DateTime viewStart, DateTime viewEnd, Size availableSpace);
}

/// Implementation for day view time calculations
class DayViewTimeCalculationService implements TimeCalculationService {
  @override
  double calculateTimePosition(DateTime time, DateTime viewStart, DateTime viewEnd, Size availableSpace) {
    // For day view, we calculate based on hours and minutes
    final startHour = time.hour;
    final startMinute = time.minute;
    final totalMinutesSinceStart = (startHour * 60) + startMinute;
    
    // Calculate the position based on the time
    // For a 24-hour day view, each hour is 1/24 of the available height
    final hourHeight = availableSpace.height / 24;
    final minuteHeight = hourHeight / 60;
    
    return totalMinutesSinceStart * minuteHeight;
  }
  
  @override
  double calculateSizeForDuration(Duration duration, DateTime viewStart, DateTime viewEnd, Size availableSpace) {
    // Calculate the size based on minutes
    final hourHeight = availableSpace.height / 24;
    final minuteHeight = hourHeight / 60;
    
    return duration.inMinutes * minuteHeight;
  }
}

/// Factory for creating the appropriate time calculation service
class TimeCalculationServiceFactory {
  static TimeCalculationService createService(CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.day:
      case CalendarViewType.week:
      case CalendarViewType.workWeek:
        return DayViewTimeCalculationService();
      default:
        throw UnimplementedError('Time calculation not implemented for $viewType');
    }
  }
}

/// Enum for calendar view types
enum CalendarViewType {
  day,
  week,
  workWeek,
  month,
  timeline,
  agenda,
}
