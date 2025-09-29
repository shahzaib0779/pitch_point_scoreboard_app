import 'package:flutter/material.dart';
import 'package:pitch_point/util/inning.dart';
class ScoreboardProvider extends ChangeNotifier{

  Inning inning1=Inning();
  Inning inning2=Inning();

  int currentInning=1;
  String striker='';
  String nonStriker='';
  String currentBowler='';

 
  Inning get activeInning =>
      currentInning == 1 ? inning1 : inning2;


  int get totalOvers =>activeInning.totalOvers;

  void setStriker(String name){
    striker =name;
    notifyListeners();
  }

  void setBowler(String name){
    currentBowler=name;
    notifyListeners();
  }

  void setNonStriker(String name){
    nonStriker =name;
    notifyListeners();
  }

  void switchInning()
  {
    currentInning =2;
    currentBowler='';
    striker='';
    nonStriker='';
    notifyListeners();
  }

  void rotateStrike(){
    final temp=striker;
    striker=nonStriker;
    nonStriker=temp;
    notifyListeners();
  }

  void updateBatsmanScore(String name,int runs,int balls)
  {
    final batsman = activeInning.battingList.firstWhere((b)=> b.playerName ==name);
    batsman.runs +=runs;
    batsman.balls+=balls;
    if(runs ==4)
    {
      batsman.fours++;
    }
    if(runs ==6)
    {
      batsman.sixes++;
    }
    activeInning.currentRunrate =activeInning.totalScore/activeInning.oversBowled;
    notifyListeners();

  }

  void updateBowlerScore(String name, int runs, int wickets) {
  final bowler = activeInning.bowlersList.firstWhere((b) => b.playerName == name);

  bowler.runsConceded += runs;
  bowler.wickets += wickets;

  // Count one legal ball
  bowler.balls++;
  if (bowler.balls == 6) {
    bowler.overs++;
    activeInning.oversBowled++; // team overs also increase
    
  }

  activeInning.totalScore += runs;
  activeInning.totalWickets += wickets;

  notifyListeners();
}

void updateWideOrNoBall(){
   final bowler = activeInning.bowlersList.firstWhere((b) => b.playerName == currentBowler);

  bowler.runsConceded += 1;

  if (bowler.balls == 6) {
    bowler.overs++;
    activeInning.oversBowled++; // team overs also increase
  }

  activeInning.totalScore += 1;
  notifyListeners();

}


  void inningOvers(int overs){
    activeInning.totalOvers=overs;
    inning2.totalOvers=overs;
    notifyListeners();

  }

  void updateCurrentBowls(String name){
      final bowler = activeInning.bowlersList.firstWhere((b) => b.playerName == name);
      bowler.balls = 0;
      notifyListeners();

  }

  void dotBall(){
    final batsman = activeInning.battingList.firstWhere((b)=> b.playerName ==striker);
    final bowler = activeInning.bowlersList.firstWhere((b) => b.playerName == currentBowler);

    batsman.balls++;
    bowler.balls++;
    notifyListeners();

  }

  int getCurrentBowls(){
      final bowler = activeInning.bowlersList.firstWhere((b)=> b.playerName ==currentBowler);
      return bowler.balls;


  }

  void inningWickets(int wickets){
    activeInning.inningWickets=wickets;
    inning2.inningWickets=wickets;
    notifyListeners();
  }

  void batsmanOut(){
    final batsman = activeInning.battingList.firstWhere((b)=> b.playerName ==striker);
    batsman.bowled=true;
    notifyListeners();

  }

 bool isInningCompleted() {
  // Inning must have started
  if (activeInning.totalOvers == 0||activeInning.inningWickets==0) {
    return false;
  }

  if (currentInning == 1) {
    if (activeInning.totalWickets == activeInning.inningWickets) return true;

    if (activeInning.oversBowled >= activeInning.totalOvers) return true;
  }

  if (currentInning == 2) {
    if (activeInning.totalWickets == activeInning.inningWickets) return true;

    if (activeInning.oversBowled >= activeInning.totalOvers) return true;

    if (activeInning.totalScore > inning1.totalScore) return true;
  }

  return false;
}


}