import 'package:flutter/material.dart';

import '../../data/basic_set_cards.dart';
import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Visas i stället för [EventCardRevealCard] när det uppslagna
/// händelsekortet är Fejd eller Brödrafejd (se
/// [GameNotifier.strengthAdvantagePlayerId]) – båda kräver att man
/// vet vem som har styrkeövertaget innan man vet vad som ska göras.
///
/// Fejd rör bara den utan övertaget (tar bort en av sina egna
/// byggnader), vilket alltid går att göra interaktivt – riktig
/// bygg-väljare (se [onStartFeudPick]) i stället för en
/// påminnelsetext. Brödrafejd rör motståndarens hand, vilket är
/// interaktivt både lokalt och online (se [onStartFraternalFeudsPick] –
/// lokalt muteras motståndarens hand direkt, online skickas en
/// [FraternalFeudsRequest] som motståndarens klient tillämpar på sig
/// själv, se GameNotifier.pickFraternalFeudsCard) – bara den UTAN
/// övertaget ser i stället en ren påminnelsetext, precis som andra
/// händelsekort.
class FeudResolutionCard extends StatelessWidget {
  final GameCard card;
  final bool isTie;
  final bool youHaveAdvantage;
  final String opponentName;

  /// Om den utan styrkeövertaget faktiskt har en byggnad (inte
  /// skepp/hjältar) att ta bort – bara relevant för Fejd (se
  /// [RealmBoard.hasAnyBuilding]). Utan kontrollen skulle Fejd be om
  /// ett val som inte går att göra när det riket bara har skepp/
  /// hjältar/ingenting utplacerat.
  final bool hasBuildingToRemove;

  /// Om motståndaren (den vars hand det gäller) faktiskt har minst 1
  /// kort på handen att välja bland – bara relevant för Brödrafejd (se
  /// [GameNotifier.startFraternalFeudsPick]). Utan kontrollen skulle
  /// Brödrafejd be om ett val som inte går att göra när motståndarens
  /// hand redan är tom, precis som [hasBuildingToRemove] gör för Fejd
  /// (rapporterad bugg: spelaren fastnade i väljaren utan att kunna
  /// avsluta den).
  final bool hasCardsToPick;

  /// Om DU (den drabbade sidan, dvs. utan styrkeövertaget) redan spelat
  /// Sebastian, den vandrande predikanten mot just det här kortet (se
  /// [GameNotifier.playSebastianForCurrentEvent]/
  /// TurnState.sebastianProtectedPlayerIds-doc) – ersätter i så fall
  /// hela instruktionen med en skyddad-text och en enkel OK-knapp.
  final bool youProtected;

  /// Om MOTSTÅNDAREN (den drabbade sidan) redan spelat Sebastian – bara
  /// relevant när DU har övertaget, se [youProtected].
  final bool opponentProtected;

  /// Om Sebastian går att spela just nu: du är den drabbade sidan (utan
  /// övertaget, inget oavgjort), har kortet på handen, och har inte
  /// redan skyddat dig.
  final bool canPlaySebastian;

  final VoidCallback onDismiss;
  final VoidCallback onStartFeudPick;
  final VoidCallback onStartFraternalFeudsPick;
  final VoidCallback onPlaySebastian;

  const FeudResolutionCard({
    super.key,
    required this.card,
    required this.isTie,
    required this.youHaveAdvantage,
    required this.opponentName,
    required this.hasBuildingToRemove,
    this.hasCardsToPick = true,
    this.youProtected = false,
    this.opponentProtected = false,
    this.canPlaySebastian = false,
    required this.onDismiss,
    required this.onStartFeudPick,
    required this.onStartFraternalFeudsPick,
    required this.onPlaySebastian,
  });

  bool get _isFraternalFeuds => card.baseId == BasicSetCards.fraternalFeuds.id;

