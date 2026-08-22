import 'package:flutter/material.dart';

/// Rundad "pill"-banner, centrerad i mitten av raden i stället för en
/// helbred rektangel – används för statusmeddelandena högst upp
/// (turindikator, väntar-på-motståndare, starthandsval, se
/// game_board_screen.dart) för att passa den mer brädspels-inspirerade
/// stilen (gyllene kant, rundade hörn, se [CarvedFrame]) i stället för
/// kantiga fält som spänner hela bredden. Utrymmet runt pillen visar
/// den delade träbakgrunden bakom hela brädet (game_board_screen.dart)
/// i stället för en helfärgad remsa.
class PillBanner extends StatelessWidget {
  final Color color;
  final Widget child;
  final Color borderColor;

  const PillBanner({
    super.key,
    required this.color,
    required this.child,
    this.borderColor = const Color(0xFFC9A227),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
          ],
        ),
        child: child,
      ),
    );
  }
}
