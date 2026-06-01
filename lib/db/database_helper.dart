import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

// Singleton SQLite helper.
// All public methods return raw Map<String,dynamic> rows so the service layer
// can map them to typed models without coupling this class to any model.

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  // ── Open / create ─────────────────────────────────────────────────────────

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'pitch_point.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE matches (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        team1_name      TEXT    NOT NULL,
        team2_name      TEXT    NOT NULL,
        toss_winner     TEXT    DEFAULT '',
        toss_decision   TEXT    DEFAULT '',
        total_overs     INTEGER DEFAULT 0,
        max_wickets     INTEGER DEFAULT 0,
        result          TEXT    DEFAULT '',
        winner          TEXT    DEFAULT '',
        man_of_match    TEXT    DEFAULT '',
        is_completed    INTEGER DEFAULT 0,
        current_inning  INTEGER DEFAULT 1,
        created_at      TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE innings (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id            INTEGER NOT NULL,
        inning_number       INTEGER NOT NULL,
        batting_team        TEXT    DEFAULT '',
        bowling_team        TEXT    DEFAULT '',
        total_score         INTEGER DEFAULT 0,
        total_wickets       INTEGER DEFAULT 0,
        overs_bowled        INTEGER DEFAULT 0,
        balls_in_over       INTEGER DEFAULT 0,
        current_striker     TEXT    DEFAULT '',
        current_non_striker TEXT    DEFAULT '',
        current_bowler      TEXT    DEFAULT '',
        is_completed        INTEGER DEFAULT 0,
        wides               INTEGER DEFAULT 0,
        no_balls            INTEGER DEFAULT 0,
        byes                INTEGER DEFAULT 0,
        leg_byes            INTEGER DEFAULT 0,
        FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');

    // UNIQUE(inning_id, player_name) enables INSERT OR REPLACE upsert.
    await db.execute('''
      CREATE TABLE batting_performances (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        inning_id        INTEGER NOT NULL,
        player_name      TEXT    NOT NULL,
        batting_position INTEGER DEFAULT 0,
        runs             INTEGER DEFAULT 0,
        balls            INTEGER DEFAULT 0,
        fours            INTEGER DEFAULT 0,
        sixes            INTEGER DEFAULT 0,
        is_out           INTEGER DEFAULT 0,
        is_retired_hurt  INTEGER DEFAULT 0,
        UNIQUE(inning_id, player_name),
        FOREIGN KEY (inning_id) REFERENCES innings(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE bowling_performances (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        inning_id     INTEGER NOT NULL,
        player_name   TEXT    NOT NULL,
        overs         INTEGER DEFAULT 0,
        balls         INTEGER DEFAULT 0,
        runs_conceded INTEGER DEFAULT 0,
        wickets       INTEGER DEFAULT 0,
        UNIQUE(inning_id, player_name),
        FOREIGN KEY (inning_id) REFERENCES innings(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE over_scores (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        inning_id    INTEGER NOT NULL,
        over_number  INTEGER NOT NULL,
        score        INTEGER NOT NULL,
        wickets      INTEGER NOT NULL,
        FOREIGN KEY (inning_id) REFERENCES innings(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Migration: v1 → v2 (add extras + retired_hurt columns) ───────────────
  // Each ALTER TABLE is wrapped in try-catch so it silently skips if a column
  // already exists in a dev build where the schema was manually bumped.

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final stmt in const [
        'ALTER TABLE innings ADD COLUMN wides    INTEGER DEFAULT 0',
        'ALTER TABLE innings ADD COLUMN no_balls INTEGER DEFAULT 0',
        'ALTER TABLE innings ADD COLUMN byes     INTEGER DEFAULT 0',
        'ALTER TABLE innings ADD COLUMN leg_byes INTEGER DEFAULT 0',
        'ALTER TABLE batting_performances ADD COLUMN is_retired_hurt INTEGER DEFAULT 0',
      ]) {
        try { await db.execute(stmt); } catch (_) {}
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS over_scores (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            inning_id    INTEGER NOT NULL,
            over_number  INTEGER NOT NULL,
            score        INTEGER NOT NULL,
            wickets      INTEGER NOT NULL,
            FOREIGN KEY (inning_id) REFERENCES innings(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE matches ADD COLUMN man_of_match TEXT DEFAULT \'\'');
      } catch (_) {}
    }
  }

  // ── Match CRUD ────────────────────────────────────────────────────────────

  Future<int> insertMatch(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('matches', data);
  }

  Future<void> updateMatch(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('matches', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getMatchById(int id) async {
    final db = await database;
    final rows =
        await db.query('matches', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns the most recent match that has not been completed.
  Future<Map<String, dynamic>?> getLastIncompleteMatch() async {
    final db = await database;
    final rows = await db.query(
      'matches',
      where: 'is_completed = 0',
      orderBy: 'id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns all matches ordered newest-first.
  Future<List<Map<String, dynamic>>> getAllMatches() async {
    final db = await database;
    return db.query('matches', orderBy: 'id DESC');
  }

  Future<void> deleteMatch(int id) async {
    final db = await database;
    await db.delete('matches', where: 'id = ?', whereArgs: [id]);
  }

  // ── Innings CRUD ──────────────────────────────────────────────────────────

  Future<int> insertInning(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('innings', data);
  }

  Future<void> updateInning(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('innings', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getInningsForMatch(
      int matchId) async {
    final db = await database;
    return db.query(
      'innings',
      where: 'match_id = ?',
      whereArgs: [matchId],
      orderBy: 'inning_number ASC',
    );
  }

  // ── Batting CRUD ──────────────────────────────────────────────────────────

  /// INSERT OR REPLACE — uses the UNIQUE(inning_id, player_name) constraint.
  Future<void> upsertBatting(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'batting_performances',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getBattingForInning(
      int inningId) async {
    final db = await database;
    return db.query(
      'batting_performances',
      where: 'inning_id = ?',
      whereArgs: [inningId],
      orderBy: 'batting_position ASC',
    );
  }

  // ── Bowling CRUD ──────────────────────────────────────────────────────────

  Future<void> upsertBowling(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'bowling_performances',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getBowlingForInning(
      int inningId) async {
    final db = await database;
    return db.query(
      'bowling_performances',
      where: 'inning_id = ?',
      whereArgs: [inningId],
    );
  }

  // ── Over scores CRUD ──────────────────────────────────────────────────────

  Future<void> insertOverScore(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('over_scores', data);
  }

  Future<List<Map<String, dynamic>>> getOverScoresForInning(
      int inningId) async {
    final db = await database;
    return db.query(
      'over_scores',
      where: 'inning_id = ?',
      whereArgs: [inningId],
      orderBy: 'over_number ASC',
    );
  }
}
