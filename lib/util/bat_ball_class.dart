class Batting {
  String playerName;
  int runs;
  int balls;
  int fours;
  int sixes;
  bool bowled;

  Batting({
    required this.playerName,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.bowled =false
  });
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

