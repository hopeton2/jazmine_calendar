# Jazmine Calendar

A flexible, cross-platform calendar widget for Flutter, inspired by Google Calendar.
Developed and maintained by Jazmine Technologies, Inc.

## Features

- Multiple calendar views: Day, Work Week, Week, Month, Agenda, and Timeline
- Customizable themes and styles
- Event management with custom rendering
- Timezone support
- Internationalization with support for English, French, and German

## Getting started

### Installation

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  jazmine_calendar: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### Import

```dart
import 'package:jazmine_calendar/jazmine_calendar.dart';
```

## Usage

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: JazmineCalendar(),
    ),
  ));
}
```

### With Internationalization

```dart
import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';

void main() {
  runApp(MaterialApp(
    localizationsDelegates: const [
      CalendarLocalization.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: CalendarLocalization.supportedLocales, // [en, fr, de]
    home: Scaffold(
      body: JazmineCalendar(),
    ),
  ));
}
```

### Using LocalizedCalendar

```dart
import 'package:flutter/material.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: LocalizedCalendar(
        locale: const Locale('fr'), // French
        calendar: JazmineCalendar(),
      ),
    ),
  ));
}
```

See the `/example` folder for more detailed examples.

## Additional information

For more information, visit [jazmine.tech](https://jazmine.tech) or contact us at [support@jazmine.tech](mailto:support@jazmine.tech).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2024 Jazmine Technologies, Inc.
