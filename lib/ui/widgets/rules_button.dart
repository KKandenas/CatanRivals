import 'package:flutter/material.dart';

/// Liten rund "?"-knapp som öppnar regelsidan (RulesScreen) – samma
/// utseende både på startskärmen (lobby_screen.dart) och under själva
/// spelet (game_board_screen.dart), så den känns igen på samma ställe
/// (uppe till vänster) oavsett var man är i appen.
class RulesButton extends StatelessWidget {
  final VoidCallback onTap;

  const RulesButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC9A227), width: 1.4),
        ),
        alignment: Alignment.center,
        child: const Text(
          '?',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
