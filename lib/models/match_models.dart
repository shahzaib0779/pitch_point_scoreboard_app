// Data-transfer models that mirror the SQLite tables.
// All fields map 1-to-1 with column names (snake_case ↔ camelCase).

// ── Batting performance ───────────────────────────────────────────────────────

class BattingRecord {
  final int? id;
  final int inningId;
  final String playerName;
  final int battingPosition;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
  final bool isRetiredHurt;

  const BattingRecord({
    this.id,
    required this.inningId,
    required this.playerName,
    required this.battingPosition,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.isRetiredHurt = false,
  });

  factory BattingRecord.fromMap(Map<String, dynamic> m) => BattingRecord(
        id: m['id'] as int?,
        inningId: m['inning_id'] as int,
        playerName: m['player_name'] as String,
        battingPosition: m['batting_position'] as int? ?? 0,
        runs: m['runs'] as int? ?? 0,
        balls: m['balls'] as int? ?? 0,
        fours: m['fours'] as int? ?? 0,
        sixes: m['sixes'] as int? ?? 0,
        isOut: (m['is_out'] as int? ?? 0) == 1,
        isRetiredHurt: (m['is_retired_hurt'] as int? ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inning_id': inningId,
        'player_name': playerName,
        'batting_position': battingPosition,
        'runs': runs,
        'balls': balls,
        'fours': fours,
        'sixes': sixes,
        'is_out': isOut ? 1 : 0,
        'is_retired_hurt': isRetiredHurt ? 1 : 0,
      };

  BattingRecord copyWith({
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    bool? isOut,
    bool? isRetiredHurt,
  }) =>
      BattingRecord(
        id: id,
        inningId: inningId,
        playerName: playerName,
        battingPosition: battingPosition,
        runs: runs ?? this.runs,
        balls: balls ?? this.balls,
        fours: fours ?? this.fours,
        sixes: sixes ?? this.sixes,
        isOut: isOut ?? this.isOut,
        isRetiredHurt: isRetiredHurt ?? this.isRetiredHurt,
      );

  /// Strike-rate (0 if no balls faced).
  double get strikeRate =>
      balls == 0 ? 0.0 : (runs / balls) * 100;

  String get strikeRateStr =>
      strikeRate.toStringAsFixed(1);
}

// ── Bowling performance ───────────────────────────────────────────────────────

class BowlingRecord {
  final int? id;
  final int inningId;
  final String playerName;
  final int overs;
  final int balls; // balls in current (incomplete) over
  final int runsConceded;
  final int wickets;

  const BowlingRecord({
    this.id,
    required this.inningId,
    required this.playerName,
    this.overs = 0,
    this.balls = 0,
    this.runsConceded = 0,
    this.wickets = 0,
  });

  factory BowlingRecord.fromMap(Map<String, dynamic> m) => BowlingRecord(
        id: m['id'] as int?,
        inningId: m['inning_id'] as int,
        playerName: m['player_name'] as String,
        overs: m['overs'] as int? ?? 0,
        balls: m['balls'] as int? ?? 0,
        runsConceded: m['runs_conceded'] as int? ?? 0,
        wickets: m['wickets'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inning_id': inningId,
        'player_name': playerName,
        'overs': overs,
        'balls': balls,
        'runs_conceded': runsConceded,
        'wickets': wickets,
      };

  /// Economy (runs per over, 0 if no overs bowled).
  double get economy {
    final totalBalls = overs * 6 + balls;
    if (totalBalls == 0) { return 0.0; }
    return runsConceded / (totalBalls / 6);
  }

  String get economyStr => economy.toStringAsFixed(2);

  /// Display string: e.g. "3.4"
  String get oversStr => '$overs.${balls == 6 ? 0 : balls}';
}

// ── Inning record ─────────────────────────────────────────────────────────────

class InningRecord {
  final int? id;
  final int matchId;
  final int inningNumber;
  final String battingTeam;
  final String bowlingTeam;
  final int totalScore;
  final int totalWickets;
  final int oversBowled;
  final int ballsInOver; // balls bowled in the current over
  final String currentStriker;
  final String currentNonStriker;
  final String currentBowler;
  final bool isCompleted;

  // Extras breakdown
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;

  // Populated by MatchService after a JOIN
  final List<BattingRecord> battingList;
  final List<BowlingRecord> bowlingList;

  const InningRecord({
    this.id,
    required this.matchId,
    required this.inningNumber,
    required this.battingTeam,
    required this.bowlingTeam,
    this.totalScore = 0,
    this.totalWickets = 0,
    this.oversBowled = 0,
    this.ballsInOver = 0,
    this.currentStriker = '',
    this.currentNonStriker = '',
    this.currentBowler = '',
    this.isCompleted = false,
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.battingList = const [],
    this.bowlingList = const [],
  });

  int get totalExtras => wides + noBalls + byes + legByes;

