import 'package:flutter/material.dart';

class TeamNamesFields extends StatelessWidget {
  
  final String labelName;
  final TextEditingController controller;
    final Function(String)? onChanged;
  const TeamNamesFields({
        super.key, required this.labelName, required this.controller, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    return TextField(
      keyboardType: TextInputType.name,
      onChanged: onChanged,
      controller: controller,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.primary,
      ),
    decoration: InputDecoration(
      labelText: labelName,
      labelStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w500,
        color: Color.fromARGB(178, 0, 0, 0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
              color: Colors.red.shade400, // highlight color
              width: 2,
        ),
      ),
      prefixIcon: const Icon(Icons.sports_cricket, color: Colors.redAccent),
    ),
    );
  }
}