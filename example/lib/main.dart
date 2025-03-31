import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jazmine_calendar/jazmine_calendar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    title: 'Jazmine Calendar Example',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurpleAccent,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    localizationsDelegates: const [
      CalendarLocalization.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: CalendarLocalization.supportedLocales,
    //locale: const Locale('fr'), // Set French as the default language
    home: const MyHomePage(),
    themeMode: ThemeMode.dark,
  ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _lastAction = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          if (_lastAction.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _lastAction,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _lastAction = ''),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<CalendarController>(
              future: CalendarController.create(
                // Pass the locale to the controller to set the first day of week
                locale: Localizations.localeOf(context),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return JazmineCalendar(
                  controller: snapshot.data,
                  showNavigationBar: true,
                  showViewSelector: true,
                  navigationBarStyle: NavigationBarStyle.compact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
