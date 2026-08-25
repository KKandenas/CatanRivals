import 'package:flutter/material.dart';

import '../../data/basic_set_cards.dart';
import '../../models/models.dart';
import '../../state/game_state.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';

/// Mittremsan mellan de två rikena: dragstaplarna (vägar/byar/städer)
/// och händelsekortsstapeln – precis som i det fysiska spelets
/// uppställning, där dessa ligger mellan de två furstendömena (se
/// regelhäftet s. 5). Vems tur det är, och åtgärdsknappen "Avsluta
/// action-fas"/handjusteringens läge/kikande-etiketten, visas i
/// stället uppe vid "DIN TUR"-bannern (se [TurnActionPill] i
/// game_board_screen.dart) – flyttades dit för att lämna mer plats åt
/// själva korten här, särskilt med fler draghögar när ett temaset är
/// aktivt (se [ExpansionSet]). Regionstapeln visas inte alls längre –
/// den är inte tryckbar/dragbar (regioner delas ut automatiskt när en
/// ny by byggs) så antalet var bara informativt, och tog upp plats som
/// behövs bättre av draghögarna. Produktionstärningen sitter inte här
/// längre – den står till höger om motståndarens rike (se
/// [DiceRollButton] i game_board_screen.dart) för att lämna så mycket
/// höjd som möjligt åt själva korten.
///
/// Vägar/byar/städer går att långtrycka-och-dra ut på det egna riket
/// för att bygga direkt från stapeln, precis som i det fysiska spelet
/// (regelhäftet s. 8: "you can build any available road or settlement
/// center card directly by paying the building costs"). Händelse-
/// stapeln är inte dragbar – händelsekort dras vid tärningsslag. De
/// fyra vanliga draghögarna (`draw1`–`draw4`) används både för
/// starthands-valet och för handjusteringen i slutet av varje
/// action-fas (se [HandAdjustmentPhase]): dra-läget gör dem tryckbara
/// för att dra ett kort, släng-läget för att slänga det valda
/// handkortet till botten av högen. `stackCounts` är mock-data tills en
/// riktig
/// dragstapel-modell finns.
class CenterStacksStrip extends StatelessWidget {
  final Map<String, int> stackCounts;

  /// Hur många kort respektive draghög startade med (se
  /// [GameState.initialDrawStackSizes]) – både antalet högar som ska
  /// ritas ut (4 utan tema, 5 med Gulderan) och tröskeln för att avgöra
  /// om en hög redan är vald under starthandsvalet härleds ur längden/
  /// värdena här, i stället för att anta exakt 4 högar à 9 kort.
  final List<int> initialStackSizes;

  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  /// Om väg-/by-/stadshögarna går att dra ut på riket just nu (se
  /// [GameState.canBuildRightNow]) – annars bara tryckbara för att
  /// förstora kortet, i stället för att gå att dra ut och mötas av ett
  /// felmeddelande efter "Betalt".
  final bool canBuild;

  /// Starthandsvalet (regelhäftet s. 6): om `true` går draghögarna att
  /// trycka på (i stället för att dra korten) för att välja hög och ta
  /// dess 3 översta kort som starthand – bara när det är ens egen tur
  /// ([isMyTurnToChooseHand]) och högen inte redan är vald.
  final bool isChoosingHand;
  final bool isMyTurnToChooseHand;
  final void Function(int stackIndex)? onChooseStack;

  /// Handjustering i slutet av action-fasen (regelhäftet s. 9) – se
  /// [HandAdjustmentPhase]. Under [HandAdjustmentPhase.drawing] går var
  /// och en av de fyra draghögarna att trycka på för att dra ett kort
  /// ([onDrawStack]); under [HandAdjustmentPhase.discarding] går de att
  /// trycka på för att slänga det just valda handkortet dit
  /// ([onDiscardToStack], bara aktiv när [hasSelectedDiscardCard]).
  final HandAdjustmentPhase handAdjustmentPhase;
  final void Function(int stackIndex)? onDrawStack;
  final void Function(int stackIndex)? onDiscardToStack;
  final bool hasSelectedDiscardCard;

