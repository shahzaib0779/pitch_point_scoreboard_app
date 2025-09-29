import 'package:flutter/material.dart';

class ScoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ScoreButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding: EdgeInsets.symmetric(horizontal: 17)
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}
