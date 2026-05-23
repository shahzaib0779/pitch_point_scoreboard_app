import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pitch_point/Providers/scoreboard_provider.dart';
import 'package:pitch_point/Providers/team_names_provider.dart';
import 'package:pitch_point/models/match_models.dart';
import 'package:pitch_point/pages/Teams_Page.dart';
import 'package:pitch_point/pages/match_history_page.dart';
import 'package:pitch_point/pages/scoreboard.dart';
import 'package:pitch_point/services/match_service.dart';
import 'package:pitch_point/util/footer.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<MatchRecord?> _incompleteFuture;

  @override
  void initState() {
    super.initState();
    _incompleteFuture = MatchService.instance.getIncompleteMatch();
  }

  Future<void> _resumeMatch(MatchRecord match) async {
    final sp = context.read<ScoreboardProvider>();
    final ok = await MatchService.instance.resumeMatch(match.id!, sp);
    if (!mounted) { return; }
    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Scoreboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resume match.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // ── Header ──────────────────────────────
              const _Header(),

              const SizedBox(height: 28),

              // ── Resume card (if incomplete match exists) ─────────────
              FutureBuilder<MatchRecord?>(
                future: _incompleteFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  final match = snap.data;
                  if (match == null) { return const SizedBox.shrink(); }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ResumeCard(
                      match: match,
                      onResume: () => _resumeMatch(match),
                    ),
                  );
                },
              ),

              // ── Menu cards ──────────────────────────
              _MenuCard(
                icon: Icons.sports_cricket_rounded,
                label: 'Start New Match',
                subtitle: 'Set up teams and begin',
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFF8B0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  // Reset any previous match state
                  context.read<ScoreboardProvider>().resetMatch();
                  context.read<TeamNamesProvider>().resetTeams();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TeamsPage()),
                  );
                },
              ),

              const SizedBox(height: 16),

              _MenuCard(
                icon: Icons.bar_chart_rounded,
                label: 'Match History',
                subtitle: 'View previous stats',
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MatchHistoryPage()),
                  );
                },
              ),

              const SizedBox(height: 16),

              _MenuCard(
                icon: Icons.exit_to_app_rounded,
                label: 'Exit',
                subtitle: 'Close the application',
                gradient: const LinearGradient(
                  colors: [Color(0xFF424242), Color(0xFF212121)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => SystemNavigator.pop(),
              ),

              const SizedBox(height: 48),
              const FooterText(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Resume card ───────────────────────────────────────────────────────────────

class _ResumeCard extends StatelessWidget {
  final MatchRecord match;
  final VoidCallback onResume;

  const _ResumeCard({required this.match, required this.onResume});

  @override
  Widget build(BuildContext context) {
    final inning1 = match.inning1;
    final currentInningLabel =
        match.currentInning == 1 ? 'Inning 1' : 'Inning 2';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.play_circle_outline_rounded,
                color: Color(0xFFE65100), size: 24),
          ),

          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resume Match',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.matchTitle}  •  $currentInningLabel',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
                if (inning1 != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${inning1.battingTeam}: ${inning1.scoreDisplay}  (${inning1.oversDisplay} ov)',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Resume button
          ElevatedButton(
            onPressed: onResume,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Resume',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header widget ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.28),
                blurRadius: 22,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/Logo.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 18),

        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Pitch ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Montserrat',
                  color: Color(0xFFD32F2F),
                ),
              ),
              TextSpan(
                text: 'Point',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Montserrat',
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Where Every Run Counts! 🏏',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }
}

// ── Menu card widget ─────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 20, horizontal: 22),
            child: Row(
              children: [
                // Icon bubble
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),

                const SizedBox(width: 18),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white54,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
