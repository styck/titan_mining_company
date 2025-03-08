import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const TitanApp(),
    ),
  );
}

class TitanApp extends StatelessWidget {
  const TitanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Titan',
      theme: ThemeData.dark(), // Dark theme for space vibe
      home: const SplashScreen(),
    );
  }
}