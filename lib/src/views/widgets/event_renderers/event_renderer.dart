import 'package:flutter/material.dart';
import '../../../models/calendar_event.dart';

abstract class EventRenderer {
  Widget buildEventWidget({
    required BuildContext context,
    required CalendarEvent event,
    required DateTime cellDate,
    required Size availableSpace,
  });
}
