import 'package:flutter/material.dart';
import 'player_selection_screen.dart'; // Import the new screen

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "TITAN!",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text("(c) Wm. Morris ~ J. 1981"),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlayerSelectionScreen()),
                );
              },
              child: const Text("Start Game"),
            ),
          ],
        ),
      ),
    );
  }
}
