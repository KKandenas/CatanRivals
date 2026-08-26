import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Beskriver vad spelaren håller på att göra, för rubriken i kortet.
String _actionPhrase(GameCard card) {
  switch (card.category) {
    case CardCategory.road:
      return 'placera ut en väg';
    case CardCategory.settlement:
      return 'bygga en by';
    case CardCategory.city:
      return 'bygga en stad';
    default:
      return 'spela ${card.name}';
  }
}

/// Sammanfattar poängen kortet ger, t.ex. "1 handelspoäng" eller
/// "2 styrkepoäng och 1 segerpoäng". Null om kortet inte ger några poäng
/// (t.ex. vägar och byar).
String? _pointsPhrase(GameCard card) {
  final parts = <String>[
    if (card.strengthPoints > 0)
      '${card.strengthPoints} styrkepoäng',
    if (card.commercePoints > 0)
      '${card.commercePoints} handelspoäng',
    if (card.skillPoints > 0) '${card.skillPoints} kunskapspoäng',
    if (card.progressPoints > 0)
      '${card.progressPoints} framstegspoäng',
    if (card.victoryPoints > 0) '${card.victoryPoints} segerpoäng',
  ];
  if (parts.isEmpty) return null;
  if (parts.length == 1) return parts.first;
  return '${parts.sublist(0, parts.length - 1).join(', ')} och ${parts.last}';
}

/// Bekräftelsekortet som visas ovanpå motståndarens rike när ett kort
/// släpps på en giltig plats – inte en modal dialogruta, utan en vanlig
/// widget som läggs ovanpå motståndarens (inte ditt eget) rike, så att
/// dina egna regioners +/- knappar fortfarande går att trycka på medan
/// den syns, och den stängs aldrig av misstag genom att man trycker
/// utanför.
///
/// Appen håller inte koll på om spelaren har råd (regelhäftet s. 9:
/// spelarna betalar och tar resurser själva) – kortet visar bara
/// kostnaden och påminner om att betala genom att trycka − på
/// respektive resurs, sedan avgör spelaren själv med "Betalt" eller
/// "Avbryt". Kortet byggs bara om "Betalt" trycks; "Avbryt" struntar
/// helt i draget.
///
/// Om [blockedReason] är satt (se
/// [GameNotifier.buildRequirementBlockedReason]/`build_requirements.dart`
/// – t.ex. Guldgömma utan hjälte, en stadsutbyggnad på en vanlig by)
/// visas i stället BARA den förklarande texten (samma stil som
/// card_detail_dialog.dart:s `blockedReason`) och en "Stäng"-knapp –
/// draget landade (så spelaren FÅR en förklaring, i stället för att
/// kortet bara studsar tillbaka utan förklaring), men går inte att
/// bekräfta.
class BuildConfirmCard extends StatelessWidget {
  final GameCard card;

  /// Satt bara när platsen redan har ett bygg-/enhets-/skeppskort (se
  /// [PrincipalityGrid]s `onRequestBuildConfirm`) – man får byta ut det
  /// mot [card] i stället för att bygget avvisas: fortfarande [card]s
  /// fulla kostnad (ingen rabatt), och [replacedCard] hamnar i
  /// slänghögen (se [GameNotifier.dropExpansion]).
  final GameCard? replacedCard;

  final String? blockedReason;

  /// En kort påminnelsetext om en byggeffekt som sänker KOSTNADEN (t.ex.
  /// Övningsplats: "betala 1 valfri resurs mindre" för en hjälte) –
  /// visas HÄR, bredvid den faktiska kostnaden, i stället för som en
  /// SnackBar EFTER att spelaren redan betalat/byggt (rapporterad bugg:
  /// för sent för att faktiskt påverka vad spelaren betalar). Precis
  /// som resten av kostnaden dras den aldrig av automatiskt – appen
  /// håller inte koll på om spelaren har råd, se klassdoc. `null` när
  /// ingen sådan rabatt gäller.
  final String? costReminder;

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BuildConfirmCard({
    super.key,
    required this.card,
    this.replacedCard,
    this.blockedReason,
    this.costReminder,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final pointsPhrase = _pointsPhrase(card);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: 10,
          // Motståndarens rike (där kortet läggs, se game_board_screen.dart)
          // kan vara ganska lågt på vissa skärmar, särskilt i liggande
          // läge – bilden ligger därför bredvid texten (inte ovanpå) för
          // att hålla höjden nere, och SingleChildScrollView är kvar som
          // en extra säkerhet så att Betalt/Avbryt-knapparna aldrig blir
          // otillgängliga, bara kräver en skroll i värsta fall.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Image.asset(
                          CatanAssets.resolveCardImage(card),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: CatanColors.woodFrame),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Du har valt att ${_actionPhrase(card)}.',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: CatanColors.ink),
                          ),
                          if (pointsPhrase != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Ger $pointsPhrase.',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: CatanColors.ink),
                            ),
                          ],
                          if (replacedCard != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Ersätter ${replacedCard!.name}, som läggs i slänghögen.',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: CatanColors.ink),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (blockedReason != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CatanColors.parchmentDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CatanColors.woodFrame),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: CatanColors.ink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            blockedReason!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: CatanColors.ink,
                                height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: CatanColors.ink,
                          side: const BorderSide(color: CatanColors.woodFrame)),
                      onPressed: onCancel,
                      child: const Text('Stäng'),
                    ),
                  ),
                ] else ...[
                  if (card.buildingCost.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Betala genom att trycka − på respektive resurs:',
                      style: TextStyle(fontSize: 11.5, color: CatanColors.ink),
                    ),
                    if (costReminder != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        costReminder!,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: CatanColors.ink),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final entry in card.buildingCost.entries)
                          _CostBadge(type: entry.key, amount: entry.value),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: CatanColors.ink,
                              side: const BorderSide(color: CatanColors.woodFrame)),
                          onPressed: onCancel,
                          child: const Text('Avbryt'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4F6F45)),
                          onPressed: onConfirm,
                          child: const Text('Betalt'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CostBadge extends StatelessWidget {
  final ResourceType type;
  final int amount;

  const _CostBadge({required this.type, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: CatanColors.parchmentDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CatanColors.woodFrame),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.asset(
              CatanAssets.resourceCostIcon(type),
              width: 18,
              height: 18,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                  width: 18, height: 18, color: CatanColors.resourceColor(type)),
            ),
          ),
          const SizedBox(width: 5),
          Text('×$amount',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, color: CatanColors.ink)),
        ],
      ),
    );
  }
}
