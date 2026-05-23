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
        title: const Text('New Match'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),

              // ── Heading ──
              const Text(
                'Let the Battle\nBegin!⚔',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Montserrat',
                  color: Color(0xFFD32F2F),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Enter both team names to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9E9E),
                ),
              ),

              const SizedBox(height: 40),

              // ── Team 1 ──
              _TeamInputCard(
                teamNumber: 1,
                controller: team1Controller,
                onChanged: (v) {
                  teamProvider.setTeam1(v);
                  teamProvider.setEnabled(
                    v.trim().isNotEmpty &&
                        team2Controller.text.trim().isNotEmpty,
                  );
                },
              ),

              const SizedBox(height: 16),

              // ── VS divider ──
              Row(
                children: [
                  const Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(thickness: 1)),
                ],
              ),

              const SizedBox(height: 16),

              // ── Team 2 ──
              _TeamInputCard(
                teamNumber: 2,
                controller: team2Controller,
                onChanged: (v) {
                  teamProvider.setTeam2(v);
                  teamProvider.setEnabled(
                    v.trim().isNotEmpty &&
                        team1Controller.text.trim().isNotEmpty,
                  );
                },
              ),

              const SizedBox(height: 40),

              // ── Next button ──
              AnimatedOpacity(
                opacity: teamProvider.isEnabled ? 1.0 : 0.45,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: teamProvider.isEnabled
                      ? () {
                          teamProvider
                              .setTeam1(team1Controller.text.trim());
                          teamProvider
                              .setTeam2(team2Controller.text.trim());
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TossScreen()),
                          );
                        }
                      : null,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Proceed to Toss',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Team input card ───────────────────────────────────────────────────────────

class _TeamInputCard extends StatelessWidget {
  final int teamNumber;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _TeamInputCard({
    required this.teamNumber,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$teamNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Team $teamNumber',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TeamNamesFields(
            labelName: 'Enter team name',
            controller: controller,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
