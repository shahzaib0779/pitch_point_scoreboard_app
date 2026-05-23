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
      appBar: AppBar(title: Text(match.matchTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Match header ──────────────────────────────────────────────
            _MatchHeaderCard(match: match, formatDate: _formatDate),

            const SizedBox(height: 14),

            // ── Inning 1 ──────────────────────────────────────────────────
            if (inning1 != null) ...[
              _InningScorecard(inning: inning1, inningLabel: 'Inning 1'),
              const SizedBox(height: 14),
            ],

            // ── Inning 2 ──────────────────────────────────────────────────
            if (inning2 != null) ...[
              _InningScorecard(inning: inning2, inningLabel: 'Inning 2'),
              const SizedBox(height: 14),
            ],

            // ── Result banner ─────────────────────────────────────────────
            if (match.result.isNotEmpty) _ResultBanner(result: match.result),

            const SizedBox(height: 28),
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
            // Teams
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    match.team1Name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.team2Name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Meta row
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 6,
              children: [
                _MetaChip(
                    icon: Icons.emoji_events_rounded,
                    text: 'Toss: ${match.tossWinner} (${match.tossDecision})'),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }
}

// ── Inning scorecard ──────────────────────────────────────────────────────────

class _InningScorecard extends StatelessWidget {
  final InningRecord inning;
  final String inningLabel;

  const _InningScorecard({
    required this.inning,
    required this.inningLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inning title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel(inningLabel),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      inning.scoreDisplay,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    Text(
                      '${inning.battingTeam}  •  ${inning.oversDisplay} Ov',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Batting table ──
            if (inning.battingList.isNotEmpty) ...[
              _SectionLabel('Batting'),
              const SizedBox(height: 8),
              _TableHeader(
                  cells: const ['Batsman', 'R', 'B', '4s', '6s', 'SR', '']),
              const Divider(height: 8),
              ...inning.battingList.map((b) => _BattingRow(b)),
              // Extras row
              if (inning.totalExtras > 0) ...[
                const Divider(height: 12),
                _ExtrasRow(inning: inning),
              ],
              const SizedBox(height: 12),
            ],

            // ── Bowling table ──
            if (inning.bowlingList.isNotEmpty) ...[
              _SectionLabel('Bowling'),
              const SizedBox(height: 8),
              _TableHeader(
                  cells: const ['Bowler', 'O', 'R', 'W', 'Econ']),
              const Divider(height: 8),
              ...inning.bowlingList.map((b) => _BowlingRow(b)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Table header ──────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final List<String> cells;

  const _TableHeader({required this.cells});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            cells[0],
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final cell in cells.skip(1))
          SizedBox(
            width: 34,
            child: Text(
              cell,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF9E9E9E),
                letterSpacing: 0.8,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Batting row ───────────────────────────────────────────────────────────────

class _BattingRow extends StatelessWidget {
  final BattingRecord b;

  const _BattingRow(this.b);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
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
                    color: b.isOut
                        ? const Color(0xFF9E9E9E)
                        : const Color(0xFF212121),
                  ),
                ),
                Text(
                  b.isRetiredHurt
                      ? 'retired hurt'
                      : (b.isOut ? 'out' : 'not out'),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
                    color: b.isRetiredHurt
                        ? const Color(0xFF4A148C)
                        : (b.isOut
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF43A047)),
                  ),
                ),
              ],
            ),
          ),
          _statCell('${b.runs}',
              bold: true, color: const Color(0xFF212121)),
          _statCell('${b.balls}'),
          _statCell('${b.fours}'),
          _statCell('${b.sixes}'),
          _statCell(b.strikeRateStr),
          // empty placeholder matching batting table header count
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  Widget _statCell(String text,
      {bool bold = false, Color color = const Color(0xFF424242)}) {
    return SizedBox(
      width: 34,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
          color: color,
        ),
      ),
    );
  }
}

// ── Extras row ────────────────────────────────────────────────────────────────

class _ExtrasRow extends StatelessWidget {
  final InningRecord inning;

  const _ExtrasRow({required this.inning});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (inning.wides > 0) { parts.add('Wd: ${inning.wides}'); }
    if (inning.noBalls > 0) { parts.add('NB: ${inning.noBalls}'); }
    if (inning.byes > 0) { parts.add('B: ${inning.byes}'); }
    if (inning.legByes > 0) { parts.add('LB: ${inning.legByes}'); }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
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
                Text(
                  parts.join('  '),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          // Runs column
          SizedBox(
            width: 34,
            child: Text(
              '${inning.totalExtras}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF212121),
              ),
            ),
          ),
          // Remaining stat columns filled with —
          for (int i = 0; i < 5; i++)
            const SizedBox(
              width: 34,
              child: Text(
                '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bowling row ───────────────────────────────────────────────────────────────

class _BowlingRow extends StatelessWidget {
  final BowlingRecord b;

  const _BowlingRow(this.b);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
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
          _statCell(b.oversStr),
          _statCell('${b.runsConceded}'),
          _statCell('${b.wickets}',
              bold: b.wickets > 0, color: const Color(0xFFD32F2F)),
          _statCell(b.economyStr),
        ],
      ),
    );
  }

  Widget _statCell(String text,
      {bool bold = false, Color color = const Color(0xFF424242)}) {
    return SizedBox(
      width: 34,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
          color: color,
        ),
      ),
    );
  }
}

// ── Result banner ─────────────────────────────────────────────────────────────

class _ResultBanner extends StatelessWidget {
  final String result;

  const _ResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFF7F0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
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
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: Color(0xFFD32F2F),
        letterSpacing: 1.4,
      ),
    );
  }
}
