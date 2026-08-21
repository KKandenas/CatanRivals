import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Info-remsan som dyker upp precis efter ett tärningskast: vem som
/// slog, vilket tal, och en påminnelse om att ta resurser via +-
/// knapparna på regionerna. En vanlig, icke-modal rad i sidflödet
/// (inte en dialogruta) – den skjuter bara ner resten av innehållet,
/// så den täcker aldrig egna regioner och +-knapparna går att trycka
/// på medan den syns. Stängs manuellt med "OK", eller försvinner
/// automatiskt när en ny omgång börjar (se `key: ValueKey(roll)` i
/// game_board_screen.dart, som gör att widgeten byggs om från noll –
/// och därmed återställer `_dismissed` – för varje nytt kast).
class RollInfoBanner extends StatefulWidget {
  final int roll;
  final bool rolledByMe;
  final String opponentName;

  const RollInfoBanner({
    super.key,
    required this.roll,
    required this.rolledByMe,
    required this.opponentName,
  });

  @override
  State<RollInfoBanner> createState() => _RollInfoBannerState();
}

class _RollInfoBannerState extends State<RollInfoBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final who = widget.rolledByMe ? 'Du' : widget.opponentName;
    return Container(
      width: double.infinity,
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$who slog en ${widget.roll}:a. Ta dina resurser genom att trycka på +.',
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF7CBF6A),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
