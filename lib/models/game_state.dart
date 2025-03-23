import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

enum Equipment {
  status,
  drillRig,
  robominer,
  deflector,
  rdUnit,
  refinery,
  energizer,
  laborPool,
  shiftTime,
  wageScale,
  recreation,
  safety,
  bonuses,
  credit,
  manpower,
  efficiency,
  veins
}

class Player {
  Map<Equipment, int> resources = {};
  String baseName;

  Player(this.baseName) {
    resources = {for (var e in Equipment.values) e: 0};
    resources[Equipment.credit] = 500;
    resources[Equipment.manpower] = 100;
    resources[Equipment.efficiency] = 5;
    resources[Equipment.energizer] = 1;
  }
}

class GameState extends ChangeNotifier {
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

  int day = 0;
  int year = 2050;
  int numPlayers = 1;
  int difficulty = 5;
  List<Player> players = [];
  List<int> costs = [
    0,    // status
    100,  // drillRig
    200,  // robominer
    300,  // deflector
    400,  // rdUnit
    500,  // refinery
    2000, // energizer
    5,    // laborPool
    10,   // shiftTime
    100,  // wageScale
    200,  // recreation
    300,  // safety
    400,  // bonuses
    0,    // credit
    0,    // manpower
    0,    // efficiency
    0,    // veins
  ];
  final Random _random = Random();

  GameState() {
    players.add(Player("ACTAEON"));
  }

  void addPlayer(String baseName) {
    players.add(Player(baseName));
    notifyListeners();
  }

  void setNumPlayers(int num) {
    numPlayers = num;
    notifyListeners();
  }

  void setDifficulty(int diff) {
    difficulty = diff;
    notifyListeners();
  }

  void buyEquipment(int playerIndex, Equipment eq) {
    var p = players[playerIndex];
    if (p.resources[Equipment.credit]! >= costs[eq.index]) {
      p.resources[eq] = p.resources[eq]! + 1;
      p.resources[Equipment.credit] = p.resources[Equipment.credit]! - costs[eq.index];
      notifyListeners();
    }
  }

  void sellEquipment(int playerIndex, Equipment eq) {
    var p = players[playerIndex];
    if (p.resources[eq]! > 0) {
      p.resources[eq] = p.resources[eq]! - 1;
      p.resources[Equipment.credit] = p.resources[Equipment.credit]! + costs[eq.index];
      notifyListeners();
    }
  }

  void calculateLaborConditions(int playerIndex) {
    var p = players[playerIndex];
    p.resources[Equipment.laborPool] = p.resources[Equipment.manpower]! -
        (p.resources[Equipment.drillRig]! * difficulty) -
        (p.resources[Equipment.robominer]! * difficulty * 2) -
        (p.resources[Equipment.deflector]! * difficulty * 3) -
        (p.resources[Equipment.rdUnit]! * difficulty * 4) -
        (p.resources[Equipment.refinery]! * difficulty * 5) -
        (p.resources[Equipment.energizer]! * difficulty * 10);

    costs[Equipment.wageScale.index] = p.resources[Equipment.manpower]!;
    costs[Equipment.recreation.index] = p.resources[Equipment.manpower]! * 2;
    costs[Equipment.safety.index] = p.resources[Equipment.manpower]! * 3;
    costs[Equipment.bonuses.index] = p.resources[Equipment.manpower]! * 4;

    _calculateEfficiency(playerIndex);
    notifyListeners();
  }

  void adjustCondition(int playerIndex, Equipment eq, bool increase) {
    var p = players[playerIndex];
    if (increase && p.resources[Equipment.credit]! >= costs[eq.index]) {
      p.resources[eq] = p.resources[eq]! + 1;
      p.resources[Equipment.credit] = p.resources[Equipment.credit]! - costs[eq.index];
      if (eq == Equipment.laborPool) {
        p.resources[Equipment.manpower] = p.resources[Equipment.manpower]! + 1;
      }
    } else if (!increase && p.resources[eq]! > 0) {
      p.resources[eq] = p.resources[eq]! - 1;
      p.resources[Equipment.credit] = p.resources[Equipment.credit]! + costs[eq.index];
      if (eq == Equipment.laborPool) {
        p.resources[Equipment.manpower] = p.resources[Equipment.manpower]! - 1;
      }
    }
    calculateLaborConditions(playerIndex);
  }

  void _calculateEfficiency(int playerIndex) {
    var p = players[playerIndex];
    int ff = 0;
    for (int z = 1; z <= 5; z++) {
      ff += p.resources[Equipment.values[z]]! * z;
    }
    if (ff < 1) ff = 1;
    double ef = p.resources[Equipment.energizer]! * 10 / ff;
    if (ef > 1) ef = ff / (p.resources[Equipment.energizer]! * 10);
    ef = ef * 100;
    ff = p.resources[Equipment.laborPool]! * 2;
    if (ff < 0) ff = ff * -2;
    ef -= ff;
    ff = (p.resources[Equipment.shiftTime]! - 6) * 3;
    if (ff < 0) ff = ff * -2;
    ef -= ff +
        (p.resources[Equipment.wageScale]! * 5) +
        (p.resources[Equipment.recreation]! * 5) +
        (p.resources[Equipment.safety]! * 7.5) +
        (p.resources[Equipment.bonuses]! * 10);
    ef = ef.round().toDouble();
    if (ef < 5) ef = 5;
    if (ef > 100) ef = 100;
    if (p.resources[Equipment.wageScale] == 0) ef = 1;
    p.resources[Equipment.efficiency] = ef.round();
  }

