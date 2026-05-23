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

class _TossScreenState extends State<TossScreen>
    with SingleTickerProviderStateMixin {
  String _result = '';
  bool _tossing = false;

  late AnimationController _coinController;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _spinAnimation = Tween<double>(begin: 0, end: 2 * pi * 4).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  void _tossCoin(bool pickedHeads) async {
    if (_tossing) return;
    setState(() {
      _tossing = true;
      _result = '';
    });

    await _coinController.forward(from: 0);

    final isHeads = Random().nextBool();

    if (!mounted) return;

    final provider =
        Provider.of<TeamNamesProvider>(context, listen: false);

    if (isHeads == pickedHeads) {
      provider.setTeam1Toss(true);
    } else {
      provider.setTeam2Toss(true);
    }
    provider.setIsToss(true);

    setState(() {
      _result = isHeads ? 'Heads 🟡' : 'Tails 🔵';
      _tossing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeamNamesProvider>(context);
    final scoreProvider =
        Provider.of<ScoreboardProvider>(context, listen: false);

    final tossDone = provider.isTossDone;
    final team1Won = provider.team1Toss;
    final winnerName = team1Won ? provider.team1 : provider.team2;

    return Scaffold(
      appBar: AppBar(title: const Text('Coin Toss')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),

              // ── Heading ──
              const Text(
                'Time to\nFlip Fate! 🎲',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Montserrat',
                  color: Color(0xFFD32F2F),
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${provider.team1}  is making the call',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9E9E9E),
                ),
              ),

              const SizedBox(height: 44),

              // ── Coin visual ──
              Center(
                child: AnimatedBuilder(
                  animation: _spinAnimation,
                  builder: (_, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateY(_spinAnimation.value),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFF9A825)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF9A825).withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🏏',
                        style: TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── State: before toss ──
              if (!tossDone) ...[
                const Text(
                  'Choose your call',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _TossChoiceButton(
                        label: 'Heads',
                        emoji: '🟡',
                        loading: _tossing,
                        onTap: () => _tossCoin(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TossChoiceButton(
                        label: 'Tails',
                        emoji: '🔵',
                        loading: _tossing,
                        onTap: () => _tossCoin(false),
                      ),
                    ),
                  ],
                ),
                if (_result.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Result: $_result',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                ],
              ],

              // ── State: after toss ──
              if (tossDone) ...[
                // Result banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _result,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$winnerName won the toss!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Choose to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF424242),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _DecisionButton(
                        label: 'Bat First',
                        icon: Icons.sports_cricket_rounded,
                        onTap: () {
                          if (team1Won) {
                            scoreProvider.inning1.battingTeamName =
                                provider.team1;
                            scoreProvider.inning1.bowlingTeamName =
                                provider.team2;
                            scoreProvider.inning2.battingTeamName =
                                provider.team2;
                            scoreProvider.inning2.bowlingTeamName =
                                provider.team1;
                          } else {
                            scoreProvider.inning1.battingTeamName =
                                provider.team2;
                            scoreProvider.inning1.bowlingTeamName =
                                provider.team1;
                            scoreProvider.inning2.battingTeamName =
                                provider.team1;
                            scoreProvider.inning2.bowlingTeamName =
                                provider.team2;
                          }
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const Scoreboard()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DecisionButton(
                        label: 'Bowl First',
                        icon: Icons.sports_baseball_rounded,
                        onTap: () {
                          if (team1Won) {
                            scoreProvider.inning1.battingTeamName =
                                provider.team2;
                            scoreProvider.inning1.bowlingTeamName =
                                provider.team1;
                            scoreProvider.inning2.battingTeamName =
                                provider.team1;
                            scoreProvider.inning2.bowlingTeamName =
                                provider.team2;
                          } else {
                            scoreProvider.inning1.battingTeamName =
                                provider.team1;
                            scoreProvider.inning1.bowlingTeamName =
                                provider.team2;
                            scoreProvider.inning2.battingTeamName =
                                provider.team2;
                            scoreProvider.inning2.bowlingTeamName =
                                provider.team1;
                          }
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const Scoreboard()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toss choice button ────────────────────────────────────────────────────────

class _TossChoiceButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool loading;
  final VoidCallback onTap;

  const _TossChoiceButton({
    required this.label,
    required this.emoji,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: loading ? Colors.grey.shade300 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: loading
                  ? Colors.grey.shade300
                  : const Color(0xFFD32F2F),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Bat / Bowl decision button ────────────────────────────────────────────────

class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
