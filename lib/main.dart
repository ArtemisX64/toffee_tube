import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:toffee_gravy/reverse/youtube/youtube_client_handler.dart';
import 'package:toffee_tube/pages/trending.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final client = YoutubeClient();
  runApp(ToffeeTube(client: client));
}

class ToffeeTube extends StatelessWidget {
  final YoutubeClient client;
  const ToffeeTube({required this.client, super.key});


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
      home: DefaultTabController(length: 3, child: TrendingPage(client: client,)),
    );
  }
}
