import 'package:pitch_point/util/bat_ball_class.dart';

class Inning {
  List<Bowling> bowlersList = [];
  List<Batting> battingList = [];
  String battingTeamName = '';
  String bowlingTeamName = '';
  int totalScore = 0;
  int totalWickets = 0;
  int inningWickets = 0;
  int totalOvers = 0;
  int oversBowled = 0;
  double currentRunrate = 0.0;

  // ── Extras ──────────────────────────────────────────────────────────────────
  int wides = 0;
  int noBalls = 0;
  int byes = 0;
  int legByes = 0;

  int get totalExtras => wides + noBalls + byes + legByes;

  // ── Player management ────────────────────────────────────────────────────────

  void addBatsman(Batting batsman) {
    battingList.add(batsman);
  }

  void addBowler(Bowling bowler) {
    final exists = bowlersList.any((b) => b.playerName == bowler.playerName);
    if (!exists) {
      bowlersList.add(bowler);
    }
  }
}
