import 'package:flutter/material.dart';
import 'package:pitch_point/models/match_models.dart';
import 'package:pitch_point/pages/match_details_page.dart';
import 'package:pitch_point/services/match_service.dart';

class MatchHistoryPage extends StatefulWidget {
  const MatchHistoryPage({super.key});

  @override
  State<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends State<MatchHistoryPage> {
  List<MatchRecord>? _matches;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await MatchService.instance.getAllMatches();
      if (mounted) {
        setState(() {
          _matches = matches;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteMatch(MatchRecord match) async {
    if (match.id == null) { return; }
    await MatchService.instance.deleteMatch(match.id!);
    if (mounted) {
      setState(() => _matches?.removeWhere((m) => m.id == match.id));
    }
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Match History')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFD32F2F)),
            const SizedBox(height: 12),
            Text('Failed to load matches',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF424242),
                )),
          ],
        ),
      );
    }

    final matches = _matches ?? [];

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏏', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'No matches yet',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a match to see history here',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _MatchCard(
        match: matches[i],
        formatDate: _formatDate,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MatchDetailsPage(match: matches[i]),
          ),
        ),
        onDelete: () async {
          final confirmed = await _confirmDelete(context, matches[i]);
          if (confirmed) { await _deleteMatch(matches[i]); }
        },
      ),
    );
  }

  Future<bool> _confirmDelete(
      BuildContext context, MatchRecord match) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Match?'),
        content: Text(
          'Remove "${match.matchTitle}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ── Match card ────────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final MatchRecord match;
  final String Function(String) formatDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MatchCard({
    required this.match,
    required this.formatDate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final inning1 = match.inning1;
    final inning2 = match.inning2;

    return Dismissible(
      key: ValueKey(match.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // we handle removal manually after confirmation
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.matchTitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(completed: match.isCompleted),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Scores
                  if (inning1 != null)
                    _ScoreLine(
                      team: inning1.battingTeam,
                      score: inning1.scoreDisplay,
                      overs: inning1.oversDisplay,
                    ),
                  if (inning2 != null) ...[
                    const SizedBox(height: 4),
                    _ScoreLine(
                      team: inning2.battingTeam,
                      score: inning2.scoreDisplay,
                      overs: inning2.oversDisplay,
                    ),
                  ],

                  // Result + date
                  if (match.result.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      match.result,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: Color(0xFFBDBDBD)),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(match.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap for scorecard →',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: Color(0xFFBDBDBD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool completed;

  const _StatusBadge({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        completed ? 'Completed' : 'In Progress',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          fontSize: 10,
          color: completed
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE65100),
        ),
      ),
    );
  }
}

// ── Score line ────────────────────────────────────────────────────────────────

class _ScoreLine extends StatelessWidget {
  final String team;
  final String score;
  final String overs;

  const _ScoreLine({
    required this.team,
    required this.score,
    required this.overs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            team.isEmpty ? '—' : team,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Color(0xFF424242),
            ),
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: score,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF212121),
                ),
              ),
              TextSpan(
                text: '  ($overs ov)',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
