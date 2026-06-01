import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:pitch_point/models/match_models.dart';

// Full cricket scorecard — batting + bowling tables for each inning.

class MatchDetailsPage extends StatelessWidget {
  final MatchRecord match;

  const MatchDetailsPage({super.key, required this.match});

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inning1 = match.inning1;
    final inning2 = match.inning2;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(title: Text(match.matchTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MatchHeaderCard(match: match, formatDate: _formatDate),
            const SizedBox(height: 14),

            // ── Scoring comparison chart ──────────────────────────────────
            if (inning1 != null && inning1.overScores.isNotEmpty) ...[
              _ScoringComparisonChart(
                inning1: inning1,
                inning2: inning2,
                totalOvers: match.totalOvers,
              ),
              const SizedBox(height: 14),
            ],

            if (inning1 != null) ...[
              _InningScorecard(inning: inning1, inningLabel: 'Inning 1'),
              const SizedBox(height: 14),
            ],
            if (inning2 != null) ...[
              _InningScorecard(inning: inning2, inningLabel: 'Inning 2'),
              const SizedBox(height: 14),
            ],
            if (match.result.isNotEmpty) ...[
              _ResultBanner(result: match.result),
              const SizedBox(height: 12),
            ],
            if (match.manOfMatch.isNotEmpty) ...[
              _ManOfMatchCard(playerName: match.manOfMatch),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Match header card ─────────────────────────────────────────────────────────

class _MatchHeaderCard extends StatelessWidget {
  final MatchRecord match;
  final String Function(String) formatDate;

  const _MatchHeaderCard({required this.match, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.team1Name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFF7F0000)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.team2Name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                _MetaChip(
                    icon: Icons.emoji_events_rounded,
                    text: '${match.tossWinner} won · ${match.tossDecision}'),
                _MetaChip(
                    icon: Icons.sports_cricket_rounded,
                    text: '${match.totalOvers} Overs'),
                _MetaChip(
                    icon: Icons.calendar_today_rounded,
                    text: formatDate(match.createdAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inning scorecard ──────────────────────────────────────────────────────────

class _InningScorecard extends StatelessWidget {
  final InningRecord inning;
  final String inningLabel;

  const _InningScorecard({required this.inning, required this.inningLabel});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient header band ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          inningLabel.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            color: Colors.white70,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        inning.battingTeam.isEmpty ? 'Batting' : inning.battingTeam,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      inning.scoreDisplay,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${inning.oversDisplay} overs',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    if (inning.totalExtras > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Extras: ${inning.totalExtras}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inning.battingList.isNotEmpty) ...[
                  _sectionLabel('Batting'),
                  const SizedBox(height: 8),
                  _BattingTable(inning: inning),
                  const SizedBox(height: 14),
                ],
                if (inning.bowlingList.isNotEmpty) ...[
                  _sectionLabel('Bowling'),
                  const SizedBox(height: 8),
                  _BowlingTable(inning: inning),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: Color(0xFF1A237E),
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── Batting table ─────────────────────────────────────────────────────────────
// Column widths chosen to prevent SR ("125.0") from wrapping on small screens.

class _BattingTable extends StatelessWidget {
  final InningRecord inning;

  const _BattingTable({required this.inning});

  static const double _wR  = 30;
  static const double _wB  = 30;
  static const double _w4  = 28;
  static const double _w6  = 28;
  static const double _wSR = 42; // wide enough for "125.0"

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          _tableHeader(),
          // Batting rows
          ...inning.battingList.asMap().entries.map((e) => Container(
                color: e.key.isEven ? Colors.white : const Color(0xFFFAFAFA),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: _battingRow(e.value),
              )),
          // Extras
          if (inning.totalExtras > 0) _extrasRow(),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFECEFF1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'BATSMAN',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: Color(0xFF607D8B),
                letterSpacing: 0.8,
              ),
            ),
          ),
          _hCell('R',  _wR),
          _hCell('B',  _wB),
          _hCell('4s', _w4),
          _hCell('6s', _w6),
          _hCell('SR', _wSR),
        ],
      ),
    );
  }

  Widget _battingRow(BattingRecord b) {
    final nameColor = (b.isOut || b.isRetiredHurt)
        ? const Color(0xFF9E9E9E)
        : const Color(0xFF212121);

    final Color statusColor;
    final String statusText;
    if (b.isRetiredHurt) {
      statusColor = const Color(0xFF6A1B9A);
      statusText = 'retired hurt';
    } else if (b.isOut) {
      statusColor = const Color(0xFFB71C1C);
      statusText = 'out';
    } else {
      statusColor = const Color(0xFF2E7D32);
      statusText = 'not out ✦';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.playerName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: nameColor,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                  fontSize: 9,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        _dCell('${b.runs}', _wR,  bold: true, color: const Color(0xFF212121)),
        _dCell('${b.balls}', _wB),
        _dCell('${b.fours}', _w4),
        _dCell('${b.sixes}', _w6),
        _dCell(b.strikeRateStr, _wSR),
      ],
    );
  }

  Widget _extrasRow() {
    final parts = <String>[];
    if (inning.wides > 0)   parts.add('Wd ${inning.wides}');
    if (inning.noBalls > 0) parts.add('NB ${inning.noBalls}');
    if (inning.byes > 0)    parts.add('B ${inning.byes}');
    if (inning.legByes > 0) parts.add('LB ${inning.legByes}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(7),
          bottomRight: Radius.circular(7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extras',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF212121),
                  ),
                ),
                if (parts.isNotEmpty)
                  Text(
                    parts.join('  ·  '),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
              ],
            ),
          ),
          _dCell('${inning.totalExtras}', _wR,
              bold: true, color: const Color(0xFF212121)),
          _blankCell(_wB),
          _blankCell(_w4),
          _blankCell(_w6),
          _blankCell(_wSR),
        ],
      ),
    );
  }

  Widget _hCell(String text, double width) => SizedBox(
        width: width,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            color: Color(0xFF607D8B),
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _dCell(String text, double width,
      {bool bold = false, Color? color}) =>
      SizedBox(
        width: width,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
            color: color ?? const Color(0xFF424242),
          ),
        ),
      );

  Widget _blankCell(double width) => SizedBox(
        width: width,
        child: const Text(
          '—',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD)),
        ),
      );
}

