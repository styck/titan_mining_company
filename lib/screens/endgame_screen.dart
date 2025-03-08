import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/sound_manager.dart';

class EndgameScreen extends StatelessWidget {
  const EndgameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var gameState = context.watch<GameState>();
    var winner = gameState.determineWinner();
    final SoundManager soundManager = SoundManager();

    // Play endgame sound (J7=20070 equivalent)
    soundManager.playSound('endgame'); // Add 'endgame.mp3' to assets

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "The INSPECTORS have arrived!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your performance is being assessed.",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            if (gameState.numPlayers == 1) ...[
              if (winner != null)
                Text(
                  "Because of your status (${winner.resources[Equipment.status]}), you have won\nthe right to mine all of TITAN!!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.green),
                )
              else
                const Text(
                  "I am sorry to report that you did not\nachieve enough status to gain all TITAN.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.red),
                ),
            ] else ...[
              if (winner != null)
                Text(
                  "The supervisor of ${winner.baseName} has won\nwith a status of ${winner.resources[Equipment.status]}!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.green),
                )
              else
                const Text(
                  "No clear winner emerged.",
                  style: TextStyle(fontSize: 20, color: Colors.orange),
                ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Return to Start"),
            ),
          ],
        ),
      ),
    );
  }
}