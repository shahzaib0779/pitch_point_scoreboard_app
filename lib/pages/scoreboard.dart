import 'package:flutter/material.dart';
import 'package:pitch_point/Providers/scoreboard_provider.dart';
import 'package:pitch_point/pages/congratulations.dart';
import 'package:pitch_point/util/bat_ball_class.dart';
import 'package:pitch_point/widgets/score_button.dart';
import 'package:provider/provider.dart';

class Scoreboard extends StatefulWidget {
  const Scoreboard({super.key});

  @override
  State<Scoreboard> createState() => _ScoreboardState();
}

class _ScoreboardState extends State<Scoreboard> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAddBatsmen(context);
    });
  }

  Future<void> _checkAndAddBatsmen(BuildContext context) async {
  final scoreProvider = Provider.of<ScoreboardProvider>(context, listen: false);

  if (scoreProvider.striker.isEmpty) {
    final strikerName = await _showBatsmanDialog(context, "Enter Striker Name",TextInputType.name);
    if (strikerName != null && strikerName.isNotEmpty) {
      scoreProvider.setStriker(strikerName);
      scoreProvider.activeInning.addBatsman(Batting(playerName: strikerName));
    }
  }

  if (scoreProvider.nonStriker.isEmpty) {
    final nonStrikerName = await _showBatsmanDialog(context, "Enter Non-Striker Name",TextInputType.name);
    if (nonStrikerName != null && nonStrikerName.isNotEmpty) {
      scoreProvider.setNonStriker(nonStrikerName);
      scoreProvider.activeInning.addBatsman(Batting(playerName: nonStrikerName));
    }
  }

  if (scoreProvider.currentBowler.isEmpty) {
    final currentBowler = await _showBatsmanDialog(context, "Enter Bowler Name",TextInputType.name);
    if (currentBowler != null && currentBowler.isNotEmpty) {
      scoreProvider.setBowler(currentBowler);
      scoreProvider.activeInning.addBowler(Bowling(playerName: currentBowler));
    }
  }

  if (scoreProvider.activeInning.totalOvers == 0) {
    final oversString = await _showBatsmanDialog(context, "Enter Total Overs",TextInputType.number);
    final overs = int.tryParse(oversString ?? '');
    if (overs != null) {
      scoreProvider.inningOvers(overs);
    }
  }

  if(scoreProvider.activeInning.inningWickets==0){
    final wicketString=await _showBatsmanDialog(context, 'Total Inning Wickets',TextInputType.number);
    final wickets =int.tryParse(wicketString ?? '');
    if(wickets!=null){
      scoreProvider.inningWickets(wickets);
    }
  }
}

  Future<String?> _showBatsmanDialog(BuildContext context, String title,TextInputType keyboardType) async {
    String name = "";
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          titleTextStyle: TextStyle(fontFamily: 'Montserrat',color: Colors.black,fontSize: 17,fontWeight: FontWeight.w600),
          content: TextField(
            keyboardType: keyboardType,
            onChanged: (value) => name = value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
            decoration: InputDecoration(
              labelText: 'Type Here',
              labelStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(178, 0, 0, 0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, name),
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBatsmanRow(String name, ScoreboardProvider scoreProvider) {
    final list = scoreProvider.activeInning.battingList;
    if (name.isEmpty || list.isEmpty || !list.any((b) => b.playerName == name)) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name.isEmpty ? "-" : name),
          const Text("0 (0)"),
        ],
      );
    }
    final batsman = list.firstWhere((b) => b.playerName == name);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        scoreProvider.striker==batsman.playerName?
        Text(
            "$name🏏",
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: scoreProvider.activeInning.battingList.isNotEmpty && batsman.bowled ? Colors.grey:Colors.black
              ),
        ): Text(
            name,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
        ),
        Text("${batsman.runs} (${batsman.balls})",
            style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBowlerRow(String name, ScoreboardProvider scoreProvider) {
    final list = scoreProvider.activeInning.bowlersList;
    if (name.isEmpty || list.isEmpty || !list.any((b) => b.playerName == name)) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name.isEmpty ? "-" : name),
          const Text("0-0 (0)"),
        ],
      );
    }
    final bowler = list.firstWhere((b) => b.playerName == name);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$name ⚾",
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
        ),
        Text("${bowler.wickets}-${bowler.runsConceded} (${bowler.overs}.${scoreProvider.getCurrentBowls() == 6 ? 0 : scoreProvider.getCurrentBowls()})",
            style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreboardProvider>(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scoreProvider.isInningCompleted()) {
      checkInning(scoreProvider, context);
    }
  });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Inning ${scoreProvider.currentInning}",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    spacing: 3,
                    children: [
                      Text(
                        "ScoreBoard",
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${scoreProvider.activeInning.totalScore}/${scoreProvider.activeInning.totalWickets}",
                        style: Theme.of(context).textTheme.displaySmall!.copyWith(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      Text(
                        "Run Rate: ${scoreProvider.activeInning.oversBowled < 1 ? scoreProvider.activeInning.totalScore.toDouble() : (scoreProvider.activeInning.totalScore / (scoreProvider.activeInning.oversBowled +(scoreProvider.getCurrentBowls()/10))).toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
                      ),
                      scoreProvider.currentInning==2? SizedBox(height: 10,):Text(''),
                      scoreProvider.currentInning==2 &&scoreProvider.currentBowler.isNotEmpty&&scoreProvider.activeInning.totalOvers!=0?Text('${scoreProvider.activeInning.battingTeamName} needs ${(scoreProvider.inning1.totalScore+1)-scoreProvider.activeInning.totalScore} in ${(scoreProvider.activeInning.totalOvers*6 -((scoreProvider.activeInning.oversBowled*6)+(scoreProvider.getCurrentBowls()==6? 0:scoreProvider.getCurrentBowls()) ))}',style: TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w600),):Text(''),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    spacing: 10,
                    children: [
                      _buildBatsmanRow(scoreProvider.striker, scoreProvider),
                      _buildBatsmanRow(scoreProvider.nonStriker, scoreProvider),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(
                        "Total Overs",
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                           scoreProvider.currentBowler.isNotEmpty&&scoreProvider.activeInning.bowlersList.isNotEmpty? Text(
                         "${scoreProvider.activeInning.oversBowled}.${scoreProvider.getCurrentBowls() == 6 ? 0 : scoreProvider.getCurrentBowls()}/${scoreProvider.totalOvers}.0",
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ):Text('0/0'),
        
                        ],
                      )
        
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: _buildBowlerRow(scoreProvider.currentBowler, scoreProvider),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Score Panel",
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: ScoreButton(label: '1', onPressed: () async{
                            scoreProvider.updateBatsmanScore(scoreProvider.striker, 1, 1);
                            scoreProvider.rotateStrike();
                            scoreProvider.updateBowlerScore(scoreProvider.currentBowler, 1, 0);
                            if(scoreProvider.activeInning.totalOvers!=0 && scoreProvider.activeInning.oversBowled !=scoreProvider.activeInning.totalOvers){
                              await setNewBowler(scoreProvider, context);
                            }                    
                          })),
                          const SizedBox(width: 12),
                          Expanded(child: ScoreButton(label: '2', onPressed: ()async {
                             scoreProvider.updateBatsmanScore(scoreProvider.striker, 2, 1);
                             scoreProvider.updateBowlerScore(scoreProvider.currentBowler,2, 0);
                           if(scoreProvider.activeInning.totalOvers!=0 && scoreProvider.activeInning.oversBowled !=scoreProvider.activeInning.totalOvers){
                              await setNewBowler(scoreProvider, context);
                            }
                          })),
                          const SizedBox(width: 12),
                          Expanded(child: ScoreButton(label: '3', onPressed: () async {
                            scoreProvider.updateBatsmanScore(scoreProvider.striker, 3, 1);
                            scoreProvider.rotateStrike();
                            scoreProvider.updateBowlerScore(scoreProvider.currentBowler, 3, 0);
                           if(scoreProvider.activeInning.totalOvers!=0 && scoreProvider.activeInning.oversBowled !=scoreProvider.activeInning.totalOvers){
                              await setNewBowler(scoreProvider, context);
                            }
                          })),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: ScoreButton(label: '4', onPressed: () async {
                          scoreProvider.updateBatsmanScore(scoreProvider.striker, 4, 1);
                          scoreProvider.updateBowlerScore(scoreProvider.currentBowler, 4, 0);
                            if(scoreProvider.activeInning.totalOvers!=0 && scoreProvider.activeInning.oversBowled !=scoreProvider.activeInning.totalOvers){
                              await setNewBowler(scoreProvider, context);
                            }
        
                          })),
                          const SizedBox(width: 12),
                          Expanded(child: ScoreButton(label: '6', onPressed: () async {
                          scoreProvider.updateBatsmanScore(scoreProvider.striker, 6, 1);
                          scoreProvider.updateBowlerScore(scoreProvider.currentBowler, 6, 0);
                           if(scoreProvider.activeInning.totalOvers!=0 && scoreProvider.activeInning.oversBowled !=scoreProvider.activeInning.totalOvers){
                              await setNewBowler(scoreProvider, context);
                            }
        
                          })),
                          const SizedBox(width: 12),
                          Expanded(child: ScoreButton(label: 'Wd', onPressed: () {
                           scoreProvider.updateWideOrNoBall();
        
                          })),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: ScoreButton(label: 'W', onPressed: () async{
                          scoreProvider.updateBowlerScore(scoreProvider.currentBowler, 0, 1);
                          if(scoreProvider.striker.isNotEmpty && scoreProvider.activeInning.battingList.isNotEmpty && scoreProvider.activeInning.inningWickets!=0 &&scoreProvider.activeInning.inningWickets!=scoreProvider.activeInning.totalWickets){
                            scoreProvider.batsmanOut();
                            final newBatsman =await _showBatsmanDialog(context, 'Add New Batsman',TextInputType.name);
                            if(newBatsman!=null){
                              scoreProvider.setStriker(newBatsman);
                              scoreProvider.activeInning.addBatsman(Batting(playerName: newBatsman));
                            }
                          }
                             if(scoreProvider.activeInning.totalOvers!=0 && scoreProvider.activeInning.oversBowled !=scoreProvider.activeInning.totalOvers){
                              await setNewBowler(scoreProvider, context);
                            }
                          })),
                          const SizedBox(width: 12),
                          Expanded(child: ScoreButton(label: 'Nb', onPressed: () {
                           scoreProvider.updateWideOrNoBall();
                          })),
                          const SizedBox(width: 12),
                          Expanded(child: ScoreButton(label: 'Dot', onPressed: () async {
                            scoreProvider.updateBowlerScore(scoreProvider.currentBowler, 0, 0);
                            if(scoreProvider.activeInning.totalOvers!=0 && scoreProvider.activeInning.oversBowled !=scoreProvider.activeInning.totalOvers){
                              await setNewBowler(scoreProvider, context);
                            }
                          })),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }

  Future<void> setNewBowler(ScoreboardProvider scoreProvider, BuildContext context) async {
    if(scoreProvider.activeInning.bowlersList.isNotEmpty){
      final bowler = scoreProvider.activeInning.bowlersList.firstWhere((b) => b.playerName == scoreProvider.currentBowler);
      if(scoreProvider.getCurrentBowls()==6){
       bowler.balls=0;
    final newBowler = await _showBatsmanDialog(context, 'Add New Bowler',TextInputType.name);
    if(newBowler!=null){
      scoreProvider.setBowler(newBowler);
      scoreProvider.activeInning.addBowler(Bowling(playerName: newBowler));
      scoreProvider.rotateStrike();
    }
     }
    }
  }

 Future<void> checkInning(
    ScoreboardProvider scoreProvider, BuildContext context) async {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Inning Completed",
            style: TextStyle(fontFamily: 'Montserrat')),
        content: scoreProvider.currentInning == 1
            ? Text(
           '${scoreProvider.activeInning.battingTeamName} has scored '
           '${scoreProvider.activeInning.totalScore} runs in '
           '${scoreProvider.activeInning.oversBowled}.${scoreProvider.getCurrentBowls() == 6 ? 0 : scoreProvider.getCurrentBowls()} overs.',
                style: const TextStyle(fontFamily: 'Montserrat'),
              )
            : Text(
                scoreProvider.activeInning.totalScore >
                        scoreProvider.inning1.totalScore
                    ? '${scoreProvider.activeInning.battingTeamName} has won the match!'
                    : '${scoreProvider.inning1.battingTeamName} has won the match',
                style: const TextStyle(
                    fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
              ),
        actions: [
          scoreProvider.currentInning == 1
              ? TextButton(
                  onPressed: () {
                    scoreProvider.switchInning();
                    Navigator.pop(dialogContext); // close dialog
                    Future.microtask(() {
                      if (mounted) {
                        // use parent context from State, not dialogContext
                        _checkAndAddBatsmen(this.context); 
                      }
                    });
                  },
                  child: const Text(
                    "Start Next Inning",
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                )
              : TextButton(
                  onPressed: () {
                    if( scoreProvider.activeInning.totalScore >
                        scoreProvider.inning1.totalScore){
                   Navigator.push(context, MaterialPageRoute(builder: (context)=>CongratulationsPage(teamName: scoreProvider.activeInning.battingTeamName)));
                    }
                    else{
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>CongratulationsPage(teamName: scoreProvider.inning1.battingTeamName)));

                    }
                  },
                  child: const Text(
                    "Completed",
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                ),
        ],
      );
    },
  );
}


}
