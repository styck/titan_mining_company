import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'game_loop_screen.dart';

class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Difficulty Level")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "LEVEL OF DIFFICULTY?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text("Use the buttons to select the difficulty."),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 4; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _selectDifficulty(context, i);
                      },
                      child: Text("$i"),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectDifficulty(BuildContext context, int level) {
    var gameState = context.read<GameState>();
    gameState.setDifficulty(level + 4); // LV = X + 4 as per original game
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameLoopScreen()),
    );
  }
}
