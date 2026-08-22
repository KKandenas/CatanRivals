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
/// påminnelsetext. Brödrafejd rör motståndarens hand, vilket bara går
/// att göra interaktivt i lokalt läge (se [isOnline]/
/// [onStartFraternalFeudsPick]) – annars (och när det är motståndaren
/// som har övertaget) visas bara en påminnelsetext, precis som andra
/// händelsekort.
class FeudResolutionCard extends StatelessWidget {
  final GameCard card;
  final bool isTie;
  final bool youHaveAdvantage;
  final bool isOnline;
  final String opponentName;
  final VoidCallback onDismiss;
  final VoidCallback onStartFeudPick;
  final VoidCallback onStartFraternalFeudsPick;

  const FeudResolutionCard({
    super.key,
    required this.card,
    required this.isTie,
    required this.youHaveAdvantage,
    required this.isOnline,
    required this.opponentName,
    required this.onDismiss,
    required this.onStartFeudPick,
    required this.onStartFraternalFeudsPick,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      CatanAssets.resolveCardImage(card),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: CatanColors.woodFrame),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 36, 14, 12),
                          child: Text(
                            card.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (card.effectText != null) ...[
                      Text(
                        card.effectText!,
                        style: const TextStyle(
                            fontSize: 13, color: CatanColors.ink, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                    ],
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _instructionText {
    if (isTie) return 'Inget händer.';
    if (!_isFraternalFeuds) {
      // Fejd: gäller den utan övertaget.
      return youHaveAdvantage
          ? 'Berätta för $opponentName vilka 3 byggnader hen får välja '
              'mellan – hen väljer sedan vilken som ska bort på sin skärm.'
          : 'Välj en av dina egna byggnader (inte skepp eller hjältar) '
              'att ta bort.';
    }
    // Brödrafejd: gäller den med övertaget.
    if (!isOnline && youHaveAdvantage) {
      return 'Titta i $opponentName' 's hand och välj 2 kort att lägga '
          'underst i valfria draghögar.';
    }
    return youHaveAdvantage
        ? 'Titta i $opponentName' 's hand och välj 2 kort att lägga '
            'underst i valfria draghögar.'
        : '$opponentName väljer 2 kort från din hand att lägga underst i '
            'valfria draghögar.';
  }

  String get _primaryButtonLabel {
    if (isTie) return 'OK';
    if (!_isFraternalFeuds && !youHaveAdvantage) return 'Välj byggnad';
    if (_isFraternalFeuds && !isOnline && youHaveAdvantage) {
      return 'Välj kort';
    }
    return 'OK';
  }

  VoidCallback get _primaryAction {
    if (isTie) return onDismiss;
    if (!_isFraternalFeuds && !youHaveAdvantage) return onStartFeudPick;
    if (_isFraternalFeuds && !isOnline && youHaveAdvantage) {
      return onStartFraternalFeudsPick;
    }
    return onDismiss;
  }
}