  factory InningRecord.fromMap(Map<String, dynamic> m) => InningRecord(
        id: m['id'] as int?,
        matchId: m['match_id'] as int,
        inningNumber: m['inning_number'] as int,
        battingTeam: m['batting_team'] as String? ?? '',
        bowlingTeam: m['bowling_team'] as String? ?? '',
        totalScore: m['total_score'] as int? ?? 0,
        totalWickets: m['total_wickets'] as int? ?? 0,
        oversBowled: m['overs_bowled'] as int? ?? 0,
        ballsInOver: m['balls_in_over'] as int? ?? 0,
        currentStriker: m['current_striker'] as String? ?? '',
        currentNonStriker: m['current_non_striker'] as String? ?? '',
        currentBowler: m['current_bowler'] as String? ?? '',
        isCompleted: (m['is_completed'] as int? ?? 0) == 1,
        wides: m['wides'] as int? ?? 0,
        noBalls: m['no_balls'] as int? ?? 0,
        byes: m['byes'] as int? ?? 0,
        legByes: m['leg_byes'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'match_id': matchId,
        'inning_number': inningNumber,
        'batting_team': battingTeam,
        'bowling_team': bowlingTeam,
        'total_score': totalScore,
        'total_wickets': totalWickets,
        'overs_bowled': oversBowled,
        'balls_in_over': ballsInOver,
        'current_striker': currentStriker,
        'current_non_striker': currentNonStriker,
        'current_bowler': currentBowler,
        'is_completed': isCompleted ? 1 : 0,
        'wides': wides,
        'no_balls': noBalls,
        'byes': byes,
        'leg_byes': legByes,
      };

  InningRecord withPlayers({
    required List<BattingRecord> batting,
    required List<BowlingRecord> bowling,
  }) =>
      InningRecord(
        id: id,
        matchId: matchId,
        inningNumber: inningNumber,
        battingTeam: battingTeam,
        bowlingTeam: bowlingTeam,
        totalScore: totalScore,
        totalWickets: totalWickets,
        oversBowled: oversBowled,
        ballsInOver: ballsInOver,
        currentStriker: currentStriker,
        currentNonStriker: currentNonStriker,
        currentBowler: currentBowler,
        isCompleted: isCompleted,
        wides: wides,
        noBalls: noBalls,
        byes: byes,
        legByes: legByes,
        battingList: batting,
        bowlingList: bowling,
      );

  String get scoreDisplay => '$totalScore/$totalWickets';
  String get oversDisplay =>
      '$oversBowled.${ballsInOver == 6 ? 0 : ballsInOver}';
}

// ── Match record ──────────────────────────────────────────────────────────────

class MatchRecord {
  final int? id;
  final String team1Name;
  final String team2Name;
  final String tossWinner;
  final String tossDecision; // 'bat' | 'bowl'
  final int totalOvers;
  final int maxWickets;
  final String result;
  final String winner;
  final bool isCompleted;
  final int currentInning;
  final String createdAt;

  // Populated after a full load
  final List<InningRecord> innings;

  const MatchRecord({
    this.id,
    required this.team1Name,
    required this.team2Name,
    this.tossWinner = '',
    this.tossDecision = '',
    this.totalOvers = 0,
    this.maxWickets = 0,
    this.result = '',
    this.winner = '',
    this.isCompleted = false,
    this.currentInning = 1,
    required this.createdAt,
    this.innings = const [],
  });

  factory MatchRecord.fromMap(Map<String, dynamic> m) => MatchRecord(
        id: m['id'] as int?,
        team1Name: m['team1_name'] as String,
        team2Name: m['team2_name'] as String,
        tossWinner: m['toss_winner'] as String? ?? '',
        tossDecision: m['toss_decision'] as String? ?? '',
        totalOvers: m['total_overs'] as int? ?? 0,
        maxWickets: m['max_wickets'] as int? ?? 0,
        result: m['result'] as String? ?? '',
        winner: m['winner'] as String? ?? '',
        isCompleted: (m['is_completed'] as int? ?? 0) == 1,
        currentInning: m['current_inning'] as int? ?? 1,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'team1_name': team1Name,
        'team2_name': team2Name,
        'toss_winner': tossWinner,
        'toss_decision': tossDecision,
        'total_overs': totalOvers,
        'max_wickets': maxWickets,
        'result': result,
        'winner': winner,
        'is_completed': isCompleted ? 1 : 0,
        'current_inning': currentInning,
        'created_at': createdAt,
      };

  MatchRecord withInnings(List<InningRecord> inns) => MatchRecord(
        id: id,
        team1Name: team1Name,
        team2Name: team2Name,
        tossWinner: tossWinner,
        tossDecision: tossDecision,
        totalOvers: totalOvers,
        maxWickets: maxWickets,
        result: result,
        winner: winner,
        isCompleted: isCompleted,
        currentInning: currentInning,
        createdAt: createdAt,
        innings: inns,
      );

  /// Convenience: find inning 1 / inning 2
  InningRecord? get inning1 =>
      innings.where((i) => i.inningNumber == 1).firstOrNull;
  InningRecord? get inning2 =>
      innings.where((i) => i.inningNumber == 2).firstOrNull;

  String get matchTitle => '$team1Name vs $team2Name';
}
