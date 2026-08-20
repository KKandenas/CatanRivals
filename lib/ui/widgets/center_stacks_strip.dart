import 'package:flutter/material.dart';

import '../../data/basic_set_cards.dart';
import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Mittremsan mellan de två rikena: dragstaplarna (vägar/byar/städer/
/// regioner), händelsekortsstapeln, tärningsslaget och turindikatorn –
/// precis som i det fysiska spelets uppställning, där dessa ligger
/// mellan de två furstendömena (se regelhäftet s. 5).
///
/// Vägar/byar/städer går att långtrycka-och-dra ut på det egna riket
/// för att bygga direkt från stapeln, precis som i det fysiska spelet
/// (regelhäftet s. 8: "you can build any available road or settlement
/// center card directly by paying the building costs"). Region- och
/// händelsestaplarna är inte dragbara – regioner delas ut automatiskt
/// när en ny by byggs, och händelsekort dras vid tärningsslag.
/// `stackCounts` är mock-data tills en riktig dragstapel-modell finns.
class CenterStacksStrip extends StatelessWidget {
  final Map<String, int> stackCounts;
  final int lastProductionRoll;
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

  const CenterStacksStrip({
    super.key,
    required this.stackCounts,
    this.lastProductionRoll = 6,
    this.isYourTurn = true,
    this.onDragStarted,
    this.onDragEnd,
    this.isChoosingHand = false,
    this.isMyTurnToChooseHand = false,
    this.onChooseStack,
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
                _StackPile(asset: CatanAssets.backRegions, count: stackCounts['regions'] ?? 0, width: 48),
                for (var i = 0; i < 4; i++) _drawStackPile(i),
                _StackPile(asset: CatanAssets.backEvent, count: stackCounts['event'] ?? 0, width: 48),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _DiceBadge(value: lastProductionRoll),
          const SizedBox(width: 8),
          _TurnIndicator(isYourTurn: isYourTurn),
        ],
      ),
    );
  }

  Widget _drawStackPile(int index) {
    final count = stackCounts['draw${index + 1}'] ?? 0;
    final claimed = count < 9;
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
            border: Border.all(color: glowing ? const Color(0xFF7CBF6A) : CatanColors.woodFrame, width: glowing ? 1.6 : 1),
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
                  child: SizedBox(width: width, child: Transform.scale(scale: 1.3, child: pile)),
                ),
                childWhenDragging: Opacity(opacity: 0.35, child: pile),
                onDragStarted: () => onDragStarted?.call(card!),
                onDragEnd: (_) => onDragEnd?.call(),
                onDraggableCanceled: (_, __) => onDragEnd?.call(),
                child: pile,
              )
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
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DiceBadge extends StatelessWidget {
  final int value;

  const _DiceBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: CatanColors.parchment,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1))],
      ),
      alignment: Alignment.center,
      child: Text('$value', style: const TextStyle(color: CatanColors.ink, fontWeight: FontWeight.bold)),
    );
  }
}

class _TurnIndicator extends StatelessWidget {
  final bool isYourTurn;

  const _TurnIndicator({required this.isYourTurn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isYourTurn ? const Color(0xFF4F6F45) : Colors.black26,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isYourTurn ? 'Din tur' : 'Motst.',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
