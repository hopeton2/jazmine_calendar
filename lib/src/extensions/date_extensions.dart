extension DateTimeExtensions on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get firstDayOfMonth => DateTime(year, month, 1);
  
  DateTime get lastDayOfMonth => DateTime(year, month + 1, 0);

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isToday() {
    final now = DateTime.now();
    return isSameDay(now);
  }

  List<DateTime> getDaysInWeek() {
    return List.generate(7, (index) => add(Duration(days: index)));
  }

  List<DateTime> getDaysInWorkWeek() {
    return List.generate(5, (index) => add(Duration(days: index)));
  }

  List<DateTime> getDaysInMonth() {
    final first = firstDayOfMonth;
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = first.weekday;
    final weeksCount = ((daysInMonth + firstWeekday - 1) / 7).ceil();
    
    return List.generate(weeksCount * 7, (index) {
      final dayNumber = index - firstWeekday + 2;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        return null;
      }
      return DateTime(year, month, dayNumber);
    }).where((date) => date != null).cast<DateTime>().toList();
  }

  bool isBetween(DateTime start, DateTime end) {
    return isAfter(start) && isBefore(end);
  }

  bool isWithinRange(DateTime start, DateTime end) {
    return (isAfter(start) || isSameDay(start)) && 
           (isBefore(end) || isSameDay(end));
  }

  /// Calculates the start date of the week containing this date.
  /// For work week view, returns Monday of the week.
  /// For full week view, returns Sunday of the week.
  DateTime getWeekStartDate(bool workWeek) {
    // Get the current weekday (1 = Monday, 7 = Sunday)
    final currentWeekday = weekday;
    
    // For work week (Monday-Friday), we want to start from Monday
    // For full week, we want to start from Sunday
    final daysToSubtract = workWeek 
        ? currentWeekday - 1  // Days to subtract to get to Monday
        : currentWeekday % 7; // Days to subtract to get to Sunday
    
    return subtract(Duration(days: daysToSubtract));
  }

  bool isEventInDay(DateTime eventStart, DateTime eventEnd) {
    final date = DateTime(year, month, day);
    return date.isAfter(eventStart.subtract(const Duration(days: 1))) && 
           date.isBefore(eventEnd.add(const Duration(days: 1)));
  }
}
