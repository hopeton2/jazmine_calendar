import 'package:flutter/material.dart';
import 'package:jazmine_calendar/src/enums/enums.dart';
import 'package:jazmine_calendar/src/services/calendar_view_service.dart';
import 'package:jazmine_calendar/src/views/widgets/jazmine_calendar.dart';

class DropdownViewSelector extends StatelessWidget {
  final bool showSelection;

  const DropdownViewSelector({super.key, this.showSelection = true});

  @override
  Widget build(BuildContext context) {
    var controller = JazmineCalendar.of(context).controller;
    return PopupMenuButton<CalendarViewType>(
      initialValue: controller.currentView,
      onSelected: (newView) {
        controller.changeView(newView);
      },
      itemBuilder: (BuildContext context) =>
          CalendarViewType.values.map((view) {
        return PopupMenuItem(
          value: view,
          child: Text(CalendarViewService().getViewLabel(view, context)),
        );
      }).toList(),
      position: PopupMenuPosition.under,
      child: Builder(
        builder: (context) => DropdownSelector(
          CalendarViewService().getViewLabel(controller.currentView, context),
          !showSelection,
          onPressed: () {
            PopupMenuButtonState<CalendarViewType> button =
                context.findAncestorStateOfType<
                    PopupMenuButtonState<CalendarViewType>>()!;
            button.showButtonMenu();
          },
        ),
      ),
    );
  }
}

class DropdownSelector extends StatelessWidget {
  final String selection;
  final bool isCompact;
  final VoidCallback onPressed;

  const DropdownSelector(this.selection, this.isCompact,
      {super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return isCompact
        ? IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onPressed,
          )
        : TextButton(
            onPressed: onPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selection),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          );
  }
}
