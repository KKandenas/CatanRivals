import 'package:flutter/material.dart';

import '../../data/basic_set_cards.dart';
import '../../models/models.dart';
import '../../state/game_state.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';

/// Mittremsan mellan de två rikena: dragstaplarna (vägar/byar/städer/
/// regioner), händelsekortsstapeln, och "Avsluta action-fas"-knappen –
/// precis som i det fysiska spelets uppställning, där dessa ligger
/// mellan de två furstendömena (se regelhäftet s. 5). Vems tur det är
/// visas bara i den breda bannern högst upp (se game_board_screen.dart)
/// – ingen egen turindikator här. Produktionstärningen sitter inte här
/// längre – den står till höger om motståndarens rike (se
/// [DiceRollButton] i game_board_screen.dart) för att lämna så mycket
/// höjd som möjligt åt själva korten.
///
/// Vägar/byar/städer går att långtrycka-och-dra ut på det egna riket
/// för att bygga direkt från stapeln, precis som i det fysiska spelet
/// (regelhäftet s. 8: "you can build any available road or settlement
/// center card directly by paying the building costs"). Region- och
/// händelsestaplarna är inte dragbara – regioner delas ut automatiskt
/// när en ny by byggs, och händelsekort dras vid tärningsslag. De fyra
/// vanliga draghögarna (`draw1`–`draw4`) används både för starthands-
/// valet och för handjusteringen i slutet av varje action-fas (se
/// [HandAdjustmentPhase]): dra-läget gör dem tryckbara för att dra ett
/// kort, släng-läget för att slänga det valda handkortet till botten
/// av högen. `stackCounts` är mock-data tills en riktig
/// dragstapel-modell finns.
class CenterStacksStrip extends StatelessWidget {
  final Map<String, int> stackCounts;
  final bool isYourTurn;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  /// Starthandsvalet (regelhäftet s. 6): om `true` går draghögarna att
  /// trycka på (i stället för att dra korten) för att välja hög och ta
  /// dess 3 översta kort som starthand – bara när det är ens egen tur
  /// ([isMyTurnToChooseHand]) och högen inte redan är vald.
  final bool isChoosingHand;
  final bool isMyTurnToChooseHand;
  final void Function(int stackIndex)? onChooseStack;

  /// Om tärningen redan är slagen den här omgången – styr om
  /// "Avsluta action-fas" visas.
  final bool diceRolled;
  final VoidCallback? onEndTurn;

  /// Handjustering i slutet av action-fasen (regelhäftet s. 9) – se
  /// [HandAdjustmentPhase]. Under [HandAdjustmentPhase.drawing] går var
  /// och en av de fyra draghögarna att trycka på för att dra ett kort
  /// ([onDrawStack]); under [HandAdjustmentPhase.discarding] går de att
  /// trycka på för att slänga det just valda handkortet dit
  /// ([onDiscardToStack], bara aktiv när [hasSelectedDiscardCard]).
  final HandAdjustmentPhase handAdjustmentPhase;
  final int handCount;
  final int handLimit;
  final void Function(int stackIndex)? onDrawStack;
  final void Function(int stackIndex)? onDiscardToStack;
  final bool hasSelectedDiscardCard;

  /// Kortbytesfasen (regelhäftet s. 9) – se [TradePhase]. Under
  /// [TradePhase.exchangeDiscard] går högarna att trycka på för att
  /// slänga det valda handkortet dit ([onExchangeDiscardToStack], bara
  /// aktiv när [hasSelectedExchangeCard]); under
  /// [TradePhase.exchangeDraw] för att dra ett kort ([onExchangeDrawStack]);
  /// under [TradePhase.peekChoosingStack] för att slå upp hela högen
  /// ([onPeekStack]).
  final TradePhase tradePhase;
  final void Function(int stackIndex)? onExchangeDiscardToStack;
  final void Function(int stackIndex)? onExchangeDrawStack;
  final void Function(int stackIndex)? onPeekStack;
  final bool hasSelectedExchangeCard;

