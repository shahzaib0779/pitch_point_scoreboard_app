import 'package:flutter/material.dart';

class TeamNamesProvider extends ChangeNotifier {
  String _team1 = '';
  String _team2 = '';
  bool _isTossDone =false;
  bool _team1Toss =false;
  bool _team2Toss = false;
  bool _isEnabled = false;

  String get team1 => _team1;
  String get team2 => _team2;
  bool get isEnabled => _isEnabled;
  bool get team1Toss =>_team1Toss;
  bool get team2Toss =>_team2Toss;
  bool get isTossDone => _isTossDone;

  void setTeam1(String name) {
    _team1 = name;
    notifyListeners();
  }

  void setEnabled(bool value)
  {
    _isEnabled = value;
    notifyListeners();
  }

  void setIsToss(bool value)
  {
    _isTossDone=value;
    notifyListeners();
  }

  void setTeam2(String name) {
    _team2 = name;
    notifyListeners();
  }

  void setTeam1Toss(bool value){
    _team1Toss =value;
  }
  void setTeam2Toss(bool value){
    _team2Toss =value;
  }

}
