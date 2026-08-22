import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Snurrar sitt barn ett helt varv (360°) varje gång [value] ändras –
/// en liten "tärningskänsla" när produktions-/händelsetärningen slås
/// (se DiceRollButton/EventDieIcon), utan att röra själva innehållet:
/// eftersom det alltid landar tillbaka på exakt samma vinkel (0°) ser
/// barnet likadant ut i vila, bara i rörelse precis efter ett kast.
///
/// Bygger på att [value] blir en ny [ValueKey] – ändras inte värdet
/// (t.ex. samma tal slås två gånger i rad) snurrar den inte igen,
/// vilket är en medveten avvägning: att alltid snurra på varje kast
/// oavsett resultat skulle kräva en egen räknare i spelstate bara för
/// den här kosmetiska detaljen.
class SpinOnChange<T> extends StatelessWidget {
  final T value;
  final Widget child;
  final Duration duration;

  const SpinOnChange({
    super.key,
    required this.value,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, animatedChild) =>
          Transform.rotate(angle: t * 2 * math.pi, child: animatedChild),
      child: child,
    );
  }
}
