import 'package:flutter/material.dart';

/// En tärningssida ritad som prickar (som en riktig tärning), 1–6.
/// Används både för produktionstärningens kast och för
/// tärningstalen på regionkorten.
class DiceFace extends StatelessWidget {
  final int value;
  final double size;
  final Color dotColor;

  const DiceFace(
      {super.key, required this.value, this.size = 24, required this.dotColor});

  // 3x3-rutnät, vänster-till-höger/uppifrån-och-ned, samma layout som
  // en fysisk tärning.
  static const Map<int, List<bool>> _patterns = {
    1: [false, false, false, false, true, false, false, false, false],
    2: [true, false, false, false, false, false, false, false, true],
    3: [true, false, false, false, true, false, false, false, true],
    4: [true, false, true, false, false, false, true, false, true],
    5: [true, false, true, false, true, false, true, false, true],
    6: [true, false, true, true, false, true, true, false, true],
  };

  @override
  Widget build(BuildContext context) {
    final pattern = _patterns[value.clamp(1, 6)]!;
    final dotSize = size / 4.5;
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var row = 0; row < 3; row++)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var col = 0; col < 3; col++)
                    SizedBox(
                      width: dotSize,
                      height: dotSize,
                      child: pattern[row * 3 + col]
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                  color: dotColor, shape: BoxShape.circle),
                            )
                          : null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