// ── Bowling table ─────────────────────────────────────────────────────────────

class _BowlingTable extends StatelessWidget {
  final InningRecord inning;

  const _BowlingTable({required this.inning});

  static const double _wO    = 36;
  static const double _wR    = 34;
  static const double _wW    = 30;
  static const double _wEcon = 46;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFFECEFF1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'BOWLER',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: Color(0xFF607D8B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _hCell('O',    _wO),
                _hCell('R',    _wR),
                _hCell('W',    _wW),
                _hCell('Econ', _wEcon),
              ],
            ),
          ),
          // Rows
          ...inning.bowlingList.asMap().entries.map((e) {
            final b = e.value;
            final isLast = e.key == inning.bowlingList.length - 1;
            return Container(
              decoration: BoxDecoration(
                color: e.key.isEven ? Colors.white : const Color(0xFFFAFAFA),
                borderRadius: isLast
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(7),
                        bottomRight: Radius.circular(7),
                      )
                    : null,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      b.playerName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                  _dCell(b.oversStr, _wO),
                  _dCell('${b.runsConceded}', _wR),
                  SizedBox(
                    width: _wW,
                    child: Text(
                      '${b.wickets}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: b.wickets > 0
                            ? FontWeight.w800
                            : FontWeight.w500,
                        fontSize: 13,
                        color: b.wickets > 0
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF424242),
                      ),
                    ),
                  ),
                  _dCell(b.economyStr, _wEcon),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _hCell(String text, double width) => SizedBox(
        width: width,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            color: Color(0xFF607D8B),
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _dCell(String text, double width) => SizedBox(
        width: width,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Color(0xFF424242),
          ),
        ),
      );
}

// ── Result banner ─────────────────────────────────────────────────────────────

class _ResultBanner extends StatelessWidget {
  final String result;

  const _ResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFF7F0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              result,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scoring comparison chart ──────────────────────────────────────────────────

class _ScoringComparisonChart extends StatelessWidget {
  final InningRecord inning1;
  final InningRecord? inning2;
  final int totalOvers;

  const _ScoringComparisonChart({
    required this.inning1,
    required this.inning2,
    required this.totalOvers,
  });

