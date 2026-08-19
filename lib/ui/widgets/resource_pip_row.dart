import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Rad med "pärlor" som visar hur många resurser (0–3) ett regionkort
/// har lagrat just nu – ersätter det fysiska spelets kortrotation.
class ResourcePipRow extends StatelessWidget {
  final Color color;
  final int stored;
  final int capacity;

  const ResourcePipRow({
    super.key,
    required this.color,
    required this.stored,
    this.capacity = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(capacity, (i) {
        final lit = i < stored;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lit ? color : Colors.transparent,
            border: Border.all(color: lit ? color : CatanColors.buildingSiteBorder, width: 1),
            boxShadow: lit
                ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 4, spreadRadius: 0.5)]
                : null,
          ),
        );
      }),
    );
  }
}