  void updateMining(
    int playerIndex,
    double drillXNormalized,
    double drillYNormalized,
    int energy,
    double canvasWidth,
    double canvasHeight,
    Function(String) setStatus,
    double targetXNormalized, // Pass target position from MiningScreen
    double targetYNormalized,
    double targetRadiusNormalized,
  ) {
    var p = players[playerIndex];
    if (energy < 1) {
      setStatus("Out of Energy!");
      return;
    }
    if (drillYNormalized < 0.25) {
      setStatus("SURFACE");
      return;
    }
    
    if (drillXNormalized >= targetXNormalized - targetRadiusNormalized &&
        drillXNormalized <= targetXNormalized + targetRadiusNormalized &&
        drillYNormalized >= targetYNormalized - targetRadiusNormalized &&
        drillYNormalized <= targetYNormalized + targetRadiusNormalized) {
      setStatus("EUREKA! You found DILITHIUM!!!");
      p.resources[Equipment.veins] = p.resources[Equipment.veins]! + 1;
      p.resources[Equipment.credit] = p.resources[Equipment.credit]! + 500;
      notifyListeners();
    } else {
      setStatus("ICE AND ROCK");
    }
  }

  bool checkMeteorImpact(int playerIndex, Function(String) setStatus) {
    var p = players[playerIndex];
    if (p.resources[Equipment.drillRig]! <= 0) return false;

    double r = _random.nextDouble() - (p.resources[Equipment.deflector]! * 0.2);
    if (r >= 0.8) {
      if (p.resources[Equipment.deflector]! > 0) {
        setStatus("Meteor shower deflected!");
      } else {
        setStatus("Meteor shower! Drill rig damaged!");
        p.resources[Equipment.drillRig] = p.resources[Equipment.drillRig]! - 1;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  bool checkCaveIn(int playerIndex, double drillYNormalized, Function(String) setStatus) {
    var p = players[playerIndex];
    if (p.resources[Equipment.drillRig]! <= 0 || p.resources[Equipment.veins]! <= 0) return false;

    double r = _random.nextDouble() - (p.resources[Equipment.safety]! * 0.15);
    if (r >= 0.7 && drillYNormalized > 0.25) {
      if (p.resources[Equipment.safety]! > 0) {
        setStatus("Cave-in prevented by safety measures!");
      } else {
        setStatus("Cave-in! Lost workers and vein!");
        p.resources[Equipment.manpower] = p.resources[Equipment.manpower]! - _random.nextInt(5) - 1;
        p.resources[Equipment.veins] = p.resources[Equipment.veins]! - 1;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateCredits(int playerIndex) {
    var p = players[playerIndex];
    int z = p.resources[Equipment.refinery]!;
    if (p.resources[Equipment.veins]! < z) z = p.resources[Equipment.veins]!;
    p.resources[Equipment.credit] = (p.resources[Equipment.credit]! +
            (p.resources[Equipment.credit]! * 0.1).round() +
            500 +
            150 * p.resources[Equipment.status]! +
            (z * 25 * p.resources[Equipment.shiftTime]!))
        .round();
    p.resources[Equipment.status] = p.resources[Equipment.status]! + p.resources[Equipment.veins]!;
    notifyListeners();
  }

  void updateCosts() {
    for (int z = 1; z <= 8; z++) {
      int x = 0;
      for (int y = 0; y < numPlayers; y++) {
        x += players[y].resources[Equipment.values[z]]!;
      }
      x = x ~/ numPlayers;
      if (z > 5) {
        costs[z] = (costs[z] + (costs[z] * (x / (55 - difficulty))).round()).round();
      } else {
        costs[z] = (costs[z] + (costs[z] * x / (25 - difficulty)) - (costs[z] * 1 / (25 - difficulty))).round();
        if (costs[z] < 100 * z) costs[z] = 100 * z;
        if (costs[z] < 200 * z) costs[z] = 200 * z;
      }
    }
    for (int z = 7; z <= 8; z++) {
      if (costs[z] < 1) costs[z] = 1;
      if (costs[z] > 50) costs[z] = 50;
    }
    if (costs[6] > 4000) costs[6] = 4000;

    for (int z = 0; z < numPlayers; z++) {
      for (int y = 8; y <= 12; y++) {
        players[z].resources[Equipment.values[y]] = 0;
      }
    }
    notifyListeners();
  }

  void advanceTime() {
    day++;
    if (day > 12) {
      day = 1;
      year++;
    }
    notifyListeners();
  }

  bool checkEndgame() {
    return year == 2051 && day == 3;
  }

  void calculateFinalStatus() {
    for (int i = 0; i < numPlayers; i++) {
      var p = players[i];
      p.resources[Equipment.status] = (p.resources[Equipment.veins]! * 100 +
              p.resources[Equipment.efficiency]! +
              p.resources[Equipment.manpower]! +
              p.resources[Equipment.credit]! +
              _random.nextInt(100))
          .round();
      if (p.resources[Equipment.status]! < 0) p.resources[Equipment.status] = 0;
    }
    notifyListeners();
  }

  Player? determineWinner() {
    if (numPlayers == 1) {
      if (players[0].resources[Equipment.status]! > 19) {
        return players[0];
      }
      return null;
    } else {
      int highestStatus = -1;
      Player? winner;
      for (var p in players) {
        if (p.resources[Equipment.status]! > highestStatus) {
          highestStatus = p.resources[Equipment.status]!;
          winner = p;
        }
      }
      return winner;
    }
  }
}