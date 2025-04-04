import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jazmine_calendar/src/controller/calendar_controller.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart';
import 'package:jazmine_calendar/src/viewmodels/all_day_grid_viewmodel.dart'; // Import the ViewModel
import 'package:jazmine_calendar/src/views/widgets/calendar_grid.dart';
import 'package:provider/provider.dart'; // Import Provider

// Callback type is defined in the ViewModel now

/// Renders the all-day event section, managed by [AllDayGridViewModel].
class AllDayGrid extends StatelessWidget {
  final List<DateTime> dates;
  final CalendarController controller;
  final double headerWidth;
  final int
      maxVisibleAllDayEvents; // Still needed to pass to ViewModel and CalendarGrid
  final Color? borderColor;

  // Removed internal constants - they are in the ViewModel now

  const AllDayGrid({
    super.key,
    required this.dates,
    required this.controller,
    this.headerWidth = 0.0,
    this.maxVisibleAllDayEvents = 2,
    this.borderColor,
  }) : assert(maxVisibleAllDayEvents >= 0);

  @override
  Widget build(BuildContext context) {
    // Use ChangeNotifierProvider to create and provide the ViewModel for this widget subtree.
    // Note: Ideally, this provider is placed higher up in the widget tree (e.g., in BaseDayView)
    // if other widgets need access to this ViewModel or if AllDayGrid rebuilds frequently.
    return ChangeNotifierProvider<AllDayGridViewModel>(
      create: (_) =>
          AllDayGridViewModel(maxVisibleAllDayEvents: maxVisibleAllDayEvents),
      child: Consumer<AllDayGridViewModel>(
        builder: (context, viewModel, child) {
          // Access state and calculated values from the ViewModel
          final double targetEventAreaHeight = viewModel.targetEventAreaHeight;
          final bool showMoreButton = viewModel.showMoreButton;
          final int hiddenCount = viewModel.hiddenEventCount;
          final bool showButtonContainer = viewModel.showButtonContainer;
          final bool isExpanded = viewModel.isExpanded;
          final bool showCollapseButton = viewModel.showCollapseButton; // Get collapse button state
          final bool isCollapsed = !isExpanded; // Determine collapsed state
          final double collapsedContentHeight = viewModel.collapsedContentHeight; // Get height limit

          final Duration animationDuration = const Duration(milliseconds: 300);

          // The rest of the build method uses viewModel properties/methods
          // Use a Row as the main structure
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Area now includes the button via Stack
              _buildAllDayHeader(
                context,
                viewModel, // Pass viewModel to header builder
                headerWidth,
                targetEventAreaHeight,
                animationDuration,
                borderColor,
                hiddenCount, // Pass hiddenCount for button text
              ),
              // Event Grid Area (no button here anymore)
              Expanded(
                child: AnimatedContainer(
                  // Animate the container for the grid
                  duration: animationDuration,
                  curve: Curves.easeInOut,
                  height: targetEventAreaHeight,
                  decoration: BoxDecoration(
                    border: borderColor != null
                        ? Border(
                            top: BorderSide(color: borderColor!),
                            bottom: BorderSide(color: borderColor!), // Add bottom border
                          )
                        : null,
                  ),
                  child: ClipRect(
                    // Clip events overflowing the animated container
                    child: CalendarGrid(
                      dates: dates,
                      controller: controller,
                      headerDateFormat: DateFormat(''),
                      numberOfColumns: dates.length,
                      numberOfRows: 1,
                      slotDuration: const Duration(days: 1),
                      intervalDuration: const Duration(days: 1),
                      orientation: Axis.horizontal,
                      rowHeaderWidth: 0,
                      columnHeaderHeight: 0.0,
                      showCurrentTimeIndicator: false,
                      isAllDay: true,
                      maxVisibleAllDayEvents: maxVisibleAllDayEvents, // Pass down
                      onOverflowStateChanged: viewModel.handleOverflowStateChanged, // Pass ViewModel's handler
                      // Pass down new parameters for filtering
                      isCollapsed: isCollapsed,
                      collapsedContentHeight: collapsedContentHeight,
                    ),
                  ),
                ),
              ),
            ], // End Row children
          ); // End Row
        }, // End builder
      ), // End Consumer
    ); // End ChangeNotifierProvider
  } // End build method

  // Helper method to build the header area, now including the button via Stack
  Widget _buildAllDayHeader(
    BuildContext context,
    AllDayGridViewModel viewModel, // Receive viewModel
    double width,
    double height,
    Duration animationDuration,
    Color? borderColor,
    int hiddenCount, // Receive hiddenCount
  ) {
    final bool showButtonContainer = viewModel.showButtonContainer;

    // Use a Stack to overlay button on the header background/border container
    // Use a Stack to overlay button on the header background/border container
    // Set alignment to center the non-positioned children (the button)
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background/Border Container (Animates height)
        AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeInOut,
          width: width,
          height: height, // Use targetHeight passed from build
          decoration: BoxDecoration(
            border: borderColor != null
                ? Border(
                    top: BorderSide(color: borderColor),
                    bottom: BorderSide(color: borderColor),
                    right: BorderSide(color: borderColor),
                  )
                : null,
          ),
        ),
        // Button Content (Now centered by Stack's alignment)
        AnimatedOpacity(
          opacity: showButtonContainer ? 1.0 : 0.0,
          duration: animationDuration,
          child: IgnorePointer(
            ignoring: !showButtonContainer,
            child: _buildButtonContent(context, viewModel, hiddenCount),
          ),
        ),
      ],
    );
  }

  /// Builds the actual button content (More or Collapse).
  Widget _buildButtonContent(
      BuildContext context, AllDayGridViewModel viewModel, int hiddenCount) {
    // Keep previous button styling or adjust as needed for header overlay
    if (viewModel.showMoreButton) {
      return GestureDetector(
        onTap: viewModel.expand,
        child: Container(
          // Adjust padding if needed for Column layout
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Fit content vertically
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "+${hiddenCount > 0 ? hiddenCount : ''}",
                style: const TextStyle(fontSize: 10, color: Colors.white, height: 1.1), // Adjust line height if needed
              ),
              Text( // Use localized string
                CalendarLocalization.of(context).moreLabel,
                style: const TextStyle(fontSize: 10, color: Colors.white, height: 1.1), // Adjust line height if needed
              ),
            ],
          ),
        ),
      );
    } else if (viewModel.showCollapseButton) {
       // Using a Container with InkWell for better control over shape/size/tap area
       return Material( // Needed for InkWell splash
         color: Colors.transparent,
         child: InkWell(
           onTap: viewModel.collapse,
           customBorder: const CircleBorder(),
           child: Container(
             padding: const EdgeInsets.all(4.0), // Padding around the icon
             decoration: BoxDecoration(
               color: Colors.black.withOpacity(0.6),
               shape: BoxShape.circle,
             ),
             child: Icon(
               Icons.expand_less,
               color: Colors.white,
               size: 16, // Slightly smaller icon
             ),
           ),
         ),
       );
    } else {
      return const SizedBox.shrink();
    }
  }
} // End AllDayGrid class