  /// Om det handkort som just nu är valt att slängas (i vilken som
  /// helst av [hasSelectedDiscardCard]/[hasSelectedExchangeCard]s tre
  /// lägen – samma lokala val, se game_board_screen.dart-doc) hör till
  /// det aktiva temasetets egna högar eller grundspelets – styr vilka
  /// högar som faktiskt går att slänga det i (se [_isThemeStack]/
  /// [GameNotifier._checkStackMatchesCardOrigin]): en grundspelskort
  /// får bara läggas i en grundspelshög, ett temakort bara i en av
  /// temasetets egna. `null` när inget kort är valt.
  final bool? selectedDiscardCardIsThemeCard;

  /// Duel of the Princes (6 högar, se [GameState.initialDrawStackSizes]):
  /// vilken EXAKT temahög (3/4/5) det valda kortet hör till – till
  /// skillnad från [selectedDiscardCardIsThemeCard] ovan (som bara vet
  /// "något temaset", tillräckligt när ett enda tema delar på EN
  /// gemensam 2-högspool) räcker inte det längre nu när varje temaset
  /// har sin egen ENSKILDA hög. `null` betyder "inte aktuellt"
  /// (grundspelskort, eller inte duel-läge) – då avgör
  /// [selectedDiscardCardIsThemeCard] som vanligt i stället.
  final int? selectedDiscardCardExactStackIndex;

  /// Vilket tema som är aktivt (se [GameState.activeExpansions]) –
  /// avgör vilken kortbaksbild [_backAssetFor] visar för temasetets
  /// EGNA högar (Gulderan/Oroligheternas tid har olika baksidor, se
  /// [CatanAssets.backEraGold]/[CatanAssets.backEraTurmoil]). Bara ETT
  /// tema är någonsin aktivt åt gången (se [LobbyScreen]).
  final Set<ExpansionSet> activeExpansions;

  /// Kortbytesfasen (regelhäftet s. 9) – se [TradePhase]. Under
  /// [TradePhase.exchangeDiscard] eller [TradePhase.peekDiscard] går
  /// högarna att trycka på för att slänga det valda handkortet dit
  /// ([onExchangeDiscardToStack], bara aktiv när
  /// [hasSelectedExchangeCard]); under [TradePhase.exchangeDraw] för
  /// att dra ett kort ([onExchangeDrawStack]); under
  /// [TradePhase.peekChoosingStack] för att slå upp hela högen
  /// ([onPeekStack]).
  final TradePhase tradePhase;
  final void Function(int stackIndex)? onExchangeDiscardToStack;
  final void Function(int stackIndex)? onExchangeDrawStack;
  final void Function(int stackIndex)? onPeekStack;
  final bool hasSelectedExchangeCard;

  /// Bibliotek (Utvecklingens tid, se [GameState.libraryDrawPending]):
  /// draghögarna görs tryckbara för att dra ett kort, precis som under
  /// [HandAdjustmentPhase.drawing]/[TradePhase.exchangeDraw] – samma
  /// mönster, egen flagga eftersom det kan hända mitt i den vanliga
  /// bygg-/action-fasen (inte bara i handjusteringen/kortbytesfasen).
  final bool libraryDrawPending;
  final void Function(int stackIndex)? onLibraryDrawStack;

  /// Händelsekortsstapeln (se [EventDieFace.eventCard]) går att trycka
  /// på för att dra det översta kortet ([onDrawEventCard]) bara när
  /// tärningen just visade "?" och inget redan är draget den här
  /// omgången.
  final bool canDrawEventCard;
  final VoidCallback? onDrawEventCard;

  /// Vilken av de fyra draghögarna (0–3) motståndaren just nu kikar i
  /// (se [GameState.peekingStackIndex]/[GameNotifier.choosePeekStack])
  /// – `null` annars. Bara index, aldrig vilka kort som ligger där.
  /// Skickas alltid som `null` för den som själv kikar (den spelaren
  /// ser redan hela högen i PeekStackOverlay, se game_board_screen.dart).
  final int? peekingStackIndex;

