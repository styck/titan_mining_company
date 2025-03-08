import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'equipment_screen.dart';
import 'labor_relations_screen.dart';
import 'mining_screen.dart';
import 'monthly_report_screen.dart';
import 'endgame_screen.dart';

class GameLoopScreen extends StatefulWidget {
  const GameLoopScreen({super.key});

  @override
  GameLoopScreenState createState() => GameLoopScreenState();
}

class GameLoopScreenState extends State<GameLoopScreen> {
  int currentPlayerIndex = 0;
  int currentPhase = 0;
  final List<String> phases = ["Equipment", "Labor Relations", "Mining", "Monthly Report"];

  @override
  Widget build(BuildContext context) {
    var gameState = context.watch<GameState>();
    var currentPlayer = gameState.players[currentPlayerIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Turn: ${currentPlayer.baseName} - ${phases[currentPhase]}"),
      ),
      body: _buildPhaseContent(gameState),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _nextPhase,
          child: const Text("Next Phase"),
        ),
      ),
    );
  }

  Widget _buildPhaseContent(GameState gameState) {
    switch (currentPhase) {
      case 0:
        return EquipmentScreen(gameState.players[currentPlayerIndex]);
      case 1:
        return LaborRelationsScreen(gameState.players[currentPlayerIndex]);
      case 2:
        return MiningScreen(gameState.players[currentPlayerIndex]);
      case 3:
        return MonthlyReportScreen(gameState.players[currentPlayerIndex]);
      default:
        return const Center(child: Text("Unknown Phase"));
    }
  }

  void _nextPhase() {
    var gameState = context.read<GameState>();
    setState(() {
      currentPhase++;
      if (currentPhase >= phases.length) {
        currentPhase = 0;
        currentPlayerIndex++;
        if (currentPlayerIndex >= gameState.numPlayers) {
          currentPlayerIndex = 0;
          gameState.advanceTime();
          gameState.updateCosts();
          if (gameState.checkEndgame()) {
            gameState.calculateFinalStatus();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const EndgameScreen()),
            );
          }
        }
      }
    });
  }
}