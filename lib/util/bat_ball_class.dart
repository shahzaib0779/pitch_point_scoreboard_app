class Batting {
  String playerName;
  int runs;
  int balls;
  int fours;
  int sixes;
  bool bowled;
  bool retiredHurt;

  Batting({
    required this.playerName,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.bowled = false,
    this.retiredHurt = false,
  });

  /// True when the batter is no longer at the crease for any reason.
  bool get isGone => bowled || retiredHurt;
}

class Bowling {
  String playerName;
  int runsConceded;
  int wickets;
  int overs;
  int balls;

  Bowling({
    required this.playerName,
    this.runsConceded = 0,
    this.wickets = 0,
    this.overs = 0,
    this.balls = 0,
  });
}