  String get _advantageLine {
    if (isTie) return 'Oavgjort – ingen spelare har styrkeövertaget.';
    return youHaveAdvantage
        ? 'Du har styrkeövertaget.'
        : '$opponentName har styrkeövertaget.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: 10,
          // Motståndarens rike (där kortet visas, se game_board_screen.dart)
          // kan vara ganska lågt på vissa skärmar – till skillnad från
          // EventCardRevealCard behöver den här rutan plats för både
          // styrkeövertags-raden och en knapp, så en stor kvadratisk bild
          // ovanpå texten (som gjorde att knappen kunde hamna utanför
          // synligt område, särskilt för Brödrafejds längre instruktion)
          // skulle lätt bli för hög. Bilden ligger i stället som en liten
          // miniatyr bredvid texten, precis som BuildConfirmCard löser
          // samma problem. SingleChildScrollView är kvar som en extra
          // säkerhet så att knappen aldrig blir otillgänglig, bara kräver
          // en skroll i värsta fall.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
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
                            card.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: CatanColors.ink),
                          ),
                          if (card.effectText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              card.effectText!,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: CatanColors.ink,
                                  height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _advantageLine,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  _instructionText,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F6F45)),
                  onPressed: _primaryAction,
                  child: Text(_primaryButtonLabel),
                ),
                if (canPlaySebastian) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: CatanColors.ink,
                        side: const BorderSide(color: CatanColors.woodFrame)),
                    onPressed: onPlaySebastian,
                    child: const Text(
                        'Spela Sebastian, den vandrande predikanten (skydda dig)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _instructionText {
    if (isTie) return 'Inget händer.';
    if (youProtected) {
      return 'Du spelade Sebastian, den vandrande predikanten – '
          'gäller inte dig. Inget händer.';
    }
    if (youHaveAdvantage && opponentProtected) {
      return '$opponentName spelade Sebastian, den vandrande predikanten – '
          'gäller inte hen. Inget händer.';
    }
    if (!_isFraternalFeuds) {
      // Fejd: gäller den utan övertaget.
      if (!hasBuildingToRemove) {
        return youHaveAdvantage
            ? '$opponentName har inga byggnader att ta bort. Inget händer.'
            : 'Du har inga byggnader att ta bort. Inget händer.';
      }
      return youHaveAdvantage
          ? 'Berätta för $opponentName vilka 3 byggnader hen får välja '
              'mellan – hen väljer sedan vilken som ska bort på sin skärm.'
          : 'Välj en av dina egna byggnader (inte skepp eller hjältar) '
              'att ta bort.';
    }
    // Brödrafejd: gäller den med övertaget.
    if (!hasCardsToPick) {
      return youHaveAdvantage
          ? '$opponentName har inga kort på handen. Inget händer.'
          : 'Din hand är tom. Inget händer.';
    }
    return youHaveAdvantage
        ? 'Titta i $opponentName' 's hand och välj 2 kort (färre om '
            'motståndaren har mindre än 2) att lägga underst i valfria '
            'draghögar.'
        : '$opponentName väljer 2 kort (färre om du har mindre än 2) '
            'från din hand att lägga underst i valfria draghögar.';
  }

  String get _primaryButtonLabel {
    if (isTie || youProtected || (youHaveAdvantage && opponentProtected)) {
      return 'OK';
    }
    if (!_isFraternalFeuds && !youHaveAdvantage && hasBuildingToRemove) {
      return 'Välj byggnad';
    }
    if (_isFraternalFeuds && youHaveAdvantage && hasCardsToPick) {
      return 'Välj kort';
    }
    return 'OK';
  }

  VoidCallback get _primaryAction {
    if (isTie || youProtected || (youHaveAdvantage && opponentProtected)) {
      return onDismiss;
    }
    if (!_isFraternalFeuds && !youHaveAdvantage && hasBuildingToRemove) {
      return onStartFeudPick;
    }
    if (_isFraternalFeuds && youHaveAdvantage && hasCardsToPick) {
      return onStartFraternalFeudsPick;
    }
    return onDismiss;
  }
}
