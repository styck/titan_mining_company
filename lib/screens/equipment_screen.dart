import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class EquipmentScreen extends StatelessWidget {
  final Player player;

  const EquipmentScreen(this.player, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Equipment Management")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "BASE: ${player.baseName} ${context.watch<GameState>().day}/1/${context.watch<GameState>().year}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text("EQUIPMENT OWNED COST", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) {
                  var eq = Equipment.values[index + 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(eq.toString().split('.').last.toUpperCase()),
                        Text("${player.resources[eq]}"),
                        Text("${context.watch<GameState>().costs[index + 1]}"),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => buy(context, eq),
                              child: const Text("Increase"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => sell(context, eq),
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
      ),
    );
  }

  void buy(BuildContext context, Equipment eq) {
    var state = context.read<GameState>();
    int playerIndex = state.players.indexOf(player);
    if (state.players[playerIndex].resources[Equipment.credit]! >= state.costs[eq.index]) {
      state.players[playerIndex].resources[eq] = state.players[playerIndex].resources[eq]! + 1;
      state.players[playerIndex].resources[Equipment.credit] =
          state.players[playerIndex].resources[Equipment.credit]! - state.costs[eq.index];
      state.notifyListeners();
    }
  }

  void sell(BuildContext context, Equipment eq) {
    var state = context.read<GameState>();
    int playerIndex = state.players.indexOf(player);
    if (state.players[playerIndex].resources[eq]! > 0) {
      state.players[playerIndex].resources[eq] = state.players[playerIndex].resources[eq]! - 1;
      state.players[playerIndex].resources[Equipment.credit] =
          state.players[playerIndex].resources[Equipment.credit]! + state.costs[eq.index];
      state.notifyListeners();
    }
  }
}