  const CenterStacksStrip({
    super.key,
    required this.stackCounts,
    this.isYourTurn = true,
    this.onDragStarted,
    this.onDragEnd,
    this.isChoosingHand = false,
    this.isMyTurnToChooseHand = false,
    this.onChooseStack,
    this.diceRolled = false,
    this.onEndTurn,
    this.handAdjustmentPhase = HandAdjustmentPhase.none,
    this.handCount = 0,
    this.handLimit = 3,
    this.onDrawStack,
    this.onDiscardToStack,
    this.hasSelectedDiscardCard = false,
    this.tradePhase = TradePhase.none,
    this.onExchangeDiscardToStack,
    this.onExchangeDrawStack,
    this.onPeekStack,
    this.hasSelectedExchangeCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CatanColors.woodFrameDark,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StackPile(
                  asset: CatanAssets.road,
                  count: stackCounts['roads'] ?? 0,
                  card: BasicSetCards.road,
                  onDragStarted: onDragStarted,
                  onDragEnd: onDragEnd,
                  width: 48,
                ),
                _StackPile(
                  asset: CatanAssets.backSettlements,
                  count: stackCounts['settlements'] ?? 0,
                  card: BasicSetCards.settlement,
                  onDragStarted: onDragStarted,
                  onDragEnd: onDragEnd,
                  width: 48,
                ),
                _StackPile(
                  asset: CatanAssets.backCities,
                  count: stackCounts['cities'] ?? 0,
                  card: BasicSetCards.city,
                  onDragStarted: onDragStarted,
                  onDragEnd: onDragEnd,
                  width: 48,
                ),
                _StackPile(
                    asset: CatanAssets.backRegions,
                    count: stackCounts['regions'] ?? 0,
                    width: 48),
                for (var i = 0; i < 4; i++) _drawStackPile(i),
                _StackPile(
                    asset: CatanAssets.backEvent,
                    count: stackCounts['event'] ?? 0,
                    width: 48),
              ],
            ),
          ),
          if (isYourTurn && diceRolled && !isChoosingHand) ...[
            const SizedBox(width: 8),
            if (handAdjustmentPhase == HandAdjustmentPhase.none &&
                tradePhase == TradePhase.none)
              _EndTurnButton(onTap: onEndTurn)
            else if (handAdjustmentPhase != HandAdjustmentPhase.none)
              _HandAdjustmentLabel(
                  phase: handAdjustmentPhase, count: handCount, limit: handLimit),
            // Under kortbytesfasen visas instruktionerna i stället i
            // TradePhaseCard (se game_board_screen.dart) – ingen egen
            // etikett här, bara högarna som tänds till.
          ],
        ],
      ),
    );
  }

  Widget _drawStackPile(int index) {
    final count = stackCounts['draw${index + 1}'] ?? 0;
    final claimed = count < 9;

    if (handAdjustmentPhase == HandAdjustmentPhase.drawing) {
      final tappable = count > 0;
      return _StackPile(
        asset: CatanAssets.backBasicSet,
        count: count,
        width: 48,
        dimmed: !tappable,
        highlighted: tappable,
        onTap: tappable ? () => onDrawStack?.call(index) : null,
      );
    }
    if (handAdjustmentPhase == HandAdjustmentPhase.discarding) {
      return _StackPile(
        asset: CatanAssets.backBasicSet,
        count: count,
        width: 48,
        highlighted: hasSelectedDiscardCard,
        onTap: hasSelectedDiscardCard ? () => onDiscardToStack?.call(index) : null,
      );
    }
    if (tradePhase == TradePhase.exchangeDiscard) {
      return _StackPile(
        asset: CatanAssets.backBasicSet,
        count: count,
        width: 48,
        highlighted: hasSelectedExchangeCard,
        onTap: hasSelectedExchangeCard
            ? () => onExchangeDiscardToStack?.call(index)
            : null,
      );
    }
    if (tradePhase == TradePhase.exchangeDraw) {
      final tappable = count > 0;
      return _StackPile(
        asset: CatanAssets.backBasicSet,
        count: count,
        width: 48,
        dimmed: !tappable,
        highlighted: tappable,
        onTap: tappable ? () => onExchangeDrawStack?.call(index) : null,
      );
    }
    if (tradePhase == TradePhase.peekChoosingStack) {
      final tappable = count > 0;
      return _StackPile(
        asset: CatanAssets.backBasicSet,
        count: count,
        width: 48,
        dimmed: !tappable,
        highlighted: tappable,
        onTap: tappable ? () => onPeekStack?.call(index) : null,
      );
    }

    final tappable = isChoosingHand && isMyTurnToChooseHand && !claimed;
    return _StackPile(
      asset: CatanAssets.backBasicSet,
      count: count,
      width: 48,
      dimmed: isChoosingHand && claimed,
      highlighted: tappable,
      onTap: tappable ? () => onChooseStack?.call(index) : null,
    );
  }
}

