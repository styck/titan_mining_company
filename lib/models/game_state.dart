import 'package:flutter/foundation.dart';

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
    resources = Map.fromIterable(
      Equipment.values,
      key: (e) => e,
      value: (e) => 0,
    );
    resources[Equipment.credit] = 500;
    resources[Equipment.manpower] = 100;
    resources[Equipment.efficiency] = 5;
    resources[Equipment.energizer] = 1;
  }
}

class GameState extends ChangeNotifier {
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

  void updateMining(int playerIndex, int drillX, int drillY, int energy, Function(String) setStatus) {
    var p = players[playerIndex];
    if (energy < 1) {
      setStatus("Out of Energy!");
      return;
    }
    if (drillY < 20) {
      setStatus("SURFACE");
      return;
    }
    int v1 = 50, v2 = 40, ra = 10 - difficulty;
    if (drillX >= v1 - ra && drillX <= v1 + ra && drillY >= v2 - ra && drillY <= v2 + ra) {
      setStatus("EUREKA! You found DILITHIUM!!!");
      p.resources[Equipment.veins] = p.resources[Equipment.veins]! + 1;
      p.resources[Equipment.credit] = p.resources[Equipment.credit]! + 500;
    } else {
      setStatus("ICE AND ROCK");
    }
    notifyListeners();
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
}