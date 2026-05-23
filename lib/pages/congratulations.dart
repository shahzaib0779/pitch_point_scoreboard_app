import 'package:flutter/material.dart';
import 'package:pitch_point/pages/main_page.dart';

class CongratulationsPage extends StatefulWidget {
  final String winnerName;
  final String resultLine;
  final String team1Name;
  final String team1Score;
  final String team2Name;
  final String team2Score;

  const CongratulationsPage({
    super.key,
    required this.winnerName,
    required this.resultLine,
    required this.team1Name,
    required this.team1Score,
    required this.team2Name,
    required this.team2Score,
  });

  @override
  State<CongratulationsPage> createState() => _CongratulationsPageState();
}

class _CongratulationsPageState extends State<CongratulationsPage>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _trophyController;

  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<double> _trophyBounce;
  late Animation<double> _detailsFade;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardScale = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _cardController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _trophyBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _trophyController, curve: Curves.elasticOut),
    );
    _detailsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _trophyController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _cardController.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _trophyController.forward();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  bool get _isTie => widget.winnerName == 'Nobody';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 24),
              child: FadeTransition(
                opacity: _cardFade,
                child: ScaleTransition(
                  scale: _cardScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Trophy ──────────────────────────────────
                      ScaleTransition(
                        scale: _trophyBounce,
                        child: Text(
                          _isTie ? '🤝' : '🏆',
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Main result card ─────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: _isTie
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF1565C0),
                                    Color(0xFF0D47A1)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFD32F2F),
                                    Color(0xFF7F0000)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (_isTie
                                      ? const Color(0xFF1565C0)
                                      : const Color(0xFFD32F2F))
                                  .withValues(alpha: 0.45),
                              blurRadius: 28,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isTie
                                  ? 'It\'s a Tie!'
                                  : 'Congratulations!',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!_isTie) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.winnerName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _detailsFade,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(30),
                                ),
                                child: Text(
                                  widget.resultLine,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Scorecard summary ────────────────────────
                      FadeTransition(
                        opacity: _detailsFade,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white12, width: 1),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'MATCH SUMMARY',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: Color(0xFF9E9E9E),
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _scoreLine(
                                  widget.team1Name, widget.team1Score),
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                    color: Colors.white12, height: 1),
                              ),
                              _scoreLine(
                                  widget.team2Name, widget.team2Score),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Home button ──────────────────────────────
                      FadeTransition(
                        opacity: _detailsFade,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const MainPage()),
                                (route) => false,
                              );
                            },
                            icon: const Icon(Icons.home_rounded,
                                color: Colors.white),
                            label: const Text(
                              'Back to Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreLine(String team, String score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            team.isEmpty ? '—' : team,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          score,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFFD32F2F),
          ),
        ),
      ],
    );
  }
}
