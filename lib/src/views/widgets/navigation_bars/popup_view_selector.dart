import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/services/view_service.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class PopupViewSelector extends StatelessWidget {
  final bool showSelection;
  
  const PopupViewSelector(
      {super.key,  this.showSelection = true});

  @override
  Widget build(BuildContext context) {
    var controller = JazmineCalendar.of(context).controller;
    return PopupMenuButton<CalendarView>(
      initialValue: controller.currentView,
      onSelected: (newView) {
        controller.changeView(newView);
      },
      itemBuilder: (BuildContext context) => CalendarView.values.map((view) {
        return PopupMenuItem(
          value: view,
          child: Text(ViewService().getViewLabel(view)),
        );
      }).toList(),
      child: DropdownSelector(
          ViewService().getViewLabel(controller.currentView),
          !showSelection),
    );
  }
}

class DropdownSelector extends StatelessWidget {
  final String selection;
  final bool isCompact;
  const DropdownSelector(this.selection, this.isCompact, {super.key});

  @override
  Widget build(BuildContext context) {
    return isCompact
        ? const Icon(Icons.more_vert)
        : Row(children: [Text(selection), const Icon(Icons.arrow_drop_down)]);
  }
}
