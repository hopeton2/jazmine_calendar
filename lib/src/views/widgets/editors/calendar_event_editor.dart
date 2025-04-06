import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting if needed directly
import 'package:jazmine_calendar/src/models/calendar_event.dart';
import 'package:jazmine_calendar/src/l10n/calendar_localization.dart'; // Import localization
import 'package:jazmine_calendar/src/viewmodels/calendar_event_editor_viewmodel.dart';
import 'package:provider/provider.dart'; // Assuming provider for state management

/// A widget for creating and editing calendar events using the MVVM pattern.
///
/// This widget displays a form driven by a [CalendarEventEditorViewModel].
/// It expects the ViewModel to be provided by an ancestor widget (e.g., using Provider).
class CalendarEventEditor extends StatelessWidget {
  /// Callback function when the editor is cancelled.
  final VoidCallback? onCancel;

  const CalendarEventEditor({
    super.key,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Access the ViewModel provided by an ancestor Provider
    final viewModel = Provider.of<CalendarEventEditorViewModel>(context);
    final localizations = CalendarLocalization.of(context); // Get localization instance

    // Use a Builder to get a context that can access the ScaffoldMessenger
    // Remove Scaffold and AppBar. The parent widget (e.g., Dialog or Page)
    // should provide the title, save/cancel actions.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: viewModel.formKey, // Use ViewModel's form key
        child: ListView( // Use ListView for scrollability
          children: <Widget>[
            TextFormField(
              controller: viewModel.titleController,
              decoration: InputDecoration(
                labelText: localizations.eventTitleLabel, // Localized label
                hintText: localizations.eventTitleHint, // Localized hint
                border: OutlineInputBorder(),
              ),
              validator: (value) { // Localized validation message
                if (value == null || value.isEmpty) {
                  return localizations.eventTitleValidation;
                }
                return null;
              },
              enabled: !viewModel.isSaving, // Disable when saving
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: viewModel.descriptionController,
              decoration: InputDecoration(
                labelText: localizations.descriptionLabel, // Localized label
                hintText: localizations.descriptionHint, // Localized hint
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !viewModel.isSaving, // Disable when saving
            ),
            const SizedBox(height: 16.0),
            // --- All Day Switch ---
            SwitchListTile(
              title: Text(localizations.allDayEventLabel), // Localized label
              value: viewModel.isAllDay,
              onChanged: viewModel.isSaving ? null : viewModel.toggleAllDay,
              secondary: const Icon(Icons.watch_later_outlined),
            ),
            const SizedBox(height: 8.0), // Adjust spacing

            // --- Date/Time Pickers ---
            // TODO: Implement proper date/time pickers connected to viewModel
            // Start Date Picker
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                 // Show only date part here
                 '${localizations.startsLabel} ${localizations.formatFullDate(viewModel.startDate.toLocal())}'
              ),
              onTap: viewModel.isSaving ? null : () => viewModel.pickStartDate(context),
            ),
            // Start Time Picker (only if not all day)
            if (!viewModel.isAllDay)
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 8.0), child: Icon(Icons.access_time_outlined, size: 20)), // Indent icon slightly
                title: Text(
                   DateFormat.jm(localizations.locale.languageCode).format(viewModel.startDate.toLocal())
                ),
                onTap: viewModel.isSaving ? null : () => viewModel.pickStartTime(context),
                dense: true, // Make it less tall
              ),
            // Conditionally show time pickers only if not an all-day event
            // End Date Picker
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined), // Use same icon as start date
              title: Text(
                // Show only date part here
                '${localizations.endsLabel} ${localizations.formatFullDate(viewModel.endDate.toLocal())}'
              ),
              onTap: viewModel.isSaving ? null : () => viewModel.pickEndDate(context),
            ),
             // End Time Picker (only if not all day)
            if (!viewModel.isAllDay)
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 8.0), child: Icon(Icons.access_time_outlined, size: 20)), // Indent icon slightly
                title: Text(
                   DateFormat.jm(localizations.locale.languageCode).format(viewModel.endDate.toLocal())
                ),
                onTap: viewModel.isSaving ? null : () => viewModel.pickEndTime(context),
                dense: true, // Make it less tall
              ),
            const SizedBox(height: 16.0),

            // --- Time Zone Selector ---
            DropdownButtonFormField<String>(
              value: viewModel.selectedTimeZone,
              items: viewModel.availableTimeZones.map((String tz) {
                return DropdownMenuItem<String>(
                  value: tz,
                  child: Text(tz.replaceAll('_', ' ')), // Make timezone names more readable
                );
              }).toList(),
              onChanged: viewModel.isSaving ? null : viewModel.setTimeZone,
              decoration: InputDecoration(
                labelText: localizations.timeZoneLabel, // Localized label
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
              validator: (value) => value == null ? localizations.timeZoneValidation : null, // Localized validation
              disabledHint: Text(viewModel.selectedTimeZone), // Show current value when disabled
            ),
            const SizedBox(height: 16.0),

            // --- Reminder Settings ---
            SwitchListTile(
              title: Text(localizations.translate('reminderLabel') ?? 'Reminder'), // Add 'reminderLabel' to l10n files
              value: viewModel.reminderEnabled,
              onChanged: viewModel.isSaving ? null : viewModel.toggleReminder,
              secondary: const Icon(Icons.notifications_active_outlined),
            ),
            if (viewModel.reminderEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0), // Indent dropdown slightly
                child: DropdownButtonFormField<int>(
                  value: viewModel.reminderMinutesBefore,
                  items: viewModel.availableReminderIntervals.map((int minutes) {
                    return DropdownMenuItem<int>(
                      value: minutes,
                      // TODO: Localize interval display (e.g., "15 minutes before", "1 hour before")
                      child: Text('$minutes minutes before'),
                    );
                  }).toList(),
                  onChanged: viewModel.isSaving ? null : viewModel.setReminderMinutes,
                  decoration: InputDecoration(
                    labelText: localizations.translate('reminderTimeLabel') ?? 'Remind me', // Add 'reminderTimeLabel'
                    border: const OutlineInputBorder(),
                    // prefixIcon: Icon(Icons.timer_outlined), // Optional icon
                  ),
                  validator: (value) => viewModel.reminderEnabled && value == null
                      ? (localizations.translate('reminderTimeValidation') ?? 'Please select reminder time') // Add 'reminderTimeValidation'
                      : null,
                  disabledHint: viewModel.reminderMinutesBefore != null
                      ? Text('${viewModel.reminderMinutesBefore} minutes before')
                      : null,
                ),
              ),
            ] else ... [
               const SizedBox(height: 16.0), // Maintain spacing when reminder details are hidden
            ],


            // --- Recurrence Selector ---
            DropdownButtonFormField<String>(
              // Ensure value exists in items, default to 'NONE' if not
              value: viewModel.availableRecurrenceTypes.contains(viewModel.selectedRecurrenceType)
                     ? viewModel.selectedRecurrenceType
                     : 'NONE',
              // TODO: Use localized display names for types
              items: viewModel.availableRecurrenceTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(localizations.translate('recurrence_$type') ?? type), // Add 'recurrence_NONE', 'recurrence_DAILY' etc. keys
                );
              }).toList(),
              onChanged: viewModel.isSaving ? null : viewModel.setRecurrenceType,
              decoration: InputDecoration(
                labelText: localizations.translate('recurrenceLabel') ?? 'Repeats', // Add 'recurrenceLabel' key
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.repeat),
              ),
              // No validator needed unless 'NONE' is invalid?
            ),
            const SizedBox(height: 16.0),

            // --- Location ---
            TextFormField(
              controller: viewModel.locationController,
              decoration: InputDecoration(
                labelText: localizations.translate('locationLabel') ?? 'Location', // Add 'locationLabel'
                hintText: localizations.translate('locationHint') ?? 'Enter location (optional)', // Add 'locationHint'
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              enabled: !viewModel.isSaving,
            ),
            const SizedBox(height: 16.0),

            // --- Color Picker ---
            // TODO: Consider using a dedicated color picker package for better UX
            Text(localizations.translate('colorLabel') ?? 'Color', style: Theme.of(context).textTheme.titleMedium), // Add 'colorLabel'
            const SizedBox(height: 8.0),
            Wrap( // Use Wrap for responsiveness
              spacing: 8.0,
              runSpacing: 4.0, // Adjust run spacing
              children: viewModel.availableColors.map((color) {
                final bool isSelected = viewModel.selectedColor?.value == color.value; // Compare color values
                return GestureDetector( // Use GestureDetector for better tap area
                   onTap: viewModel.isSaving ? null : () => viewModel.setColor(color),
                   child: Container(
                     width: 32, // Fixed size for color circle
                     height: 32,
                     decoration: BoxDecoration(
                       color: color,
                       shape: BoxShape.circle,
                       border: Border.all(
                         color: isSelected ? Theme.of(context).primaryColorDark : Colors.grey,
                         width: isSelected ? 3.0 : 1.0,
                       ),
                     ),
                   ),
                );
              }).toList(),
            ),
             const SizedBox(height: 16.0),

            // --- Privacy Toggle ---
            SwitchListTile(
              title: Text(localizations.translate('privateLabel') ?? 'Private Event'), // Add 'privateLabel'
              value: viewModel.isPrivate,
              onChanged: viewModel.isSaving ? null : viewModel.togglePrivate,
              secondary: Icon(viewModel.isPrivate ? Icons.lock_outline : Icons.lock_open_outlined),
            ),
            const SizedBox(height: 16.0),


            // TODO: Add field for attachments (More complex, requires separate handling)
            const SizedBox(height: 24.0),
            // Keep the save button at the bottom of the form
            ElevatedButton(
              onPressed: viewModel.isSaving ? null : viewModel.saveEvent,
              child: viewModel.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                    )
                  : Text(localizations.save),
            ),
          ],
        ),
      ),
    );
  }
}