  const CenterStacksStrip({
    super.key,
    required this.stackCounts,
    this.initialStackSizes = const [9, 9, 9, 9],
    this.onDragStarted,
    this.onDragEnd,
    this.canBuild = true,
    this.isChoosingHand = false,
    this.isMyTurnToChooseHand = false,
    this.onChooseStack,
    this.handAdjustmentPhase = HandAdjustmentPhase.none,
    this.onDrawStack,
    this.onDiscardToStack,
    this.hasSelectedDiscardCard = false,
    this.selectedDiscardCardIsThemeCard,
    this.selectedDiscardCardExactStackIndex,
    this.activeExpansions = const {},
    this.tradePhase = TradePhase.none,
    this.onExchangeDiscardToStack,
    this.onExchangeDrawStack,
    this.onPeekStack,
    this.hasSelectedExchangeCard = false,
    this.libraryDrawPending = false,
    this.onLibraryDrawStack,
    this.canDrawEventCard = false,
    this.onDrawEventCard,
    this.peekingStackIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Lätt genomskinlig (samma mönster som HandDock/TopStatusBar) så
      // den delade träbakgrunden bakom hela brädet syns igenom en
      // aning (se game_board_screen.dart).
      color: CatanColors.woodFrameDark.withValues(alpha: 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StackPile(
            asset: CatanAssets.road,
            count: stackCounts['roads'] ?? 0,
            card: BasicSetCards.road,
            onDragStarted: onDragStarted,
            onDragEnd: onDragEnd,
            canBuild: canBuild,
            width: 48,
          ),
          _StackPile(
            asset: CatanAssets.backSettlements,
            count: stackCounts['settlements'] ?? 0,
            card: BasicSetCards.settlement,
            onDragStarted: onDragStarted,
            onDragEnd: onDragEnd,
            canBuild: canBuild,
            width: 48,
          ),
          _StackPile(
            asset: CatanAssets.backCities,
            count: stackCounts['cities'] ?? 0,
            card: BasicSetCards.city,
            onDragStarted: onDragStarted,
            onDragEnd: onDragEnd,
            canBuild: canBuild,
            width: 48,
          ),
          for (var i = 0; i < initialStackSizes.length; i++) _drawStackPile(i),
          _StackPile(
            asset: CatanAssets.backEvent,
            count: stackCounts['event'] ?? 0,
            width: 48,
            highlighted: canDrawEventCard,
            onTap: canDrawEventCard ? onDrawEventCard : null,
          ),
        ],
      ),
    );
  }

  /// Om draghög [index] är en av det aktiva temasetets EGNA högar (de
  /// sista 2 av 5, se [GameState.initialDrawStackSizes]/
  /// [GameNotifier._isThemeStackIndex]) – styr både vilken kortbaksbild
  /// som visas ([_backAssetFor]) och (tillsammans med
  /// [selectedDiscardCardIsThemeCard]) vilka högar som går att slänga
  /// ett valt handkort i.
  /// I Duel of the Princes-läget (se [GameState.initialDrawStackSizes]
  /// 6-högsfall) har VARJE temaset sin egen ENSKILDA hög (index 3/4/5)
  /// i stället för att dela på 2 gemensamma – "sista 3" räknas då i
  /// stället för "sista 2".
  bool _isThemeStack(int index) {
    if (initialStackSizes.length == 6) return index >= 3;
    return initialStackSizes.length == 5 && index >= initialStackSizes.length - 2;
  }

  String _backAssetFor(int index) {
    if (!_isThemeStack(index)) return CatanAssets.backBasicSet;
    if (initialStackSizes.length == 6) {
      // Duel of the Princes: fast ordning Gulderan/Oroligheternas tid/
      // Utvecklingens tid (index 3/4/5, se DuelOfThePrincesSetup-doc).
      if (index == 3) return CatanAssets.backEraGold;
      if (index == 4) return CatanAssets.backEraTurmoil;
      return CatanAssets.backEraProgress;
    }
    if (activeExpansions.contains(ExpansionSet.eraOfTurmoil)) {
      return CatanAssets.backEraTurmoil;
    }
    if (activeExpansions.contains(ExpansionSet.eraOfProgress)) {
      return CatanAssets.backEraProgress;
    }
    return CatanAssets.backEraGold;
  }

  Widget _drawStackPile(int index) {
    final count = stackCounts['draw${index + 1}'] ?? 0;
    final claimed = count < initialStackSizes[index];
    final peeking = peekingStackIndex == index;
    final asset = _backAssetFor(index);

    if (handAdjustmentPhase == HandAdjustmentPhase.drawing) {
      final tappable = count > 0;
      return _StackPile(
        asset: asset,
        count: count,
        width: 48,
        dimmed: !tappable,
        highlighted: tappable,
        peeking: peeking,
        onTap: tappable ? () => onDrawStack?.call(index) : null,
      );
    }
    if (handAdjustmentPhase == HandAdjustmentPhase.discarding) {
      // Ett valt handkort får bara slängas i en hög av samma set (se
      // GameNotifier._checkStackMatchesCardOrigin) – bara den
      // matchande högen highlightas/går att trycka på, i stället för
      // att gå att trycka och sedan mötas av ett felmeddelande.
      final tappable = hasSelectedDiscardCard &&
          (selectedDiscardCardExactStackIndex != null
              ? selectedDiscardCardExactStackIndex == index
              : selectedDiscardCardIsThemeCard == _isThemeStack(index));
      return _StackPile(
        asset: asset,
        count: count,
        width: 48,
        highlighted: tappable,
        peeking: peeking,
        onTap: tappable ? () => onDiscardToStack?.call(index) : null,
      );
    }
    if (tradePhase == TradePhase.exchangeDiscard ||
        tradePhase == TradePhase.peekDiscard) {
      final tappable = hasSelectedExchangeCard &&
          (selectedDiscardCardExactStackIndex != null
              ? selectedDiscardCardExactStackIndex == index
              : selectedDiscardCardIsThemeCard == _isThemeStack(index));
      return _StackPile(
        asset: asset,
        count: count,
        width: 48,
        highlighted: tappable,
        peeking: peeking,
        onTap: tappable ? () => onExchangeDiscardToStack?.call(index) : null,
      );
    }
    if (libraryDrawPending) {
      final tappable = count > 0;
      return _StackPile(
        asset: asset,
        count: count,
        width: 48,
        dimmed: !tappable,
        highlighted: tappable,
        peeking: peeking,
        onTap: tappable ? () => onLibraryDrawStack?.call(index) : null,
      );
    }
    if (tradePhase == TradePhase.exchangeDraw) {
      final tappable = count > 0;
      return _StackPile(
        asset: asset,
        count: count,
        width: 48,
        dimmed: !tappable,
        highlighted: tappable,
        peeking: peeking,
        onTap: tappable ? () => onExchangeDrawStack?.call(index) : null,
      );
    }
    if (tradePhase == TradePhase.peekChoosingStack) {
      final tappable = count > 0;
      return _StackPile(
        asset: asset,
        count: count,
        width: 48,
        dimmed: !tappable,
        highlighted: tappable,
        peeking: peeking,
        onTap: tappable ? () => onPeekStack?.call(index) : null,
      );
    }

    // Temasetets egna högar hör aldrig till starthanden (se
    // GameNotifier.startHandDraft-doc) – bara grundspelets 3 (eller,
    // utan tema, alla 4) går att välja.
    final tappable = isChoosingHand &&
        isMyTurnToChooseHand &&
        !claimed &&
        !_isThemeStack(index);
    return _StackPile(
      asset: asset,
      count: count,
      width: 48,
      dimmed: isChoosingHand && (claimed || _isThemeStack(index)),
      highlighted: tappable,
      peeking: peeking,
      onTap: tappable ? () => onChooseStack?.call(index) : null,
    );
  }
}

