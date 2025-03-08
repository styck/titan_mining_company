import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:titan_mining_company/main.dart';
import 'package:titan_mining_company/models/game_state.dart';

void main() {
  testWidgets('TitanApp starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
       ChangeNotifierProvider(
          create: (context) => GameState(),
        child: const TitanApp(),
      ),
    );

    // Verify that the app starts on the SplashScreen.
    expect(find.text('TITAN!'), findsOneWidget);
  });
}
