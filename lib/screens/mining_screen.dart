import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/mining_canvas.dart';
import '../services/sound_manager.dart';

class MiningScreen extends StatefulWidget {
  final Player player;

  const MiningScreen(this.player, {super.key});

  @override
  MiningScreenState createState() => MiningScreenState();
}

class MiningScreenState extends State<MiningScreen> {
  int drillX = 50;
  int drillY = 19;
  int energy = 500;
  String statusMessage = "Drill to find Dilithium!";
  List<Offset> meteors = [];
  Timer? _meteorTimer;
  Timer? _caveInTimer;
  final SoundManager _soundManager = SoundManager();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startMeteorCheck();
    _startCaveInCheck();
  }

  @override
  void dispose() {
    _meteorTimer?.cancel();
    _caveInTimer?.cancel();
    _soundManager.stopSound();
    super.dispose();
  }

  void _startMeteorCheck() {
    _meteorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      var gameState = context.read<GameState>();
      int playerIndex = gameState.players.indexOf(widget.player);
      setState(() {
        bool eventOccurred = gameState.checkMeteorImpact(playerIndex, (status) {
          statusMessage = status;
          if (status.contains("Meteor")) {
            meteors.add(Offset(_random.nextInt(150).toDouble(), _random.nextInt(60) + 19));
            _soundManager.playSound('meteor');
            Future.delayed(const Duration(milliseconds: 500), () => setState(() => meteors.clear()));
          }
        });
        if (eventOccurred && gameState.players[playerIndex].resources[Equipment.drillRig]! <= 0) {
          _meteorTimer?.cancel();
          _caveInTimer?.cancel();
        }
      });
    });
  }

  void _startCaveInCheck() {
    _caveInTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      var gameState = context.read<GameState>();
      int playerIndex = gameState.players.indexOf(widget.player);
      setState(() {
        gameState.checkCaveIn(playerIndex, drillY, (status) {
          statusMessage = status;
          if (status.contains("Cave-in")) {
            _soundManager.playSound('caveIn');
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var gameState = context.watch<GameState>();
    final screenHeight = MediaQuery.of(context).size.height;
    final canvasHeight = screenHeight * 0.5;
    final canvasWidth = canvasHeight * 2;

    if (widget.player.resources[Equipment.drillRig]! < 1) {
      _meteorTimer?.cancel();
      _caveInTimer?.cancel();
      return const Center(child: Text("No Drill Rigs Available"));
    }

    return Column(
      children: [
        Container(
          height: canvasHeight,
          width: canvasWidth,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                drillX += (details.delta.dx / (canvasWidth / 150)).round();
                drillY += (details.delta.dy / (canvasHeight / 78)).round();
                if (drillX < 0) drillX = 0;
                if (drillX > 150) drillX = 150;
                if (drillY < 19) drillY = 19;
                if (drillY > 78) drillY = 78;
                energy -= 10;
                gameState.updateMining(
                  gameState.players.indexOf(widget.player),
                  drillX,
                  drillY,
                  energy,
                  (status) {
                    statusMessage = status;
                    if (status.contains("EUREKA")) {
                      _soundManager.playSound('dilithium');
                    }
                  },
                );
              });
            },
            child: CustomPaint(
              painter: MiningCanvas(
                drillX,
                drillY,
                meteors,
                canvasWidth,
                canvasHeight,
                widget.player.resources[Equipment.drillRig]!, // Pass total drill rigs
              ),
              size: Size(canvasWidth, canvasHeight),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Energy: $energy", style: const TextStyle(fontSize: 18)),
              Text(
                "Drill Rigs Available: ${widget.player.resources[Equipment.drillRig]}", // Clarify label
                style: const TextStyle(fontSize: 18, color: Color(0xFF00FFFF)),
              ),
              Text(statusMessage, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ],
    );
  }
}