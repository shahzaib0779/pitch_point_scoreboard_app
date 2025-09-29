import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pitch_point/Providers/scoreboard_provider.dart';
import 'package:pitch_point/Providers/team_names_provider.dart';
import 'package:pitch_point/pages/scoreboard.dart';
import 'package:provider/provider.dart';

class TossScreen extends StatefulWidget {
  const TossScreen({super.key});

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen> {
  String result = "Tap to Toss";

 void tossCoin(bool teamValue) {
  setState(() {
    result = "Tossing the Coin...";
  });

  final random = Random();
  final toss = random.nextBool(); // true = heads, false = tails

  Future.delayed(const Duration(seconds: 3), () {
    setState(() {
      result = toss ? "Heads" : "Tails";
    });

    if(!context.mounted){
      return;
    }

    if (toss == teamValue) {
      Provider.of<TeamNamesProvider>(context, listen: false).setTeam1Toss(true);
      Provider.of<TeamNamesProvider>(context,listen: false).setIsToss(true);


    } else {
      Provider.of<TeamNamesProvider>(context, listen: false).setTeam2Toss(true);
      Provider.of<TeamNamesProvider>(context,listen: false).setIsToss(true);

    }
  });
}


  @override
  Widget build(BuildContext context) {

    final provider = Provider.of<TeamNamesProvider>(context,listen: false);
    final teamNames =Provider.of<ScoreboardProvider>(context,listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Coin Toss",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
               Text(
                  "Time to\n flip fate!🎲",
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 100,),
              Text(
                result,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3,),
             provider.team1Toss ==provider.team2Toss? Text("${provider.team1} is making the call",
              style: TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w500),):Text(""),

              const SizedBox(height: 20),
              provider.team1Toss ==provider.team2Toss? 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:!provider.isTossDone? Theme.of(context).colorScheme.primary:Colors.grey,
                      padding:
                          const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    ),
                    onPressed:!provider.isTossDone?() {
                      tossCoin(true);
                    }:null,
                    child: Text(
                      "Heads",
                      style: TextStyle(
                        color:Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:!provider.isTossDone? Theme.of(context).colorScheme.primary:Colors.grey,

                      padding:
                          const EdgeInsets.symmetric(vertical: 10, horizontal: 27),
                    ),
                    onPressed:!provider.isTossDone?() {
                      tossCoin(false);
                    }:null,
                    child: Text(
                      "Tails",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ],
              ):Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.team1Toss? "${provider.team1} has won the toss":"${provider.team2} has won the toss",
                  style: TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w500,),),
                  SizedBox(height: 2,),
                  Text('Choose to:',style: TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w500,)),
                   SizedBox(height: 8,),
                   Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                    backgroundColor:Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    ),
                    onPressed:() {
                      if(provider.team1Toss==true){
                        teamNames.inning1.battingTeamName=provider.team1;
                        teamNames.inning1.bowlingTeamName=provider.team2;

                         teamNames.inning2.battingTeamName=provider.team2;
                        teamNames.inning2.bowlingTeamName=provider.team1;
                      }else{
                         teamNames.inning1.battingTeamName=provider.team2;
                         teamNames.inning1.bowlingTeamName=provider.team1;

                         teamNames.inning2.battingTeamName=provider.team1;
                         teamNames.inning2.bowlingTeamName=provider.team2;
                      }
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>Scoreboard()),(route)=>false);
                    },
                    child: Text(
                      "Bat",
                      style: TextStyle(
                        color:Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:Theme.of(context).colorScheme.primary,
                    ),
                    onPressed:() {
                      if(provider.team1Toss==true){
                        teamNames.inning1.battingTeamName=provider.team2;
                        teamNames.inning1.bowlingTeamName=provider.team1;

                        teamNames.inning2.battingTeamName=provider.team1;
                        teamNames.inning2.bowlingTeamName=provider.team2;

                        
                      }
                      else{
                         teamNames.inning1.battingTeamName=provider.team1;
                        teamNames.inning1.bowlingTeamName=provider.team2;

                        teamNames.inning2.battingTeamName=provider.team2;
                        teamNames.inning2.bowlingTeamName=provider.team1;
                      }

                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>Scoreboard()),(route)=>false);

                    },
                    child: Text(
                      "Bowl",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ],
              ),

                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