  @override
  Widget build(BuildContext context) {
    final hasInning2 = inning2 != null && inning2!.overScores.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + legend ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SCORING COMPARISON',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  _LegendDot(
                    color: const Color(0xFF4FC3F7),
                    label: inning1.battingTeam,
                  ),
                  if (hasInning2) ...[
                    const SizedBox(width: 10),
                    _LegendDot(
                      color: const Color(0xFFEF5350),
                      label: inning2!.battingTeam,
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Chart canvas ──────────────────────────────────────────────
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScoringChartPainter(
                inning1Scores: inning1.overScores,
                inning2Scores: hasInning2 ? inning2!.overScores : const [],
                totalOvers: totalOvers > 0 ? totalOvers : inning1.oversBowled,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ── X-axis label ──────────────────────────────────────────────
          const Center(
            child: Text(
              'OVERS',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 9,
                color: Colors.white38,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Chart painter ─────────────────────────────────────────────────────────────

class _ScoringChartPainter extends CustomPainter {
  final List<OverScoreRecord> inning1Scores;
  final List<OverScoreRecord> inning2Scores;
  final int totalOvers;

  const _ScoringChartPainter({
    required this.inning1Scores,
    required this.inning2Scores,
    required this.totalOvers,
  });

  static const double _left   = 36.0;
  static const double _right  = 8.0;
  static const double _top    = 8.0;
  static const double _bottom = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalOvers == 0) return;

    final w = size.width  - _left - _right;
    final h = size.height - _top  - _bottom;

    // ── Max score for Y axis ──────────────────────────────────────────
    int maxScore = 30;
    for (final s in [...inning1Scores, ...inning2Scores]) {
      maxScore = max(maxScore, s.score);
    }
    // Round to next clean multiple
    final int yStep = maxScore <= 60 ? 10 : maxScore <= 150 ? 25 : maxScore <= 300 ? 50 : 100;
    maxScore = ((maxScore / yStep).ceil() * yStep).clamp(yStep, 9999);

    // ── Grid lines ────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    const gridRows = 4;
    for (int i = 0; i <= gridRows; i++) {
      final y = _top + h - (i / gridRows) * h;
      canvas.drawLine(Offset(_left, y), Offset(_left + w, y), gridPaint);
      _drawLabel(canvas, '${(i / gridRows * maxScore).round()}',
          Offset(_left - 4, y), TextAlign.right);
    }

    // ── Vertical grid lines (overs) ───────────────────────────────────
    final vGridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    final overStep = totalOvers <= 10 ? 2 : totalOvers <= 20 ? 5 : 10;
    for (int o = 1; o <= totalOvers; o += overStep) {
      final x = _left + (o / totalOvers) * w;
      canvas.drawLine(Offset(x, _top), Offset(x, _top + h), vGridPaint);
      _drawLabel(canvas, '$o', Offset(x, _top + h + 4), TextAlign.center);
    }
    // Ensure totalOvers is always shown if not already included by the loop
    if ((totalOvers - 1) % overStep != 0) {
      final x = _left + (totalOvers / totalOvers) * w;
      canvas.drawLine(Offset(x, _top), Offset(x, _top + h), vGridPaint);
      _drawLabel(canvas, '$totalOvers', Offset(x, _top + h + 4), TextAlign.center);
    }

    // ── Axes ──────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(_left, _top), Offset(_left, _top + h), axisPaint);
    canvas.drawLine(Offset(_left, _top + h), Offset(_left + w, _top + h), axisPaint);

    // ── Lines ─────────────────────────────────────────────────────────
    _drawInningLine(canvas, inning1Scores, w, h, maxScore,
        const Color(0xFF4FC3F7));
    _drawInningLine(canvas, inning2Scores, w, h, maxScore,
        const Color(0xFFEF5350));
  }

  void _drawInningLine(Canvas canvas, List<OverScoreRecord> scores,
      double w, double h, int maxScore, Color color) {
    if (scores.isEmpty) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dotFill  = Paint()..color = color..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    Offset toPoint(int over, int score) {
      final x = _left + (over / totalOvers) * w;
      final y = _top  + h - (score / maxScore) * h;
      return Offset(x, y.clamp(_top, _top + h));
    }

    // Build path starting from origin
    final path = Path()..moveTo(_left, _top + h);
    for (final s in scores) {
      final pt = toPoint(s.overNumber, s.score);
      path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path, linePaint);

    // Dots on data points
    for (final s in scores) {
      final pt = toPoint(s.overNumber, s.score);
      canvas.drawCircle(pt, 4, dotFill);
      canvas.drawCircle(pt, 4, dotBorder);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 9,
          color: Color(0x99FFFFFF),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    final dx = align == TextAlign.right
        ? pos.dx - tp.width
        : align == TextAlign.center
            ? pos.dx - tp.width / 2
            : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ScoringChartPainter old) =>
      old.inning1Scores != inning1Scores ||
      old.inning2Scores != inning2Scores ||
      old.totalOvers != totalOvers;
}

// ── Man of the Match card ─────────────────────────────────────────────────────

class _ManOfMatchCard extends StatelessWidget {
  final String playerName;

  const _ManOfMatchCard({required this.playerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'MAN OF THE MATCH',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Colors.white60,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  playerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
        ],
      ),
    );
  }
}

