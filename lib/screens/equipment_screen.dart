import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class EquipmentScreen extends StatelessWidget {
  final Player player;

  const EquipmentScreen(this.player, {super.key});

  @override
  Widget build(BuildContext context) {
    var gameState = context.watch<GameState>();
    int playerIndex = gameState.players.indexOf(player);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BASE: ${player.baseName} ${gameState.day}/1/${gameState.year}",
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          const Text("EQUIPMENT OWNED COST", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: 12, // From drillRig to bonuses (indices 1-12)
              itemBuilder: (context, index) {
                var eq = Equipment.values[index + 1];
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
                            onPressed: () => gameState.buyEquipment(playerIndex, eq),
                            child: const Text("Increase"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => gameState.sellEquipment(playerIndex, eq),
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
        ],
      ),
    );
  }
}