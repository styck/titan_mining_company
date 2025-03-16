import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
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
  double drillXNormalized = 0.3333; // Start at 50/150
  double drillYNormalized = 0.2436; // Start at 19/78
  int energy = 500;
  String statusMessage = "Drill to find Dilithium!";
  List<Offset> meteors = [];
  Timer? _meteorTimer;
  Timer? _caveInTimer;
  Timer? _eurekaTimer; // Timer to persist Eureka message
  final SoundManager _soundManager = SoundManager();
  final Random _random = Random();
  bool _isFirstEntry = true;
  bool _isLosingRig = false;
  bool _isOutOfEnergy = false;
  bool _showEurekaHighlight = false; // Flag for visual highlight

  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: (dateTime) => DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(dateTime),
    ),
  );

  static const bool showDebugIndicator = true;

  final double targetXNormalized = 0.3333; // 50 / 150
  final double targetYNormalized = 0.5; // 40 / 78, adjusted for subsurface
  late double targetRadiusNormalized;

  @override
  void initState() {
    super.initState();
    var gameState = context.read<GameState>();
    targetRadiusNormalized = (10 - gameState.difficulty) / 150.0;
    logger.i("MiningScreen initialized for player: ${widget.player.baseName}, starting at (x: $drillXNormalized, y: $drillYNormalized), energy: $energy");
    logger.d("Dilithium target at (x: $targetXNormalized, y: $targetYNormalized), radius: $targetRadiusNormalized (difficulty: ${gameState.difficulty})");
    _startMeteorCheck();
    _startCaveInCheck();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstEntry) {
        logger.i("Showing tooltip on first entry");
        _showTooltip();
        _isFirstEntry = false;
      }
    });
  }

  void _showTooltip() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text("Mining Phase Tips"),
        content: const Text(
          "You control one drill at a time. Additional drill rigs are spares that can be lost to hazards. Use DEFLECTOR and SAFETY to protect your operation! Start exploring near the center of the canvas to find Dilithium.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              logger.i("Tooltip dismissed by user");
              Navigator.pop(context);
            },
            child: const Text("Got It"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _meteorTimer?.cancel();
    _caveInTimer?.cancel();
    _eurekaTimer?.cancel();
    _soundManager.stopSound();
    logger.i("Disposing MiningScreen: cancelling timers and stopping sounds");
    super.dispose();
  }

  void _startMeteorCheck() {
    logger.i("Starting meteor check timer (every 3 seconds)");
    _meteorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      var gameState = context.read<GameState>();
      int playerIndex = gameState.players.indexOf(widget.player);
      int initialRigs = gameState.players[playerIndex].resources[Equipment.drillRig]!;
      logger.d("Checking for meteor impact, initial rigs: $initialRigs");
      setState(() {
        bool eventOccurred = gameState.checkMeteorImpact(playerIndex, (status) {
          statusMessage = status;
          logger.i("Meteor event status: $status");
          if (status.contains("Meteor")) {
            meteors.add(Offset(
              _random.nextDouble(),
              _random.nextDouble() * 0.75 + 0.25,
            ));
            logger.d("Meteor added at normalized position: ${meteors.last}, playing meteor sound");
            _soundManager.playSound('meteor');
            Future.delayed(const Duration(milliseconds: 500), () {
              logger.d("Clearing meteors after 500ms");
              setState(() => meteors.clear());
            });
            if (gameState.players[playerIndex].resources[Equipment.drillRig]! < initialRigs) {
              logger.w("Lost a drill rig, triggering animation");
              _isLosingRig = true;
              Future.delayed(const Duration(milliseconds: 300), () {
                logger.d("Animation complete, resetting _isLosingRig");
                setState(() => _isLosingRig = false);
              });
            }
          }
        });
        if (eventOccurred && gameState.players[playerIndex].resources[Equipment.drillRig]! <= 0) {
          logger.w("No drill rigs left, stopping timers");
          _meteorTimer?.cancel();
          _caveInTimer?.cancel();
        }
      });
    });
  }

  void _startCaveInCheck() {
    logger.i("Starting cave-in check timer (every 4 seconds)");
    _caveInTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      var gameState = context.read<GameState>();
      int playerIndex = gameState.players.indexOf(widget.player);
      logger.d("Checking for cave-in at normalized position (x: $drillXNormalized, y: $drillYNormalized)");
      setState(() {
        gameState.checkCaveIn(playerIndex, drillYNormalized, (status) {
          statusMessage = status;
          logger.i("Cave-in event status: $status");
          if (status.contains("Cave-in")) {
            logger.d("Playing cave-in sound");
            _soundManager.playSound('caveIn');
          }
        });
      });
    });
  }

  void _switchToNextRigIfAvailable(GameState gameState) {
    if (gameState.players[gameState.players.indexOf(widget.player)].resources[Equipment.drillRig]! > 0) {
      logger.i("Energy depleted, switching to next rig. Rigs remaining: ${gameState.players[gameState.players.indexOf(widget.player)].resources[Equipment.drillRig]}");
      setState(() {
        energy = 500;
        _isOutOfEnergy = false;
        drillXNormalized = 0.3333;
        drillYNormalized = 0.2436;
        statusMessage = "Drill to find Dilithium! (New Rig)";
      });
    } else {
      logger.w("Energy depleted and no rigs left, stopping mining phase");
      _meteorTimer?.cancel();
      _caveInTimer?.cancel();
    }
  }

  void _showEurekaNotification(String status) {
    if (status.contains("EUREKA")) {
      setState(() {
        statusMessage = status;
        _showEurekaHighlight = true;
      });
      _soundManager.playSound('dilithium');
      logger.i("Found Dilithium, playing sound and showing highlight");
      _eurekaTimer?.cancel();
      _eurekaTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          if (!statusMessage.contains("EUREKA")) statusMessage = "Drill to find Dilithium!";
          _showEurekaHighlight = false;
        });
      });
    } else {
      setState(() {
        statusMessage = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var gameState = context.watch<GameState>();
    final screenHeight = MediaQuery.of(context).size.height;
    final canvasHeight = screenHeight * 0.5;
    final canvasWidth = canvasHeight * 2;
    logger.d("Building MiningScreen with canvas size: ${canvasWidth}x$canvasHeight");

    if (widget.player.resources[Equipment.drillRig]! < 1 && !_isOutOfEnergy) {
      logger.w("No drill rigs available, cancelling timers and showing message");
      _meteorTimer?.cancel();
      _caveInTimer?.cancel();
      return const Center(child: Text("No Drill Rigs Available"));
    }

    if (_isOutOfEnergy && widget.player.resources[Equipment.drillRig]! <= 0) {
      logger.w("Out of energy and no rigs left, showing message");
      return const Center(child: Text("Out of Energy and No Rigs Left"));
    }

    return Column(
      children: [
        Container(
          height: canvasHeight,
          width: canvasWidth,
          decoration: _showEurekaHighlight
              ? BoxDecoration(
                  border: Border.all(color: Colors.yellow, width: 5),
                  color: Colors.yellow.withValues(alpha: 0.3), // Replace withOpacity with withValues
                )
              : null,
          child: GestureDetector(
            onPanUpdate: (details) {
              if (_isOutOfEnergy) {
                logger.d("Cannot move: out of energy, checking for next rig");
                _switchToNextRigIfAvailable(gameState);
                return;
              }
              setState(() {
                double oldX = drillXNormalized;
                double oldY = drillYNormalized;
                drillXNormalized += details.delta.dx / canvasWidth;
                drillYNormalized += details.delta.dy / canvasHeight;
                drillXNormalized = drillXNormalized.clamp(0.0, 1.0);
                drillYNormalized = drillYNormalized.clamp(0.25, 1.0);
                if (energy > 0) {
                  energy -= 10;
                  if (energy <= 0) {
                    energy = 0;
                    _isOutOfEnergy = true;
                    statusMessage = "Out of Energy!";
                    logger.w("Energy depleted, stopping movement for this rig");
                    _switchToNextRigIfAvailable(gameState);
                  }
                }
                logger.d("Drill moved from (x: $oldX, y: $oldY) to (x: $drillXNormalized, y: $drillYNormalized), energy: $energy");
                if (!_isOutOfEnergy) {
                  gameState.updateMining(
                    gameState.players.indexOf(widget.player),
                    drillXNormalized,
                    drillYNormalized,
                    energy,
                    canvasWidth,
                    canvasHeight,
                    _showEurekaNotification,
                  );
                }
              });
            },
            child: CustomPaint(
              painter: MiningCanvas(
                drillXNormalized,
                drillYNormalized,
                meteors,
                canvasWidth,
                canvasHeight,
                widget.player.resources[Equipment.drillRig]!,
                _isLosingRig,
                targetXNormalized,
                targetYNormalized,
                targetRadiusNormalized,
                showDebugIndicator: showDebugIndicator,
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
                "Drill Rigs Available: ${widget.player.resources[Equipment.drillRig]}",
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