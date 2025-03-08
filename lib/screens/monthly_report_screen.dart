import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class MonthlyReportScreen extends StatelessWidget {
  final Player player;

  const MonthlyReportScreen(this.player, {super.key});

  @override
  Widget build(BuildContext context) {
    var gameState = context.watch<GameState>();
    int playerIndex = gameState.players.indexOf(player);
    gameState.updateCredits(playerIndex);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MONTHLY REPORT - ${gameState.day}/1/${gameState.year}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text("ITEM", style: TextStyle(fontWeight: FontWeight.bold)),
          _buildReportRow("STATUS", player.resources[Equipment.status]!),
          _buildReportRow("DRILL RIG", player.resources[Equipment.drillRig]!),
          _buildReportRow("ROBOMINER", player.resources[Equipment.robominer]!),
          _buildReportRow("DEFLECTOR", player.resources[Equipment.deflector]!),
          _buildReportRow("R&D UNIT", player.resources[Equipment.rdUnit]!),
          _buildReportRow("REFINERY", player.resources[Equipment.refinery]!),
          _buildReportRow("ENERGIZER", player.resources[Equipment.energizer]!),
          const SizedBox(height: 20),
          _buildReportRow("CREDIT", player.resources[Equipment.credit]!),
          _buildReportRow("MANPOWER", player.resources[Equipment.manpower]!),
          _buildReportRow("EFFICIENCY", player.resources[Equipment.efficiency]!),
          _buildReportRow("VEINS", player.resources[Equipment.veins]!),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text("$value"),
        ],
      ),
    );
  }
}