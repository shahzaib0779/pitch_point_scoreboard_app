// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pitch_point/Providers/team_names_provider.dart';
import 'package:pitch_point/pages/toss_page.dart';
import 'package:pitch_point/widgets/TeamNameField.dart';
import 'package:provider/provider.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  late TextEditingController team1Controller;
  late TextEditingController team2Controller;

  @override
  void initState() {
    super.initState();
    team1Controller = TextEditingController();
    team2Controller = TextEditingController();
  }

  @override
  void dispose() {
    team1Controller.dispose();
    team2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamNamesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enter Teams',
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
                "Let the battle\n begin! ⚔️🔥",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Team 1 input
              TeamNamesFields(
                labelName: 'Enter Team 1',
                controller: team1Controller,
                onChanged: (value) {
                  teamProvider.setTeam1(value);
                  teamProvider.setEnabled(
                    value.isNotEmpty && team2Controller.text.isNotEmpty,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Team 2 input
              TeamNamesFields(
                labelName: 'Enter Team 2',
                controller: team2Controller,
                onChanged: (value) {
                  teamProvider.setTeam2(value);
                  teamProvider.setEnabled(
                    value.isNotEmpty && team1Controller.text.isNotEmpty,
                  );
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: teamProvider.isEnabled
                    ? () {
                        teamProvider.setTeam1(team1Controller.text);
                        teamProvider.setTeam2(team2Controller.text);
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>TossScreen()));
                      }
                    : null,
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.hovered)) {
                      return teamProvider.isEnabled
                          ? const Color.fromARGB(255, 155, 15, 5)
                          : Colors.grey;
                    }
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.black;
                    }
                    return teamProvider.isEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey;
                  }),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  ),
                  elevation: MaterialStateProperty.all(4),
                  shape: MaterialStateProperty.all(
                    const StadiumBorder(
                      side: BorderSide(width: 1.5, color: Colors.black26),
                    ),
                  ),
                ),
                child: Text(
                  "Next",
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
        ),
      ),
    );
  }
}
