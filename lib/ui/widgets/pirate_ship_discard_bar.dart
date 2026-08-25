import 'package:flutter/material.dart';

import '../theme/catan_colors.dart';

/// Visas ovanför ditt eget rike när motståndaren har byggt Piratskepp
/// och du måste välja bort ett eget handelsskepp (se
/// [GameNotifier.resolvePirateShipDiscard]) – samma enkla stil som
/// [FeudBuildingInstructionBar], men utan "Avbryt"-knapp: till skillnad
/// från Fejd finns inget föregående val att ångra, ett enda tryck på ett
/// handelsskepp genomför bytet direkt.
class PirateShipDiscardBar extends StatelessWidget {
  const PirateShipDiscardBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: const Text(
        'Piratskepp: tryck på ett av dina egna handelsskepp för att '
        'kasta det.',
        style: TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
