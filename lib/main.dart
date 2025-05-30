import 'package:flutter/material.dart';
import 'package:toffee_tube/pages/trending_page.dart';
import 'package:fvp/fvp.dart' as fvp;

void main() {
  fvp.registerWith(options: {'platforms': ['windows', 'linux']});
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toffee Tube',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: DefaultTabController(length: 3, child: TrendingPage()),
    );
  }
}
