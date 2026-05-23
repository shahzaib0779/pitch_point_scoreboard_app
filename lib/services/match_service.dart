import 'package:pitch_point/db/database_helper.dart';
import 'package:pitch_point/models/match_models.dart';
import 'package:pitch_point/Providers/scoreboard_provider.dart';

// High-level operations that bridge the provider state and the database.

class MatchService {
  MatchService._();
  static final MatchService instance = MatchService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── Create a new match + both inning stubs ────────────────────────────────

  Future<({int matchId, int inning1Id, int inning2Id})> createMatch({
    required String team1,
    required String team2,
    required String tossWinner,
    required String tossDecision,
    required int totalOvers,
    required int maxWickets,
    required String inning1BattingTeam,
    required String inning1BowlingTeam,
    required String inning2BattingTeam,
    required String inning2BowlingTeam,
  }) async {
    final now = DateTime.now().toIso8601String();

    final matchId = await _db.insertMatch({
      'team1_name': team1,
      'team2_name': team2,
      'toss_winner': tossWinner,
      'toss_decision': tossDecision,
      'total_overs': totalOvers,
      'max_wickets': maxWickets,
      'is_completed': 0,
      'current_inning': 1,
      'created_at': now,
    });

    final inning1Id = await _db.insertInning({
      'match_id': matchId,
      'inning_number': 1,
      'batting_team': inning1BattingTeam,
      'bowling_team': inning1BowlingTeam,
      'is_completed': 0,
    });

    final inning2Id = await _db.insertInning({
      'match_id': matchId,
      'inning_number': 2,
      'batting_team': inning2BattingTeam,
      'bowling_team': inning2BowlingTeam,
      'is_completed': 0,
    });

    return (matchId: matchId, inning1Id: inning1Id, inning2Id: inning2Id);
  }

  // ── Persist provider state after every delivery ───────────────────────────

  Future<void> saveProgress(ScoreboardProvider sp) async {
    if (sp.matchId == null) { return; }

    await _db.updateMatch(sp.matchId!, {
      'current_inning': sp.currentInning,
      'total_overs': sp.inning1.totalOvers,
      'max_wickets': sp.inning1.inningWickets,
    });

    await _saveInningState(sp, 1);
    await _saveInningState(sp, 2);
  }

  Future<void> _saveInningState(
      ScoreboardProvider sp, int inningNum) async {
    final inning = inningNum == 1 ? sp.inning1 : sp.inning2;
    final inningId =
        inningNum == 1 ? sp.inning1Id : sp.inning2Id;
    if (inningId == null) { return; }

    final isActive = sp.currentInning == inningNum;

    await _db.updateInning(inningId, {
      'total_score': inning.totalScore,
      'total_wickets': inning.totalWickets,
      'overs_bowled': inning.oversBowled,
      'balls_in_over': isActive ? sp.getCurrentBowls() : 0,
      'current_striker': isActive ? sp.striker : '',
      'current_non_striker': isActive ? sp.nonStriker : '',
      'current_bowler': isActive ? sp.currentBowler : '',
      // Inning 1 is complete once inning 2 has started
      'is_completed': (!isActive && inningNum == 1) ? 1 : 0,
      // Extras
      'wides': inning.wides,
      'no_balls': inning.noBalls,
      'byes': inning.byes,
      'leg_byes': inning.legByes,
    });

    // Batting performances
    int position = 0;
    for (final b in inning.battingList) {
      await _db.upsertBatting({
        'inning_id': inningId,
        'player_name': b.playerName,
        'batting_position': position++,
        'runs': b.runs,
        'balls': b.balls,
        'fours': b.fours,
        'sixes': b.sixes,
        'is_out': b.bowled ? 1 : 0,
        'is_retired_hurt': b.retiredHurt ? 1 : 0,
      });
    }

    // Bowling performances
    for (final b in inning.bowlersList) {
      await _db.upsertBowling({
        'inning_id': inningId,
        'player_name': b.playerName,
        'overs': b.overs,
        'balls': b.balls,
        'runs_conceded': b.runsConceded,
        'wickets': b.wickets,
      });
    }
  }

  // ── Mark match complete ───────────────────────────────────────────────────

  Future<void> completeMatch(
      int matchId, String result, String winner) async {
    await _db.updateMatch(matchId, {
      'is_completed': 1,
      'result': result,
      'winner': winner,
    });
    final innings = await _db.getInningsForMatch(matchId);
    for (final row in innings) {
      await _db.updateInning(row['id'] as int, {'is_completed': 1});
    }
  }

  // ── Load full match with all player data ──────────────────────────────────

  Future<MatchRecord?> getFullMatch(int matchId) async {
    final matchRow = await _db.getMatchById(matchId);
    if (matchRow == null) { return null; }

    final inningRows = await _db.getInningsForMatch(matchId);
    final List<InningRecord> inningRecords = [];

    for (final iRow in inningRows) {
      final inningId = iRow['id'] as int;
      final batting = await _db.getBattingForInning(inningId);
      final bowling = await _db.getBowlingForInning(inningId);

      inningRecords.add(
        InningRecord.fromMap(iRow).withPlayers(
          batting: batting.map(BattingRecord.fromMap).toList(),
          bowling: bowling.map(BowlingRecord.fromMap).toList(),
        ),
      );
    }

    return MatchRecord.fromMap(matchRow).withInnings(inningRecords);
  }

  // ── Last incomplete match for the resume prompt ───────────────────────────

  Future<MatchRecord?> getIncompleteMatch() async {
    final row = await _db.getLastIncompleteMatch();
    if (row == null) { return null; }
    return getFullMatch(row['id'] as int);
  }

  // ── All matches for history page ──────────────────────────────────────────

  Future<List<MatchRecord>> getAllMatches() async {
    final rows = await _db.getAllMatches();
    final List<MatchRecord> results = [];
    for (final row in rows) {
      final full = await getFullMatch(row['id'] as int);
      if (full != null) { results.add(full); }
    }
    return results;
  }

  // ── Restore provider from a saved match (resume) ──────────────────────────

  Future<bool> resumeMatch(int matchId, ScoreboardProvider sp) async {
    final record = await getFullMatch(matchId);
    if (record == null) { return false; }

    final i1 = record.inning1;
    if (i1 == null) { return false; }

    sp.loadFromMatchRecord(
      match: record,
      inning1Record: i1,
      inning2Record: record.inning2,
    );
    return true;
  }

  // ── Delete a match ────────────────────────────────────────────────────────

  Future<void> deleteMatch(int matchId) async {
    await _db.deleteMatch(matchId);
  }
}
