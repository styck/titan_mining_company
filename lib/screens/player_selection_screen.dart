import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'difficulty_selection_screen.dart';

class PlayerSelectionScreen extends StatelessWidget {
  const PlayerSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Number of Players")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "WELCOME TO TITAN!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text("Use the buttons to select the number of players."),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 4; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _selectPlayers(context, i);
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

  void _selectPlayers(BuildContext context, int numPlayers) {
    var gameState = context.read<GameState>();
    gameState.setNumPlayers(numPlayers);
    List<String> baseNames = ["ACTAEON", "BELLONA", "CHIMERA", "DAEDALUS"];
    gameState.players.clear();
    for (int i = 0; i < numPlayers; i++) {
      gameState.addPlayer(baseNames[i]);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DifficultySelectionScreen()),
    );
  }
}
