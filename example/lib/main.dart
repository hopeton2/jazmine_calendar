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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: JazmineCalendar(
        showNavigationBar: true,
        showViewSelector: true,
        navigationBarStyle: NavigationBarStyle.compact,
        controller: CalendarController(
          initialView: CalendarViewType.day,
          initialDate: DateTime.now(),
          scrollToCurrentTimeOnLoad: false, // Disable auto-scrolling
          interval: const Duration(minutes: 60),
        ),
      ),
    );
  }
}