class _StackPile extends StatelessWidget {
  final String asset;
  final int count;
  final double width;

  /// Kortmall att dra (t.ex. [BasicSetCards.road]). `null` = ej dragbar
  /// stapel (regioner, draghögar, händelse).
  final GameCard? card;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  /// Tryckbar (i stället för dragbar) – används av draghögarna under
  /// starthandsvalet.
  final VoidCallback? onTap;

  /// Grön glöd, samma stil som de dragbara högarna – visar att den här
  /// högen går att trycka på just nu.
  final bool highlighted;

  /// Nedtonad – en redan vald draghög under starthandsvalet.
  final bool dimmed;

  const _StackPile({
    required this.asset,
    required this.count,
    this.width = 40,
    this.card,
    this.onDragStarted,
    this.onDragEnd,
    this.onTap,
    this.highlighted = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final glowing = card != null || highlighted;
    final pile = AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color:
                    glowing ? const Color(0xFF7CBF6A) : CatanColors.woodFrame,
                width: glowing ? 1.6 : 1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(asset, fit: BoxFit.cover),
              Positioned(
                right: 2,
                bottom: 2,
                child: _CountBadge(count: count),
              ),
            ],
          ),
        ),
      ),
    );
    final dimmedPile = dimmed ? Opacity(opacity: 0.4, child: pile) : pile;

    final content = onTap != null
        ? GestureDetector(onTap: onTap, child: dimmedPile)
        : card != null && count > 0
            ? LongPressDraggable<GameCard>(
                data: card,
                delay: const Duration(milliseconds: 180),
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                      width: width,
                      child: Transform.scale(scale: 1.3, child: pile)),
                ),
                childWhenDragging: Opacity(opacity: 0.35, child: pile),
                onDragStarted: () => onDragStarted?.call(card!),
                onDragEnd: (_) => onDragEnd?.call(),
                // Ett riktigt fingertryck varar ofta längre än 180ms,
                // så LongPressDraggable hinner vinna gest-arenan innan
                // ett vanligt tryck hade fått chansen – utan det här
                // skulle den här högen inte gå att trycka på alls.
                // Släpps kortet utan att träffa ett giltigt mål tolkar
                // vi det som ett tryck och visar kortet förstorat.
                onDraggableCanceled: (_, __) {
                  onDragEnd?.call();
                  showCardDetail(context, card!);
                },
                child: pile,
              )
            // Tom hög (t.ex. slut på städer) – fortfarande tryckbar
            // för att kunna se kostnaden, bara inte dragbar.
            : card != null
                ? GestureDetector(
                    onTap: () => showCardDetail(context, card!),
                    child: dimmedPile)
                : dimmedPile;

    return SizedBox(width: width, child: content);
  }
}

/// Antalet kort kvar i högen – en liten badge ovanpå kortbilden i
/// stället för en textrad under, så att själva högarna kan göras
/// större utan att remsan växer i höjd.
class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EndTurnButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _EndTurnButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF7CBF6A),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Avsluta action-fas',
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Visas i stället för "Avsluta action-fas" medan handjusteringen
/// pågår – talar om vad spelaren ska göra och hur långt kvar det är
/// (t.ex. "Dra kort: 2/4" eller "Släng kort: 5/4").
class _HandAdjustmentLabel extends StatelessWidget {
  final HandAdjustmentPhase phase;
  final int count;
  final int limit;

  const _HandAdjustmentLabel(
      {required this.phase, required this.count, required this.limit});

  @override
  Widget build(BuildContext context) {
    final label = phase == HandAdjustmentPhase.drawing
        ? 'Dra kort: $count/$limit'
        : 'Släng kort: $count/$limit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7CBF6A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
