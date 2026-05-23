import 'package:flutter/material.dart';

enum ScoreButtonVariant { run, extra, wicket, dot, retired }

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

  Color _bgColor() {
    switch (variant) {
      case ScoreButtonVariant.run:
        return const Color(0xFFD32F2F);
      case ScoreButtonVariant.extra:
        return const Color(0xFFE65100); // orange
      case ScoreButtonVariant.wicket:
        return const Color(0xFF6A0000); // dark red
      case ScoreButtonVariant.dot:
        return const Color(0xFF37474F); // dark grey-blue
      case ScoreButtonVariant.retired:
        return const Color(0xFF4A148C); // deep purple
    }
  }

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
