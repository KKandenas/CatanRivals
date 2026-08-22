import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';
import 'dice_face.dart';

/// Sifferväljaren för Brigitta, den visa kvinnan (regelhäftet: "Play
/// this card before rolling the dice. Choose the result of the
/// production die roll.") – visas efter att spelaren bekräftat "Vill
/// du använda kortet?" i kortförstoringen (se `showCardDetail`s
/// `onUseCard`, card_detail_dialog.dart). Ett tryck på en tärningssida
/// väljer den och stänger dialogrutan direkt; [onPick] sköter själva
/// tärningsslaget (GameNotifier.useBrigitta).
Future<void> showBrigittaNumberPicker(
  BuildContext context, {
  required ValueChanged<int> onPick,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Välj produktionstärningens resultat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var n = 1; n <= 6; n++)
                      _NumberButton(
                        number: n,
                        onTap: () {
                          Navigator.of(context).pop();
                          onPick(n);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NumberButton extends StatelessWidget {
  final int number;
  final VoidCallback onTap;

  const _NumberButton({required this.number, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CatanColors.woodFrame, width: 1.4),
        ),
        alignment: Alignment.center,
        child: DiceFace(value: number, size: 34, dotColor: CatanColors.ink),
      ),
    );
  }
}