class _StackPile extends StatefulWidget {
  final String asset;
  final int count;
  final double width;

  /// Kortmall att dra (t.ex. [BasicSetCards.road]). `null` = ej dragbar
  /// stapel (regioner, draghögar, händelse).
  final GameCard? card;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  /// Om [card] går att dra ut just nu (se [CenterStacksStrip.canBuild])
  /// – annars bara tryckbar för att förstora, inte dragbar.
  final bool canBuild;

  /// Tryckbar (i stället för dragbar) – används av draghögarna under
  /// starthandsvalet.
  final VoidCallback? onTap;

  /// Grön glöd, samma stil som de dragbara högarna – visar att den här
  /// högen går att trycka på just nu.
  final bool highlighted;

  /// Nedtonad – en redan vald draghög under starthandsvalet.
  final bool dimmed;

  /// Om motståndaren just nu kikar i den här högen (se
  /// [CenterStacksStrip.peekingStackIndex]) – en stadig gyllene glöd,
  /// till skillnad från [_StackFlash] som bara blinkar till en kort
  /// stund vid en släng-/dra-händelse.
  final bool peeking;

  const _StackPile({
    required this.asset,
    required this.count,
    this.width = 40,
    this.card,
    this.onDragStarted,
    this.onDragEnd,
    this.canBuild = true,
    this.onTap,
    this.highlighted = false,
    this.dimmed = false,
    this.peeking = false,
  });

  @override
  State<_StackPile> createState() => _StackPileState();
}

