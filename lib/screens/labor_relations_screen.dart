import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class LaborRelationsScreen extends StatelessWidget {
  final Player player;

  const LaborRelationsScreen(this.player, {super.key});

  @override
  Widget build(BuildContext context) {
    var gameState = context.watch<GameState>();
    int playerIndex = gameState.players.indexOf(player);
    gameState.calculateLaborConditions(playerIndex); // Update on build

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BASE: ${player.baseName} MANPOWER: ${player.resources[Equipment.manpower]}",
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          const Text("CONDITIONS SET COST", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: 6, // laborPool to bonuses (indices 7-12)
              itemBuilder: (context, index) {
                var eq = Equipment.values[index + 7];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(eq.toString().split('.').last.toUpperCase()),
                      Text("${player.resources[eq]}"),
                      Text("${gameState.costs[eq.index]}"),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => gameState.adjustCondition(playerIndex, eq, true),
                            child: const Text("Increase"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => gameState.adjustCondition(playerIndex, eq, false),
                            child: const Text("Decrease"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text("Credit: ${player.resources[Equipment.credit]}"),
          Text("Efficiency Rate: ${player.resources[Equipment.efficiency]}%"),
        ],
      ),
    );
  }
}