import 'package:jazmine_calendar/src/enums/enums.dart';

class CalendarViewService {
  // Singleton instance
  static final CalendarViewService _instance = CalendarViewService._internal();
  
  factory CalendarViewService() {
    return _instance;
  }
  
  CalendarViewService._internal();

  bool isDayView(CalendarView view) {
    return view == CalendarView.day || 
           view == CalendarView.week || 
           view == CalendarView.workWeek;
  }

  String getScrollStorageKey(CalendarView view) {
    if (isDayView(view)) {
      return 'day_view_scroll';
    }
    return '${view.toString()}_scroll';
  }
}
