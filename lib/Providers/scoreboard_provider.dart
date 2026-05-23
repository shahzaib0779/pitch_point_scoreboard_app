import 'package:flutter/material.dart';
import 'package:pitch_point/models/match_models.dart';
import 'package:pitch_point/util/bat_ball_class.dart';
import 'package:pitch_point/util/inning.dart';

class ScoreboardProvider extends ChangeNotifier {
  Inning inning1 = Inning();
  Inning inning2 = Inning();

  int currentInning = 1;
  String striker = '';
  String nonStriker = '';
  String currentBowler = '';

  /// Deliveries in the current over, e.g. ['1','·','4','Wd','W','NB']
  List<String> currentOverBalls = [];

  // ── Database tracking ────────────────────────────────────────────────────

  int? matchId;
  int? inning1Id;
  int? inning2Id;

  int? get activeInningId =>
      currentInning == 1 ? inning1Id : inning2Id;

  bool get hasActiveMatch => matchId != null;

  void setMatchIds(int mid, int i1id, int i2id) {
    matchId = mid;
    inning1Id = i1id;
    inning2Id = i2id;
    notifyListeners();
  }

  // ── Active inning helper ─────────────────────────────────────────────────

  Inning get activeInning => currentInning == 1 ? inning1 : inning2;

  int get totalOvers => activeInning.totalOvers;

  // ── Player setters ───────────────────────────────────────────────────────

  void setStriker(String name) {
    striker = name;
    notifyListeners();
  }

  void setNonStriker(String name) {
    nonStriker = name;
    notifyListeners();
  }

  void setBowler(String name) {
    currentBowler = name;
    notifyListeners();
  }

  void inningOvers(int overs) {
    activeInning.totalOvers = overs;
    inning2.totalOvers = overs;
    notifyListeners();
  }

  void inningWickets(int wickets) {
    activeInning.inningWickets = wickets;
    inning2.inningWickets = wickets;
    notifyListeners();
  }

  // ── Match control ────────────────────────────────────────────────────────

  void switchInning() {
    currentInning = 2;
    currentBowler = '';
    striker = '';
    nonStriker = '';
    currentOverBalls = [];
    notifyListeners();
  }

  void resetMatch() {
    inning1 = Inning();
    inning2 = Inning();
    currentInning = 1;
    striker = '';
    nonStriker = '';
    currentBowler = '';
    currentOverBalls = [];
    matchId = null;
    inning1Id = null;
    inning2Id = null;
    notifyListeners();
  }

  void addBallToOver(String label) {
    currentOverBalls.add(label);
    notifyListeners();
  }

  // ── Strike rotation ──────────────────────────────────────────────────────

  void rotateStrike() {
    final temp = striker;
    striker = nonStriker;
    nonStriker = temp;
    notifyListeners();
  }

  // ── Batsman scoring ──────────────────────────────────────────────────────

  void updateBatsmanScore(String name, int runs, int balls) {
    if (!activeInning.battingList.any((b) => b.playerName == name)) {
      return;
    }
    final bat =
        activeInning.battingList.firstWhere((b) => b.playerName == name);
    bat.runs += runs;
    bat.balls += balls;
    if (runs == 4) { bat.fours++; }
    if (runs == 6) { bat.sixes++; }
    notifyListeners();
  }

  void addBallToBatsman() {
    if (striker.isEmpty) { return; }
    if (!activeInning.battingList.any((b) => b.playerName == striker)) {
      return;
    }
    activeInning.battingList
        .firstWhere((b) => b.playerName == striker)
        .balls++;
    notifyListeners();
  }

  void batsmanOut() {
    if (!activeInning.battingList.any((b) => b.playerName == striker)) {
      return;
    }
    activeInning.battingList
        .firstWhere((b) => b.playerName == striker)
        .bowled = true;
    notifyListeners();
  }

  // ── Bowler scoring ───────────────────────────────────────────────────────

  void updateBowlerScore(String name, int runs, int wickets) {
    if (!activeInning.bowlersList.any((b) => b.playerName == name)) {
      return;
    }
    final bowl =
        activeInning.bowlersList.firstWhere((b) => b.playerName == name);
    bowl.runsConceded += runs;
    bowl.wickets += wickets;
    bowl.balls++;
    if (bowl.balls == 6) {
      bowl.overs++;
      activeInning.oversBowled++;
    }
    activeInning.totalScore += runs;
    activeInning.totalWickets += wickets;
    notifyListeners();
  }

