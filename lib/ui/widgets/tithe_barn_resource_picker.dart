import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';

/// Resurstypsväljaren för Tiondelada (regelhäftet: "När du bygger
/// Tiondeladan väljer du en resurstyp – antingen ull eller säd. För
/// varje egen hjälte får du 1 resurs av den valda typen.") – visas
/// direkt efter att bygget bekräftats (se game_board_screen.dart:
/// `_confirmPendingBuild`). Precis som andra byggeffekter (Stapelhus/
/// Marknadsfält) flyttar appen inga resurser åt spelarna, så [onPick]
/// bara stänger dialogen; anroparen visar sedan en påminnelsetext med
/// det faktiska antalet.
Future<void> showTitheBarnResourcePicker(
  BuildContext context, {
  required ValueChanged<ResourceType> onPick,
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
                  'Tiondelada: välj resurstyp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F6F45)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onPick(ResourceType.wool);
                        },
                        child: const Text('Ull'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F6F45)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onPick(ResourceType.grain);
                        },
                        child: const Text('Säd'),
                      ),
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
