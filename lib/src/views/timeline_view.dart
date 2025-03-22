import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../jazmine_calendar.dart';
import 'base_calendar_view.dart';

class TimelineView extends BaseCalendarView {
  final TimelineViewConfiguration configuration;

  const TimelineView({
    super.key,
    this.configuration = const TimelineViewConfiguration(),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<JazmineCalendarController>(
      builder: (context, controller, child) {
        return ValueListenableBuilder<List<Event>>(
          valueListenable: controller.eventsNotifier,
          builder: (context, events, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final timeZones = controller.visibleTimeZones;
            
            return Column(
              children: [
                _buildTimeZoneHeader(timeZones),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildTimeline(context, events, timeZones),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeZoneHeader(List<String> timeZones) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: timeZones.map((timeZone) {
          return Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              timeZone,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<Event> events, List<String> timeZones) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: timeZones.map((timeZone) {
        final timeZoneEvents = events.where((event) => event.timeZone == timeZone).toList();
        return SizedBox(
          width: 200,
          child: _buildTimeZoneColumn(context, timeZoneEvents),
        );
      }).toList(),
    );
  }

  Widget _buildTimeZoneColumn(BuildContext context, List<Event> events) {
    return Column(
      children: List.generate(24, (hour) {
        final hourEvents = events.where((event) => event.start.hour == hour).toList();
        return Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ...hourEvents.map((event) => Positioned(
                left: 40,
                right: 0,
                top: (event.start.minute * 60) / 60,
                child: buildEventTile(context, event),
              )),
            ],
          ),
        );
      }),
    );
  }
}
