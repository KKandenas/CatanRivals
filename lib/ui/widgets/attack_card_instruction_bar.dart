import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';

/// Visas ovanför ditt eget rike när motståndaren har spelat Bågskytt
/// eller Pyroman och du måste välja bort en egen kvalificerande enhet
/// (se [GameNotifier.selectAttackCardUnit]/[TurnState.pendingAttackCard]-
/// doc) – samma enkla stil som [PirateShipDiscardBar], men med ett
/// extra steg (vilken draghög, se StackChoiceOverlay i
/// game_board_screen.dart) eftersom kortet inte hamnar i slänghögen
/// utan underst i en draghög.
class AttackCardInstructionBar extends StatelessWidget {
  final AttackCardKind kind;

  const AttackCardInstructionBar({super.key, required this.kind});

  String get _text {
    switch (kind) {
      case AttackCardKind.archer:
        return 'Bågskytt: tryck på en av dina egna enheter (byggnad, '
            'skepp eller hjälte) med styrkepoäng för att ta bort den.';
      case AttackCardKind.arsonist:
        return 'Pyroman: tryck på en av dina egna byggnader för att ta '
            'bort den.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        _text,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
