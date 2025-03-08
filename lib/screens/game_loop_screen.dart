import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'equipment_screen.dart';
import 'labor_relations_screen.dart';
import 'mining_screen.dart';
import 'monthly_report_screen.dart';

class GameLoopScreen extends StatefulWidget {
  const GameLoopScreen({super.key});

  @override
  _GameLoopScreenState createState() => _GameLoopScreenState();
}

class _GameLoopScreenState extends State<GameLoopScreen> {
  int currentPlayerIndex = 0;
  int currentPhase = 0; // 0: Equipment, 1: Labor, 2: Mining, 3: Report

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
      case 0: // Equipment Management
        return EquipmentScreen(gameState.players[currentPlayerIndex]);
      case 1: // Labor Relations
        return LaborRelationsScreen(gameState.players[currentPlayerIndex]);
      case 2: // Mining
        return MiningScreen(gameState.players[currentPlayerIndex]);
      case 3: // Monthly Report
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
          // Increment day/year (subroutine 7000)
          gameState.day++;
          if (gameState.day > 12) {
            gameState.day = 1;
            gameState.year++;
          }
          // TODO: Add endgame check (subroutine 8000)
          gameState.notifyListeners();
        }
      }
    });
  }
}