  // ── Wide ─────────────────────────────────────────────────────────────────
  // Ball does NOT count to over; runs charged to bowler; wides tracked.

  void updateWide(int totalRuns) {
    if (currentBowler.isEmpty) { return; }
    if (!activeInning.bowlersList
        .any((b) => b.playerName == currentBowler)) {
      return;
    }
    final bowl = activeInning.bowlersList
        .firstWhere((b) => b.playerName == currentBowler);
    bowl.runsConceded += totalRuns;
    // bowl.balls NOT incremented (wide doesn't count to over)
    activeInning.totalScore += totalRuns;
    activeInning.wides += totalRuns;
    notifyListeners();
  }

  // ── No Ball ───────────────────────────────────────────────────────────────
  // Ball does NOT count to over; +1 penalty always; runs off bat charged too.

  void updateNoBall(int runsOffBat, {bool isWicket = false}) {
    if (currentBowler.isEmpty) { return; }
    if (!activeInning.bowlersList
        .any((b) => b.playerName == currentBowler)) {
      return;
    }
    final bowl = activeInning.bowlersList
        .firstWhere((b) => b.playerName == currentBowler);
    bowl.runsConceded += runsOffBat + 1; // +1 penalty
    // bowl.balls NOT incremented (NB doesn't count to over)
    activeInning.totalScore += runsOffBat + 1;
    activeInning.noBalls++;
    if (isWicket) { activeInning.totalWickets++; }
    notifyListeners();
  }

  // ── Bye ───────────────────────────────────────────────────────────────────
  // Ball counts to over; runs go to byes (NOT bowler); batsman faces ball.

  void addBye(int runs) {
    if (currentBowler.isEmpty) { return; }
    if (!activeInning.bowlersList
        .any((b) => b.playerName == currentBowler)) {
      return;
    }
    final bowl = activeInning.bowlersList
        .firstWhere((b) => b.playerName == currentBowler);
    bowl.balls++;
    if (bowl.balls == 6) {
      bowl.overs++;
      activeInning.oversBowled++;
    }
    // runsConceded NOT incremented — byes not charged to bowler
    if (striker.isNotEmpty &&
        activeInning.battingList.any((b) => b.playerName == striker)) {
      activeInning.battingList
          .firstWhere((b) => b.playerName == striker)
          .balls++;
    }
    activeInning.totalScore += runs;
    activeInning.byes += runs;
    notifyListeners();
  }

  // ── Leg Bye ───────────────────────────────────────────────────────────────
  // Same as Bye but tracked separately.

  void addLegBye(int runs) {
    if (currentBowler.isEmpty) { return; }
    if (!activeInning.bowlersList
        .any((b) => b.playerName == currentBowler)) {
      return;
    }
    final bowl = activeInning.bowlersList
        .firstWhere((b) => b.playerName == currentBowler);
    bowl.balls++;
    if (bowl.balls == 6) {
      bowl.overs++;
      activeInning.oversBowled++;
    }
    // runsConceded NOT incremented — leg byes not charged to bowler
    if (striker.isNotEmpty &&
        activeInning.battingList.any((b) => b.playerName == striker)) {
      activeInning.battingList
          .firstWhere((b) => b.playerName == striker)
          .balls++;
    }
    activeInning.totalScore += runs;
    activeInning.legByes += runs;
    notifyListeners();
  }

  // ── Retired Hurt ──────────────────────────────────────────────────────────
  // Marks the current striker as retired hurt; caller must then set a new striker.

  void retiredHurt() {
    if (striker.isEmpty) { return; }
    if (!activeInning.battingList.any((b) => b.playerName == striker)) {
      return;
    }
    activeInning.battingList
        .firstWhere((b) => b.playerName == striker)
        .retiredHurt = true;
    striker = '';
    notifyListeners();
  }

  // ── Legacy alias kept for any callers that used it directly ──────────────
  @Deprecated('Use updateWide() or updateNoBall() instead')
  void updateWideOrNoBall() => updateWide(1);

  // ── Over helpers ─────────────────────────────────────────────────────────

