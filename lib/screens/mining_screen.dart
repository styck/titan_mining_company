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
  double drillYNormalized = 0.2436; // Start at 19/78 (ground level)
  int energy = 500;
  String statusMessage = "Position your rig at the surface!";
  List<Offset> meteors = [];
  Timer? _meteorTimer;
  Timer? _caveInTimer;
  Timer? _eurekaTimer;
  final SoundManager _soundManager = SoundManager();
  final Random _random = Random();
  bool _isFirstEntry = true;
  bool _isLosingRig = false;
  bool _isOutOfEnergy = false;
  bool _showEurekaHighlight = false;
  bool _moveX = false;
  bool _hasMoved = false;
  bool _hasFoundCrystal = false;
  bool _positioningPhase = true; // Track if in positioning phase (horizontal movement only)

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

  double targetXNormalized = 0.3333; // Initial position: 50 / 150
  double targetYNormalized = 0.5; // Initial position: 40 / 78, adjusted for subsurface
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
          "First, move your rig left or right to position it at the surface. Then, drill downward to find Dilithium below the ground. Use DEFLECTOR and SAFETY to protect your operation!",
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
    logger.i("Starting meteor check timer (every 10 seconds)");
    _meteorTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
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
    int playerIndex = gameState.players.indexOf(widget.player);
    if (gameState.players[playerIndex].resources[Equipment.drillRig]! > 0) {
      logger.i("Switching to next rig. Rigs remaining: ${gameState.players[playerIndex].resources[Equipment.drillRig]}");
      setState(() {
        energy = 500;
        _isOutOfEnergy = false;
        _hasFoundCrystal = false;
        _positioningPhase = true;
        drillXNormalized = 0.3333;
        drillYNormalized = 0.2436;
        statusMessage = "Position your rig at the surface!";
      });
    } else {
      logger.w("No rigs left, stopping mining phase");
      _meteorTimer?.cancel();
      _caveInTimer?.cancel();
      setState(() {
        statusMessage = "Mining Phase Ended: No Rigs Left";
      });
    }
  }

  void _randomizeCrystalPosition() {
    // Ensure the crystal is within a reachable distance (Manhattan distance <= 0.5)
    // and strictly below the surface (Y >= 0.25)
    const double maxDistance = 0.5; // Maximum Manhattan distance (50 moves, 500 energy)
    const double startX = 0.3333; // Starting X position
    const double startY = 0.2436; // Starting Y position
    const double groundLevel = 0.2436; // Ground level

    // Randomly choose a total distance up to maxDistance
    double totalDistance = _random.nextDouble() * maxDistance;

    // Randomly split the distance between X and Y
    double dx = _random.nextDouble() * totalDistance;
    double dy = totalDistance - dx;

    // Randomly decide the direction for X (positive or negative)
    double newX = startX + (dx * (_random.nextBool() ? 1 : -1));
    newX = newX.clamp(0.0, 1.0); // Clamp X to canvas bounds

    // Ensure Y is strictly below the surface
    // Randomize Y between groundLevel and groundLevel + dy, then adjust to fit distance
    double maxYDistance = maxDistance - (newX - startX).abs(); // Remaining distance for Y
    if (maxYDistance < 0) maxYDistance = 0; // Ensure non-negative
    double newY = groundLevel + (_random.nextDouble() * maxYDistance);
    newY = newY.clamp(groundLevel, 1.0); // Ensure Y is below ground

    // If Y distance is less than intended due to clamping, adjust X to maintain total distance
    double actualDy = newY - startY;
    if (actualDy < dy) {
      double remainingDistance = totalDistance - actualDy;
      newX = startX + (remainingDistance * (_random.nextBool() ? 1 : -1));
      newX = newX.clamp(0.0, 1.0);
    }

    targetXNormalized = newX;
    targetYNormalized = newY;
    logger.d("New Dilithium target position: (x: $targetXNormalized, y: $targetYNormalized)");
  }

  void _showEurekaNotification(String status, GameState gameState) {
    if (status.contains("EUREKA") && !_hasFoundCrystal) {
      setState(() {
        statusMessage = status;
        _showEurekaHighlight = true;
        _hasFoundCrystal = true;
      });
      _soundManager.playSound('dilithium');
      logger.i("Found Dilithium, playing sound and showing highlight");
      _eurekaTimer?.cancel();
      _eurekaTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          _showEurekaHighlight = false;
          _randomizeCrystalPosition();
          _switchToNextRigIfAvailable(gameState);
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

    // Log the current state to debug
    logger.d("Drill rigs: ${widget.player.resources[Equipment.drillRig]}, isOutOfEnergy: $_isOutOfEnergy");

    // Update status message based on conditions, but always show the full UI
    if (widget.player.resources[Equipment.drillRig]! < 1 && !_isOutOfEnergy) {
      logger.w("No drill rigs available, cancelling timers");
      _meteorTimer?.cancel();
      _caveInTimer?.cancel();
      statusMessage = "No Drill Rigs Available - Buy more in Equipment!";
    } else if (_isOutOfEnergy && widget.player.resources[Equipment.drillRig]! <= 0) {
      logger.w("Out of energy and no rigs left");
      statusMessage = "Out of Energy and No Rigs Left";
    }

    return Column(
      children: [
        Container(
          height: canvasHeight,
          width: canvasWidth,
          decoration: _showEurekaHighlight
              ? BoxDecoration(
                  border: Border.all(color: Colors.yellow, width: 5),
                  color: Colors.yellow.withValues(alpha: 0.3),
                )
              : null,
          child: GestureDetector(
            onPanStart: (details) {
              _hasMoved = false;
            },
            onPanUpdate: (details) {
              if (_isOutOfEnergy || _hasFoundCrystal) {
                logger.d("Cannot move: out of energy or crystal found, checking for next rig");
                _switchToNextRigIfAvailable(gameState);
                return;
              }
              setState(() {
                double oldX = drillXNormalized;
                double oldY = drillYNormalized;
                const double stepSize = 0.01;

                if (!_hasMoved) {
                  double dx = details.delta.dx / canvasWidth;
                  double dy = details.delta.dy / canvasHeight;
                  _moveX = dx.abs() > dy.abs();
                  _hasMoved = true;
                }

                if (_positioningPhase) {
                  // Positioning phase: only allow horizontal movement
                  if (_moveX) {
                    double dx = details.delta.dx / canvasWidth;
                    if (dx > 0) {
                      drillXNormalized += stepSize; // Right
                      logger.d("Moving right: dx=$dx");
                    } else if (dx < 0) {
                      drillXNormalized -= stepSize; // Left
                      logger.d("Moving left: dx=$dx");
                    }
                  }
                  // Transition to drilling phase if moving down
                  if (!_moveX && details.delta.dy > 0) {
                    _positioningPhase = false;
                    statusMessage = "Drill to find Dilithium!";
                    drillYNormalized += stepSize; // Down
                    logger.d("Transitioning to drilling phase, moving down: dy=${details.delta.dy / canvasHeight}");
                  }
                } else {
                  // Drilling phase: allow left, right, down (but not up past surface)
                  if (_moveX) {
                    double dx = details.delta.dx / canvasWidth;
                    if (dx > 0) {
                      drillXNormalized += stepSize; // Right
                      logger.d("Moving right: dx=$dx");
                    } else if (dx < 0) {
                      drillXNormalized -= stepSize; // Left
                      logger.d("Moving left: dx=$dx");
                    }
                  } else {
                    double dy = details.delta.dy / canvasHeight;
                    if (dy > 0) {
                      drillYNormalized += stepSize; // Down
                      logger.d("Moving down: dy=$dy");
                    } else if (dy < 0 && drillYNormalized > 0.2436) {
                      drillYNormalized -= stepSize; // Up, but not past surface
                      logger.d("Moving up: dy=$dy");
                    }
                  }
                }

                drillXNormalized = drillXNormalized.clamp(0.0, 1.0);
                drillYNormalized = drillYNormalized.clamp(0.2436, 1.0);

                if (drillXNormalized != oldX || drillYNormalized != oldY) {
                  if (energy > 0) {
                    energy -= 10;
                    if (energy <= 0) {
                      energy = 0;
                      _isOutOfEnergy = true;
                      statusMessage = "Out of Energy! Rig lost.";
                      logger.w("Energy depleted, losing a rig");
                      // Decrement the rig count
                      int playerIndex = gameState.players.indexOf(widget.player);
                      gameState.players[playerIndex].resources[Equipment.drillRig] =
                          gameState.players[playerIndex].resources[Equipment.drillRig]! - 1;
                      gameState.notifyListeners(); // Notify listeners to update UI
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
                      (status) => _showEurekaNotification(status, gameState),
                      targetXNormalized,
                      targetYNormalized,
                      targetRadiusNormalized,
                    );
                  }
                }
              });
            },
            onPanEnd: (details) {
              _moveX = false;
              _hasMoved = false;
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