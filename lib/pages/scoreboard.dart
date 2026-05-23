import 'package:flutter/material.dart';
import 'package:pitch_point/Providers/scoreboard_provider.dart';
import 'package:pitch_point/Providers/team_names_provider.dart';
import 'package:pitch_point/pages/congratulations.dart';
import 'package:pitch_point/services/match_service.dart';
import 'package:pitch_point/util/bat_ball_class.dart';
import 'package:pitch_point/widgets/score_button.dart';
import 'package:provider/provider.dart';

// ── Delivery type modifier ────────────────────────────────────────────────────

enum DeliveryType { normal, noBall, bye, legBye }

class Scoreboard extends StatefulWidget {
  const Scoreboard({super.key});

  @override
  State<Scoreboard> createState() => _ScoreboardState();
}

class _ScoreboardState extends State<Scoreboard> {
  /// Guards against showing the inning-completed dialog more than once.
  bool _inningDialogShown = false;

  /// Active delivery modifier — auto-resets to [DeliveryType.normal] after
  /// each counted delivery.
  DeliveryType _deliveryType = DeliveryType.normal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAddPlayers();
    });
  }

  // ── Setup dialogs ─────────────────────────────────────────────────────────

  Future<void> _checkAndAddPlayers() async {
    if (!mounted) { return; }
    final sp = Provider.of<ScoreboardProvider>(context, listen: false);

    if (sp.striker.isEmpty) {
      final name = await _inputDialog('Striker Name', TextInputType.name);
      if (name != null && name.isNotEmpty) {
        sp.setStriker(name);
        sp.activeInning.addBatsman(Batting(playerName: name));
      }
    }

    if (sp.nonStriker.isEmpty) {
      final name =
          await _inputDialog('Non-Striker Name', TextInputType.name);
      if (name != null && name.isNotEmpty) {
        sp.setNonStriker(name);
        sp.activeInning.addBatsman(Batting(playerName: name));
      }
    }

    if (sp.currentBowler.isEmpty) {
      final name =
          await _inputDialog('Opening Bowler Name', TextInputType.name);
      if (name != null && name.isNotEmpty) {
        sp.setBowler(name);
        sp.activeInning.addBowler(Bowling(playerName: name));
      }
    }

    if (sp.activeInning.totalOvers == 0) {
      final s = await _inputDialog('Total Overs', TextInputType.number);
      final overs = int.tryParse(s ?? '');
      if (overs != null && overs > 0) { sp.inningOvers(overs); }
    }

    if (sp.activeInning.inningWickets == 0) {
      final s =
          await _inputDialog('Max Wickets', TextInputType.number);
      final w = int.tryParse(s ?? '');
      if (w != null && w > 0) { sp.inningWickets(w); }
    }

    // Create DB record once all setup dialogs are done
    await _initMatchInDb();
  }

  // ── DB: create the match record once, after all setup dialogs ─────────────

  Future<void> _initMatchInDb() async {
    if (!mounted) { return; }
    final sp = Provider.of<ScoreboardProvider>(context, listen: false);
    if (sp.matchId != null) { return; } // already created (or resumed)

    final tnp = Provider.of<TeamNamesProvider>(context, listen: false);

    final tossWinner = tnp.team1Toss ? tnp.team1 : tnp.team2;
    final tossDecision =
        sp.inning1.battingTeamName == tossWinner ? 'bat' : 'bowl';

    try {
      final ids = await MatchService.instance.createMatch(
        team1: tnp.team1,
        team2: tnp.team2,
        tossWinner: tossWinner,
        tossDecision: tossDecision,
        totalOvers: sp.inning1.totalOvers,
        maxWickets: sp.inning1.inningWickets,
        inning1BattingTeam: sp.inning1.battingTeamName,
        inning1BowlingTeam: sp.inning1.bowlingTeamName,
        inning2BattingTeam: sp.inning2.battingTeamName,
        inning2BowlingTeam: sp.inning2.bowlingTeamName,
      );
      sp.setMatchIds(ids.matchId, ids.inning1Id, ids.inning2Id);
    } catch (e) {
      debugPrint('DB init error: $e');
    }
  }

  // ── DB: fire-and-forget save after every delivery ─────────────────────────

  void _saveProgress() {
    if (!mounted) { return; }
    final sp = Provider.of<ScoreboardProvider>(context, listen: false);
    if (sp.matchId == null) { return; }
    MatchService.instance.saveProgress(sp); // intentionally not awaited
  }

  // ── Delivery type helpers ─────────────────────────────────────────────────

  void _resetDeliveryType() {
    if (_deliveryType != DeliveryType.normal) {
      setState(() => _deliveryType = DeliveryType.normal);
    }
  }

  Color get _deliveryAccentColor {
    switch (_deliveryType) {
      case DeliveryType.normal:
        return const Color(0xFFD32F2F);
      case DeliveryType.noBall:
        return const Color(0xFFE65100);
      case DeliveryType.bye:
        return const Color(0xFF1565C0);
      case DeliveryType.legBye:
        return const Color(0xFF2E7D32);
    }
  }

  // ── Scoring actions ───────────────────────────────────────────────────────

  /// Scores [runs] runs, respecting the active delivery modifier.
  Future<void> _scoreRun(ScoreboardProvider sp, int runs) async {
    switch (_deliveryType) {
      case DeliveryType.normal:
        sp.updateBatsmanScore(sp.striker, runs, 1);
        if (runs.isOdd) { sp.rotateStrike(); }
        sp.updateBowlerScore(sp.currentBowler, runs, 0);
        sp.addBallToOver('$runs');
        await _handleOverEnd(sp);

      case DeliveryType.noBall:
        sp.updateBatsmanScore(sp.striker, runs, 0);
        if (runs.isOdd) { sp.rotateStrike(); }
        sp.updateNoBall(runs);
        sp.addBallToOver('NB');

      case DeliveryType.bye:
        sp.addBye(runs);
        if (runs.isOdd) { sp.rotateStrike(); }
        sp.addBallToOver('B');
        await _handleOverEnd(sp);

      case DeliveryType.legBye:
        sp.addLegBye(runs);
        if (runs.isOdd) { sp.rotateStrike(); }
        sp.addBallToOver('LB');
        await _handleOverEnd(sp);
    }
    _resetDeliveryType();
    _saveProgress();
  }

  /// Scores a dot ball, respecting the active modifier.
  Future<void> _scoreDot(ScoreboardProvider sp) async {
    switch (_deliveryType) {
      case DeliveryType.normal:
      case DeliveryType.bye:
      case DeliveryType.legBye:
        sp.addBallToBatsman();
        sp.updateBowlerScore(sp.currentBowler, 0, 0);
        sp.addBallToOver('·');
        await _handleOverEnd(sp);

      case DeliveryType.noBall:
        sp.updateNoBall(0);
        sp.addBallToOver('NB');
    }
    _resetDeliveryType();
    _saveProgress();
  }

  /// Scores a wicket, respecting the active modifier.
  Future<void> _scoreWicket(ScoreboardProvider sp) async {
    switch (_deliveryType) {
      case DeliveryType.normal:
      case DeliveryType.bye:
      case DeliveryType.legBye:
        sp.addBallToBatsman();
        sp.updateBowlerScore(sp.currentBowler, 0, 1);
        sp.addBallToOver('W');
        await _handleWicketFallout(sp);
        await _handleOverEnd(sp);

      case DeliveryType.noBall:
        sp.updateNoBall(0, isWicket: true);
        sp.addBallToOver('NB');
        await _handleWicketFallout(sp);
    }
    _resetDeliveryType();
    _saveProgress();
  }

  /// Common wicket handling: mark batsman out, ask for new batsman if needed.
  Future<void> _handleWicketFallout(ScoreboardProvider sp) async {
    final canContinue =
        sp.activeInning.inningWickets != 0 &&
        sp.activeInning.totalWickets < sp.activeInning.inningWickets;
    if (!canContinue) { return; }

    sp.batsmanOut();
    final name =
        await _inputDialog('New Batsman Name', TextInputType.name);
    if (name != null && name.isNotEmpty) {
      sp.setStriker(name);
      sp.activeInning.addBatsman(Batting(playerName: name));
    }
  }

  // ── Wide ──────────────────────────────────────────────────────────────────

  Future<void> _handleWide(ScoreboardProvider sp) async {
    final runs = await _wideOptionsSheet();
    if (runs == null) { return; }
    sp.updateWide(runs);
    sp.addBallToOver('Wd');
    _saveProgress();
  }

  Future<int?> _wideOptionsSheet() async {
    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Wide — How many total runs?',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Includes the 1-run wide penalty.',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (int i = 1; i <= 5; i++) ...[
                  Expanded(
                    child: _WideOptionButton(
                      runs: i,
                      onTap: () => Navigator.pop(ctx, i),
                    ),
                  ),
                  if (i < 5) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Retired Hurt ──────────────────────────────────────────────────────────

  Future<void> _handleRetiredHurt(ScoreboardProvider sp) async {
    if (sp.striker.isEmpty) { return; }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retired Hurt'),
        content: Text(
          '${sp.striker} will retire hurt and leave the crease.\n'
          'A new batsman will take their place.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) { return; }

    sp.retiredHurt();

    final name =
        await _inputDialog('New Batsman Name', TextInputType.name);
    if (name != null && name.isNotEmpty) {
      sp.setStriker(name);
      sp.activeInning.addBatsman(Batting(playerName: name));
    }
    _saveProgress();
  }

  // ── Input dialog ──────────────────────────────────────────────────────────

  Future<String?> _inputDialog(
      String title, TextInputType keyboardType) async {
    String value = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          autofocus: true,
          keyboardType: keyboardType,
          onChanged: (v) => value = v,
          decoration: const InputDecoration(labelText: 'Type here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, value.trim()),
            child: const Text('Add',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Over / bowler change ──────────────────────────────────────────────────

  Future<void> _handleOverEnd(ScoreboardProvider sp) async {
    if (sp.getCurrentBowls() != 6) { return; }
    if (sp.activeInning.oversBowled >= sp.activeInning.totalOvers) { return; }

    sp.resetCurrentBowlerBalls();

    // Previous bowlers (excluding the one who just finished)
    final prev = sp.activeInning.bowlersList
        .where((b) => b.playerName != sp.currentBowler)
        .map((b) => b.playerName)
        .toList();

    String? name;
    if (prev.isNotEmpty) {
      final picked = await _bowlerPickerSheet(prev);
      if (picked == null) { return; }
      name = picked == '__new__'
          ? await _inputDialog('New Bowler Name', TextInputType.name)
          : picked;
    } else {
      name = await _inputDialog('New Bowler Name', TextInputType.name);
    }

    if (name != null && name.isNotEmpty) {
      sp.setBowler(name);
      if (!sp.activeInning.bowlersList.any((b) => b.playerName == name)) {
        sp.activeInning.addBowler(Bowling(playerName: name));
      }
      sp.rotateStrike();
    }

    // Persist the score at the end of this over
    if (sp.activeInningId != null) {
      MatchService.instance.recordOverScore(
        sp.activeInningId!,
        sp.activeInning.oversBowled,
        sp.activeInning.totalScore,
        sp.activeInning.totalWickets,
      );
    }
  }

  Future<String?> _bowlerPickerSheet(List<String> previous) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Bowler',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Previously bowled this innings',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 12),
            ...previous.map(
              (name) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF212121),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFBDBDBD)),
                onTap: () => Navigator.pop(ctx, name),
              ),
            ),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                child: const Icon(Icons.add, color: Color(0xFFD32F2F), size: 18),
              ),
              title: const Text(
                'New Bowler',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFFD32F2F),
                ),
              ),
              onTap: () => Navigator.pop(ctx, '__new__'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Inning completed ──────────────────────────────────────────────────────

  void _onInningComplete(ScoreboardProvider sp) {
    if (_inningDialogShown) { return; }
    _inningDialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) { return; }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          final isFirstInning = sp.currentInning == 1;
          return AlertDialog(
            title: Text(
                isFirstInning ? 'Inning 1 Complete' : 'Match Complete'),
            content: Text(
              isFirstInning
                  ? '${sp.activeInning.battingTeamName} scored '
                      '${sp.activeInning.totalScore}/${sp.activeInning.totalWickets} '
                      'in ${sp.activeInning.oversBowled}.'
                      '${sp.getCurrentBowls() == 6 ? 0 : sp.getCurrentBowls()} overs.\n\n'
                      '${sp.inning2.battingTeamName} needs '
                      '${sp.activeInning.totalScore + 1} to win.'
                  : sp.getMatchResult(),
            ),
            actions: [
              if (isFirstInning)
                ElevatedButton(
                  onPressed: () {
                    sp.switchInning();
                    Navigator.pop(dialogCtx);
                    setState(() => _inningDialogShown = false);
                    Future.microtask(() {
                      if (mounted) { _checkAndAddPlayers(); }
                    });
                  },
                  child: const Text('Start Inning 2',
                      style: TextStyle(color: Colors.white)),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    // Persist final scores + mark match complete in DB
                    if (sp.matchId != null) {
                      MatchService.instance.saveProgress(sp);
                      final resultText = sp.getMatchResult();
                      final winner =
                          sp.activeInning.totalScore > sp.inning1.totalScore
                              ? sp.activeInning.battingTeamName
                              : (sp.activeInning.totalScore ==
                                      sp.inning1.totalScore
                                  ? 'Tie'
                                  : sp.inning1.battingTeamName);
                      MatchService.instance.completeMatch(
                          sp.matchId!, resultText, winner);
                    }
                    Navigator.pop(dialogCtx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CongratulationsPage(
                          winnerName: sp.activeInning.totalScore >
                                  sp.inning1.totalScore
                              ? sp.activeInning.battingTeamName
                              : (sp.activeInning.totalScore ==
                                      sp.inning1.totalScore
                                  ? 'Nobody'
                                  : sp.inning1.battingTeamName),
                          resultLine: sp.getMatchResult(),
                          team1Name: sp.inning1.battingTeamName,
                          team1Score:
                              '${sp.inning1.totalScore}/${sp.inning1.totalWickets}',
                          team2Name: sp.inning2.battingTeamName,
                          team2Score:
                              '${sp.inning2.totalScore}/${sp.inning2.totalWickets}',
                        ),
                      ),
                    );
                  },
                  child: const Text('See Result',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          );
        },
      );
    });
  }

  // ── Row builders ──────────────────────────────────────────────────────────

  Widget _batsmanRow(
      String name, bool isStriker, ScoreboardProvider sp) {
    final list = sp.activeInning.battingList;
    if (name.isEmpty || !list.any((b) => b.playerName == name)) {
      return _statsRow(
          isStriker ? '$name 🏏' : name, '0 (0)', dimmed: false);
    }
    final b = list.firstWhere((b) => b.playerName == name);
    final suffix = b.retiredHurt
        ? ' 🩹'
        : (b.bowled ? ' ✖' : (isStriker ? ' 🏏' : ''));
    return _statsRow(
      '${b.playerName}$suffix',
      '${b.runs} (${b.balls})  4s:${b.fours}  6s:${b.sixes}',
      dimmed: b.isGone,
      bold: isStriker && !b.isGone,
    );
  }

  Widget _statsRow(String left, String right,
      {bool dimmed = false, bool bold = false}) {
    final color =
        dimmed ? Colors.grey : const Color(0xFF212121);
    final weight =
        bold ? FontWeight.w700 : FontWeight.w500;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            left,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: weight,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
        Text(
          right,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _bowlerRow(String name, ScoreboardProvider sp) {
    final list = sp.activeInning.bowlersList;
    if (name.isEmpty || !list.any((b) => b.playerName == name)) {
      return _statsRow('— Bowler', '0/0 (0.0)');
    }
    final b = list.firstWhere((b) => b.playerName == name);
    final balls = sp.getCurrentBowls() == 6 ? 0 : sp.getCurrentBowls();
    return _statsRow(
      '⚾  $name',
      '${b.wickets}/${b.runsConceded} (${b.overs}.$balls)',
      bold: true,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<ScoreboardProvider>(context);

    // Inning-completion guard — fire once per inning
    if (sp.isInningCompleted() && !_inningDialogShown) {
      _onInningComplete(sp);
    }

    final balls = sp.getCurrentBowls() == 6 ? 0 : sp.getCurrentBowls();
    final oversBowled = sp.activeInning.oversBowled;
    final totalOvers = sp.activeInning.totalOvers;
    final score = sp.activeInning.totalScore;
    final wickets = sp.activeInning.totalWickets;
    final extras = sp.activeInning.totalExtras;

    // Run rate
    final double rr = oversBowled < 1
        ? score.toDouble()
        : score / (oversBowled + balls / 10);

    // Target / required (inning 2 only)
    final int target = sp.inning1.totalScore + 1;
    final int needed = target - score;
    final int ballsLeft =
        (totalOvers * 6) - (oversBowled * 6 + balls);
    final double rrr =
        ballsLeft > 0 ? (needed / (ballsLeft / 6)) : 0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Inning ${sp.currentInning}  •  ${sp.activeInning.battingTeamName}',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // ── Score card ─────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  children: [
                    // Team name
                    Text(
                      sp.activeInning.battingTeamName.isEmpty
                          ? 'Batting'
                          : sp.activeInning.battingTeamName,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Score
                    Text(
                      '$score / $wickets',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                        fontSize: 52,
                        color: Color(0xFFD32F2F),
                        height: 1.0,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Overs + RR + Extras
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _pill(
                            'Overs: $oversBowled.$balls / $totalOvers'),
                        _pill('RR: ${rr.toStringAsFixed(2)}'),
                        if (extras > 0) _pill('Extras: $extras'),
                      ],
                    ),

                    // Inning 2: target info
                    if (sp.currentInning == 2 &&
                        sp.currentBowler.isNotEmpty &&
                        totalOvers != 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFFFB300), width: 1),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Target: $target',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Need $needed in $ballsLeft balls  •  RRR: ${rrr.toStringAsFixed(2)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Batsmen card ───────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    // ── Batsmen header with rotate strike ──────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel('Batsmen'),
                        GestureDetector(
                          onTap: () => sp.rotateStrike(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFD32F2F)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.compare_arrows_rounded,
                                    size: 13, color: Color(0xFFD32F2F)),
                                SizedBox(width: 4),
                                Text(
                                  'Rotate',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: Color(0xFFD32F2F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _batsmanRow(sp.striker, true, sp),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1),
                    ),
                    _batsmanRow(sp.nonStriker, false, sp),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1),
                    ),
                    // ── Current over ball-by-ball ───────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel('This Over'),
                        Text(
                          '$oversBowled.$balls / $totalOvers',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _OverBallsRow(sp: sp),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Bowler card ────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    _sectionLabel('Bowler'),
                    const SizedBox(height: 10),
                    _bowlerRow(sp.currentBowler, sp),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Score panel ────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _deliveryType == DeliveryType.normal
                      ? Colors.transparent
                      : _deliveryAccentColor.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                children: [
                  const Text(
                    'Score Panel',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Delivery Type Selector ─────────────────────────
                  _DeliveryTypeSelector(
                    selected: _deliveryType,
                    onChanged: (t) => setState(() => _deliveryType = t),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Row 1: 1 · 2 · 3
                  Row(
                    children: [
                      Expanded(
                          child: ScoreButton(
                              label: '1',
                              onPressed: () => _scoreRun(sp, 1))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ScoreButton(
                              label: '2',
                              onPressed: () => _scoreRun(sp, 2))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ScoreButton(
                              label: '3',
                              onPressed: () => _scoreRun(sp, 3))),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Row 2: 4 · 6 · Wide
                  Row(
                    children: [
                      Expanded(
                          child: ScoreButton(
                              label: '4',
                              variant: ScoreButtonVariant.boundary,
                              onPressed: () => _scoreRun(sp, 4))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ScoreButton(
                              label: '6',
                              variant: ScoreButtonVariant.six,
                              onPressed: () => _scoreRun(sp, 6))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ScoreButton(
                              label: 'Wide',
                              variant: ScoreButtonVariant.extra,
                              onPressed: () => _handleWide(sp))),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Row 3: W · Dot · Ret
                  Row(
                    children: [
                      Expanded(
                          child: ScoreButton(
                              label: 'W',
                              variant: ScoreButtonVariant.wicket,
                              onPressed: () => _scoreWicket(sp))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ScoreButton(
                              label: '·',
                              variant: ScoreButtonVariant.dot,
                              onPressed: () => _scoreDot(sp))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ScoreButton(
                              label: 'Ret ↩',
                              variant: ScoreButtonVariant.retired,
                              onPressed: () =>
                                  _handleRetiredHurt(sp))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Color(0xFF424242),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: Color(0xFFD32F2F),
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ── Delivery Type Selector ────────────────────────────────────────────────────

class _DeliveryTypeSelector extends StatelessWidget {
  final DeliveryType selected;
  final ValueChanged<DeliveryType> onChanged;

  static const _labels = {
    DeliveryType.normal: 'Normal',
    DeliveryType.noBall: 'No Ball',
    DeliveryType.bye: 'Bye',
    DeliveryType.legBye: 'Leg Bye',
  };

  static const _colors = {
    DeliveryType.normal: Color(0xFF212121),
    DeliveryType.noBall: Color(0xFFE65100),
    DeliveryType.bye: Color(0xFF1565C0),
    DeliveryType.legBye: Color(0xFF2E7D32),
  };

  const _DeliveryTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DELIVERY TYPE',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            color: Color(0xFF9E9E9E),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: DeliveryType.values.map((type) {
            final isSelected = selected == type;
            final color = _colors[type]!;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => onChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _labels[type]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: isSelected ? Colors.white : color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Over ball-by-ball row ─────────────────────────────────────────────────────

class _OverBallsRow extends StatelessWidget {
  final ScoreboardProvider sp;

  const _OverBallsRow({required this.sp});

  @override
  Widget build(BuildContext context) {
    final legalBalls = sp.getCurrentBowls().clamp(0, 6);
    final emptySlots = 6 - legalBalls;

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        ...sp.currentOverBalls.map((b) => _BallChip(label: b)),
        ...List.generate(emptySlots, (_) => const _EmptyBallSlot()),
      ],
    );
  }
}

class _BallChip extends StatelessWidget {
  final String label;

  const _BallChip({required this.label});

  Color get _color {
    switch (label) {
      case '·':
        return const Color(0xFF9E9E9E);
      case 'W':
        return const Color(0xFF212121);
      case 'Wd':
      case 'NB':
        return const Color(0xFFE65100);
      case 'B':
      case 'LB':
        return const Color(0xFF546E7A);
      default: // runs 1–6
        return const Color(0xFFD32F2F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _EmptyBallSlot extends StatelessWidget {
  const _EmptyBallSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
      ),
    );
  }
}

// ── Wide option button ────────────────────────────────────────────────────────

class _WideOptionButton extends StatelessWidget {
  final int runs;
  final VoidCallback onTap;

  const _WideOptionButton({required this.runs, required this.onTap});

  String get _label {
    switch (runs) {
      case 1:
        return '+1\n(Wide)';
      case 2:
        return '+2\n(W+1)';
      case 3:
        return '+3\n(W+2)';
      case 4:
        return '+4\n(W+3)';
      case 5:
        return '+5\n(W·4)';
      default:
        return '+$runs';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFE65100).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE65100).withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            _label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFFE65100),
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
