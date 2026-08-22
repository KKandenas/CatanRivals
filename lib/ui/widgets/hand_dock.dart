import 'package:flutter/material.dart';

import '../../data/basic_set_cards.dart';
import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';
import 'score_summary.dart';

/// Bottenfältet (~10%): halvtransparent docka med handkort samt
/// spelarens aktuella ställning (VP och poäng).
///
/// Bygg-/enhetskort (kategori [CardCategory.expansion]) går att
/// långtrycka-och-dra upp på det egna riket för att spela dem – se
/// [PrincipalityGrid]. Handlingskort (kategori [CardCategory.action])
/// är inte dragbara – de spelas med regelhäftets "tvåstegsraket": ett
/// tryck förstorar kortet ([showCardDetail]), som då frågar "Vill du
/// använda kortet?" (se [onUseActionCard]). Undantaget är Spejare
/// (regelhäftets "action-scout"), som bara går att använda i samma
/// stund som en ny by byggs – den frågan visas i stället automatiskt
/// då (se GameNotifier.dropSettlement), så ett tryck på Spejare i
/// handen visar bara det vanliga, rena kortförstoringsläget.
class HandDock extends StatelessWidget {
  final Player player;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  /// Anropas när spelaren bekräftar "Vill du använda kortet?" för ett
  /// handlingskort (utom Spejare, se klassdoc). Notifiern avgör själv
  /// vad "använda" innebär för respektive kort.
  final void Function(GameCard card)? onUseActionCard;

  /// Handjustering i slutet av action-fasen (se [HandAdjustmentPhase.
  /// discarding]): om satt går varje handkort (oavsett kategori) att
  /// trycka på för att välja det att slänga i stället för att förstora
  /// det – normal dra-för-att-bygga är avstängd medan det här pågår.
  final GameCard? selectedDiscardCard;
  final void Function(GameCard card)? onSelectForDiscard;

  /// Totalpoäng och brickinnehav (se [ScoreSummary]) – räknas ut i
  /// [GameState], inte i den här rent presentationslagret-widgeten.
  final int totalVictoryPoints;
  final bool hasHeroToken;
  final bool hasTradeToken;

  const HandDock({
    super.key,
    required this.player,
    this.onDragStarted,
    this.onDragEnd,
    this.onUseActionCard,
    this.selectedDiscardCard,
    this.onSelectForDiscard,
    required this.totalVictoryPoints,
    this.hasHeroToken = false,
    this.hasTradeToken = false,
  });

  /// Exponerad så TotalScoreBoard kan placera sig ovanför dockan i
  /// stället för att skarva ihop med dess egen ScoreSummary-ruta i
  /// samma hörn.
  static const double dockHeight = 92;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: dockHeight,
      color: CatanColors.woodFrameDark.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: player.hand.isEmpty
                    ? const Center(
                        child: Text('Inga handkort',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: player.hand.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => _HandCard(
                          card: player.hand[i],
                          onDragStarted: onDragStarted,
                          onDragEnd: onDragEnd,
                          onUseActionCard: onUseActionCard,
                          selected: player.hand[i] == selectedDiscardCard,
                          onSelectForDiscard: onSelectForDiscard == null
                              ? null
                              : () => onSelectForDiscard!(player.hand[i]),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              ScoreSummary(
                player: player,
                totalVictoryPoints: totalVictoryPoints,
                hasHeroToken: hasHeroToken,
                hasTradeToken: hasTradeToken,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandCard extends StatelessWidget {
  final GameCard card;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;
  final void Function(GameCard card)? onUseActionCard;
  final bool selected;
  final VoidCallback? onSelectForDiscard;

  const _HandCard({
    required this.card,
    this.onDragStarted,
    this.onDragEnd,
    this.onUseActionCard,
    this.selected = false,
    this.onSelectForDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final playable = card.category == CardCategory.expansion;
    // Spejare undantas: den frågas automatiskt vid by-bygge i stället
    // (se klassdocen på [HandDock]), inte via ett tryck i handen.
    final isUsableAction = card.category == CardCategory.action &&
        card.baseId != BasicSetCards.scout.id;

    // Under handjusteringen (slänga kort) går varje kort – oavsett
    // kategori – bara att trycka på för att välja det, ingen dra-för-
    // att-bygga: det är inte läge att bygga mitt i handjusteringen.
    if (onSelectForDiscard != null) {
      return _CardFace(
          card: card,
          playable: playable,
          selected: selected,
          onTap: onSelectForDiscard);
    }

    final useActionTap = isUsableAction && onUseActionCard != null
        ? () => showCardDetail(context, card,
            onUseCard: () => onUseActionCard!(card))
        : null;

    final face =
        _CardFace(card: card, playable: playable, onTap: useActionTap);

    if (!playable) return face;

    return LongPressDraggable<GameCard>(
      data: card,
      delay: const Duration(milliseconds: 180),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
            scale: 1.12, child: _CardFace(card: card, playable: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: face),
      onDragStarted: () => onDragStarted?.call(card),
      onDragEnd: (_) => onDragEnd?.call(),
      // En riktig fingertryck varar ofta längre än 180ms, så
      // LongPressDraggable hinner vinna gest-arenan (och starta en
      // "drag") innan ett vanligt tryck (ExpansionCardViews egen
      // GestureDetector) någonsin får chansen – annars skulle
      // dragbara handkort inte gå att trycka på alls. Släpps kortet
      // sedan utan att träffa ett giltigt mål (dvs. draget avbryts),
      // tolkar vi det som ett tryck och visar kortet förstorat.
      onDraggableCanceled: (_, __) {
        onDragEnd?.call();
        showCardDetail(context, card);
      },
      child: face,
    );
  }
}

class _CardFace extends StatelessWidget {
  final GameCard card;
  final bool playable;
  final bool selected;
  final VoidCallback? onTap;

  const _CardFace({
    required this.card,
    required this.playable,
    this.selected = false,
    this.onTap,
  });

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExpansionCardView(card: card, showCost: playable, onTap: onTap),
          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.redAccent, width: 2.4),
              ),
            )
          else if (playable)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF7CBF6A), width: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}