  int getCurrentBowls() {
    if (currentBowler.isEmpty) { return 0; }
    if (!activeInning.bowlersList
        .any((b) => b.playerName == currentBowler)) {
      return 0;
    }
    return activeInning.bowlersList
        .firstWhere((b) => b.playerName == currentBowler)
        .balls;
  }

  void resetCurrentBowlerBalls() {
    if (currentBowler.isEmpty) { return; }
    if (!activeInning.bowlersList
        .any((b) => b.playerName == currentBowler)) {
      return;
    }
    activeInning.bowlersList
        .firstWhere((b) => b.playerName == currentBowler)
        .balls = 0;
    currentOverBalls = [];
    notifyListeners();
  }

  // ── Inning completion ────────────────────────────────────────────────────

  bool isInningCompleted() {
    if (activeInning.totalOvers == 0 || activeInning.inningWickets == 0) {
      return false;
    }
    if (activeInning.totalWickets >= activeInning.inningWickets) {
      return true;
    }
    if (activeInning.oversBowled >= activeInning.totalOvers) {
      return true;
    }
    if (currentInning == 2 &&
        activeInning.totalScore > inning1.totalScore) {
      return true;
    }
    return false;
  }

  String getMatchResult() {
    final s2 = activeInning.totalScore;
    final s1 = inning1.totalScore;
    if (s2 > s1) {
      final remaining =
          activeInning.inningWickets - activeInning.totalWickets;
      return '${activeInning.battingTeamName} won by '
          '$remaining wicket${remaining == 1 ? '' : 's'}!';
    } else if (s2 == s1) {
      return "It's a Tie! 🤝";
    } else {
      final margin = s1 - s2;
      return '${inning1.battingTeamName} won by '
          '$margin run${margin == 1 ? '' : 's'}!';
    }
  }

  // ── Resume: restore full state from DB records ────────────────────────────

  void loadFromMatchRecord({
    required MatchRecord match,
    required InningRecord inning1Record,
    InningRecord? inning2Record,
  }) {
    matchId = match.id;
    inning1Id = inning1Record.id;
    currentInning = match.currentInning;

    // Restore inning 1
    inning1 = _inningFromRecord(
        inning1Record, match.totalOvers, match.maxWickets);

    // Restore inning 2 (may be empty if match never reached it)
    if (inning2Record != null) {
      inning2Id = inning2Record.id;
      inning2 = _inningFromRecord(
          inning2Record, match.totalOvers, match.maxWickets);
    } else {
      inning2 = Inning()
        ..totalOvers = match.totalOvers
        ..inningWickets = match.maxWickets;
    }

    // Restore active players from whichever inning is current
    final active =
        currentInning == 1 ? inning1Record : (inning2Record ?? inning1Record);
    striker = active.currentStriker;
    nonStriker = active.currentNonStriker;
    currentBowler = active.currentBowler;

    notifyListeners();
  }

  // ── Private: build Inning from a record ──────────────────────────────────

  static Inning _inningFromRecord(
      InningRecord rec, int totalOvers, int maxWickets) {
    final inning = Inning()
      ..battingTeamName = rec.battingTeam
      ..bowlingTeamName = rec.bowlingTeam
      ..totalScore = rec.totalScore
      ..totalWickets = rec.totalWickets
      ..oversBowled = rec.oversBowled
      ..totalOvers = totalOvers
      ..inningWickets = maxWickets
      ..wides = rec.wides
      ..noBalls = rec.noBalls
      ..byes = rec.byes
      ..legByes = rec.legByes
      ..battingList = rec.battingList
          .map((r) => Batting(
                playerName: r.playerName,
                runs: r.runs,
                balls: r.balls,
                fours: r.fours,
                sixes: r.sixes,
                bowled: r.isOut,
                retiredHurt: r.isRetiredHurt,
              ))
          .toList()
      ..bowlersList = rec.bowlingList
          .map((r) => Bowling(
                playerName: r.playerName,
                overs: r.overs,
                balls: r.balls,
                runsConceded: r.runsConceded,
                wickets: r.wickets,
              ))
          .toList();

    // Restore the current bowler's ball count inside the over
    if (rec.currentBowler.isNotEmpty &&
        inning.bowlersList
            .any((b) => b.playerName == rec.currentBowler)) {
      final bowler = inning.bowlersList
          .firstWhere((b) => b.playerName == rec.currentBowler);
      bowler.balls = rec.ballsInOver;
    }

    return inning;
  }
}
