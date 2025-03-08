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
  _MiningScreenState createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen> {
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
      _checkMeteorImpact(context.read<GameState>());
    });
  }

  void _startCaveInCheck() {
    _caveInTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _checkCaveIn(context.read<GameState>());
    });
  }

  void _checkMeteorImpact(GameState gameState) {
    int playerIndex = gameState.players.indexOf(widget.player);
    var p = gameState.players[playerIndex];
    if (p.resources[Equipment.drillRig]! <= 0) return;

    double r = _random.nextDouble() - (p.resources[Equipment.deflector]! * 0.2); // Tuned probability
    if (r >= 0.6) { // 40% base chance, reduced by deflectors
      setState(() {
        meteors.add(Offset(_random.nextInt(150).toDouble(), _random.nextInt(60) + 19));
        _soundManager.playSound('meteor');
        Future.delayed(const Duration(milliseconds: 500), () => setState(() => meteors.clear()));
        if (p.resources[Equipment.deflector]! > 0) {
          statusMessage = "Meteor shower deflected!";
        } else {
          statusMessage = "Meteor shower! Drill rig damaged!";
          p.resources[Equipment.drillRig] = p.resources[Equipment.drillRig]! - 1;
          gameState.notifyListeners();
          if (p.resources[Equipment.drillRig]! <= 0) {
            _meteorTimer?.cancel();
            _caveInTimer?.cancel();
          }
        }
      });
    }
  }

  void _checkCaveIn(GameState gameState) {
    int playerIndex = gameState.players.indexOf(widget.player);
    var p = gameState.players[playerIndex];
    if (p.resources[Equipment.drillRig]! <= 0 || p.resources[Equipment.veins]! <= 0) return;

    double r = _random.nextDouble() - (p.resources[Equipment.safety]! * 0.15); // Tuned probability
    if (r >= 0.7 && drillY > 20) { // 30% base chance, reduced by safety, only underground
      setState(() {
        _soundManager.playSound('caveIn');
        if (p.resources[Equipment.safety]! > 0) {
          statusMessage = "Cave-in prevented by safety measures!";
        } else {
          statusMessage = "Cave-in! Lost workers and vein!";
          p.resources[Equipment.manpower] = p.resources[Equipment.manpower]! - _random.nextInt(5) - 1;
          p.resources[Equipment.veins] = p.resources[Equipment.veins]! - 1;
          gameState.notifyListeners();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var gameState = context.watch<GameState>();
    if (widget.player.resources[Equipment.drillRig]! < 1) {
      _meteorTimer?.cancel();
      _caveInTimer?.cancel();
      return const Center(child: Text("No Drill Rigs Available"));
    }

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                drillX += details.delta.dx.round();
                drillY += details.delta.dy.round();
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
                    setState(() {
                      statusMessage = status;
                      if (status.contains("EUREKA")) {
                        _soundManager.playSound('dilithium');
                      }
                    });
                  },
                );
              });
            },
            child: CustomPaint(
              painter: MiningCanvas(drillX, drillY, meteors),
              size: const Size(160, 80),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Energy: $energy"),
              Text(statusMessage),
            ],
          ),
        ),
      ],
    );
  }
}