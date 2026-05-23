import 'package:flutter/material.dart';

enum ScoreButtonVariant { run, boundary, six, extra, wicket, dot, retired }

class ScoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ScoreButtonVariant variant;

  const ScoreButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ScoreButtonVariant.run,
  });

  Color _bgColor() => const Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _bgColor(),
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: Text(
        label,
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