/// Vilken sorts förändring högen just fick, för [_StackFlash]-färgen –
/// [discard] (antalet ökade: någon slängde/lade tillbaka ett kort hit)
/// eller [draw] (antalet minskade: någon drog/tog ett kort härifrån).
enum _StackFlashKind { discard, draw }

class _StackPileState extends State<_StackPile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> _flashOpacity;
  _StackFlashKind? _flashKind;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    // Snabb intoning, en kort stund kvar på topp, sedan en längre
    // uttoning – "blinkar till" i stället för en jämn puls, så det syns
    // tydligt i ögonvrån utan att bli ett störande, ständigt pulserande
    // ljus.
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(_flashController);
  }

  @override
  void didUpdateWidget(covariant _StackPile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nyckelad enbart på [count] – oavsett om ändringen kom från en
    // egen lokal handling eller synkades in från motståndaren (se
    // GameNotifier._syncCenterStacks/_centerStacksSub), eftersom
    // antalet är den enda datan som faktiskt delas mellan klienterna.
    // Ökning = ett kort slängdes/lades hit, minskning = ett kort
    // drogs/togs härifrån – se [_StackFlashKind].
    if (widget.count != oldWidget.count) {
      _flashKind = widget.count > oldWidget.count
          ? _StackFlashKind.discard
          : _StackFlashKind.draw;
      _flashController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowing = widget.card != null || widget.highlighted;
    // Gyllene "kikar"-glöd går före den vanliga gröna tryckbar-glöden –
    // ovanligare och mer värd att lägga märke till.
    final borderColor = widget.peeking
        ? const Color(0xFFC9A227)
        : glowing
            ? const Color(0xFF7CBF6A)
            : CatanColors.woodFrame;
    final pile = AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: borderColor, width: widget.peeking || glowing ? 2 : 1),
            boxShadow: widget.peeking
                ? [
                    BoxShadow(
                        color: const Color(0xFFC9A227).withValues(alpha: 0.7),
                        blurRadius: 8,
                        spreadRadius: 1),
                  ]
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(widget.asset, fit: BoxFit.cover),
              Positioned(
                right: 2,
                bottom: 2,
                child: _CountBadge(count: widget.count),
              ),
            ],
          ),
        ),
      ),
    );
    final dimmedPile = widget.dimmed ? Opacity(opacity: 0.4, child: pile) : pile;

    final content = widget.onTap != null
        ? GestureDetector(onTap: widget.onTap, child: dimmedPile)
        : widget.card != null && widget.count > 0 && widget.canBuild
            ? LongPressDraggable<GameCard>(
                data: widget.card,
                delay: const Duration(milliseconds: 180),
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                      width: widget.width,
                      child: Transform.scale(scale: 1.3, child: pile)),
                ),
                childWhenDragging: Opacity(opacity: 0.35, child: pile),
                onDragStarted: () => widget.onDragStarted?.call(widget.card!),
                onDragEnd: (_) => widget.onDragEnd?.call(),
                // Ett riktigt fingertryck varar ofta längre än 180ms,
                // så LongPressDraggable hinner vinna gest-arenan innan
                // ett vanligt tryck hade fått chansen – utan det här
                // skulle den här högen inte gå att trycka på alls.
                // Släpps kortet utan att träffa ett giltigt mål tolkar
                // vi det som ett tryck och visar kortet förstorat.
                onDraggableCanceled: (_, __) {
                  widget.onDragEnd?.call();
                  showCardDetail(context, widget.card!);
                },
                child: pile,
              )
            // Tom hög (t.ex. slut på städer) – fortfarande tryckbar
            // för att kunna se kostnaden, bara inte dragbar.
            : widget.card != null
                ? GestureDetector(
                    onTap: () => showCardDetail(context, widget.card!),
                    child: dimmedPile)
                : dimmedPile;

    return SizedBox(
      width: widget.width,
      child: Stack(
        children: [
          content,
          AnimatedBuilder(
            animation: _flashOpacity,
            builder: (context, _) {
              final kind = _flashKind;
              if (kind == null || _flashOpacity.value <= 0) {
                return const SizedBox.shrink();
              }
              final color = kind == _StackFlashKind.discard
                  ? Colors.redAccent
                  : const Color(0xFF7CBF6A);
              return IgnorePointer(
                child: Opacity(
                  opacity: _flashOpacity.value,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: color.withValues(alpha: 0.75),
                              blurRadius: 9,
                              spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
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
