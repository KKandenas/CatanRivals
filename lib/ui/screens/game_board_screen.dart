import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/basic_set_cards.dart';
import '../../models/models.dart';
import '../../state/game_notifier.dart';
import '../../state/game_state.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import '../widgets/brigitta_number_picker.dart';
import '../widgets/build_confirm_card.dart';
import '../widgets/carved_frame.dart';
import '../widgets/center_stacks_strip.dart';
import '../widgets/dice_roll_button.dart';
import '../widgets/dice_roll_summary_banner.dart';
import '../widgets/event_card_reveal_card.dart';
import '../widgets/event_die_icon.dart';
import '../widgets/feud_building_instruction_bar.dart';
import '../widgets/feud_resolution_card.dart';
import '../widgets/fraternal_feuds_hand_picker.dart';
import '../widgets/hand_dock.dart';
import '../widgets/peek_stack_overlay.dart';
import '../widgets/pending_regions_bar.dart';
import '../widgets/pill_banner.dart';
import '../widgets/principality_grid.dart';
import '../widgets/relocation_instruction_bar.dart';
import '../widgets/scout_prompt_card.dart';
import '../widgets/scout_region_picker.dart';
import '../widgets/stack_choice_overlay.dart';
import '../widgets/top_status_bar.dart';
import '../widgets/total_score_board.dart';
import '../widgets/trade_phase_card.dart';

/// Huvudskärmen, stående layout: motståndarens namn/status (smal remsa),
/// motståndarens rike (kompakt), dragstaplar + "Avsluta action-fas" i
/// mitten (som i det fysiska spelets uppställning), ditt eget rike
/// (större, i fokus) och din handkortsdocka längst ner. Vems tur det är
/// visas bara i den breda bannern högst upp.
///
/// Rent presentationslager – allt spelstate bor i [gameProvider]
/// (state/game_notifier.dart). Undantaget är [_pendingBuildCard] och
/// [_selectedDiscardCard], som är rent lokalt UI-state (bekräftelse-
/// kortet, se [BuildConfirmCard], respektive vilket handkort som är
/// valt att slänga under handjusteringen) – de behöver inte synkas
/// mellan spelarna.
class GameBoardScreen extends ConsumerStatefulWidget {
  const GameBoardScreen({super.key});

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
  GameCard? _pendingBuildCard;
  VoidCallback? _pendingBuildConfirm;

  /// Handkortet som just nu är valt att slänga under
  /// [HandAdjustmentPhase.discarding] – rent lokalt UI-val (vilken
  /// draghög det till slut hamnar i avgörs av nästa tryck, se
  /// [CenterStacksStrip.onDiscardToStack]).
  GameCard? _selectedDiscardCard;

  /// Nyckeln (samma som `key: ValueKey(...)` på [DiceRollSummaryBanner]
  /// nedan) för det senast med "OK" stängda tärningskastet – rent
  /// lokalt UI-state. Måste ligga här (inte inuti banner-widgeten
  /// själv) för att HELA `Positioned.fill`-täckningen (den mörka
  /// bakgrunden, inte bara bannerns eget innehåll) ska försvinna vid
  /// "OK" – annars blockerar den svarta bakgrunden fortfarande
  /// motståndarens rike/kortförstoring resten av action-fasen.
  String? _dismissedDiceRollKey;

  /// Brödrafejd: kortet du precis valt från motståndarens hand, i
  /// väntan på att du väljer vilken draghög det ska läggas underst i
  /// (se [GameNotifier.pickFraternalFeudsCard]) – rent lokalt UI-val,
  /// precis som [_pendingBuildCard].
  GameCard? _pendingFraternalFeudsCard;

  void _handleResult(BuildContext context, String? error) {
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), duration: const Duration(seconds: 2)),
    );
  }

  /// Andra halvan av handlingskortens "tvåstegsraket" (se
  /// [HandDock.onUseActionCard]/card_detail_dialog.dart) – "Vill du
  /// använda kortet?" har redan bekräftats, nu avgörs vad just det
  /// korttypen faktiskt gör. Brigitta behöver ytterligare ett val
  /// (vilket tärningstal, se [showBrigittaNumberPicker]) och
  /// Omlokalisering startar en egen väljarläge (se
  /// [RelocationInstructionBar]) – övriga (Handelskaravan/Guldsmed) är
  /// självbevakade och behöver inget mer än att tas bort från handen.
  void _handleUseActionCard(
      BuildContext context, GameCard card, GameNotifier notifier) {
    if (card.baseId == BasicSetCards.brigittaTheWiseWoman.id) {
      showBrigittaNumberPicker(
        context,
        onPick: (number) =>
            _handleResult(context, notifier.useBrigitta(number)),
      );
      return;
    }
    if (card.baseId == BasicSetCards.relocation.id) {
      _handleResult(context, notifier.startRelocation());
      return;
    }
    _handleResult(context, notifier.discardActionCard(card));
  }

  /// Om ett kort redan väntar på bekräftelse (se [_pendingBuildCard])
  /// ignoreras nya förfrågningar i stället för att tyst skriva över den
  /// väntande – annars skulle ett andra kort kunna dras till en annan
  /// byggplats innan det första hunnit bekräftas/avbrytas, vilket tyst
  /// kastade bort det första kortets bekräftelse utan felmeddelande
  /// (kortet stannade förvisso kvar i handen, men försvann spårlöst ur
  /// bekräftelserutan – väldigt lätt att missa mitt i draget).
  void _requestBuildConfirm(GameCard card, VoidCallback onConfirm) {
    if (_pendingBuildCard != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bekräfta eller avbryt förra byggnationen först.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _pendingBuildCard = card;
      _pendingBuildConfirm = onConfirm;
    });
  }

  void _clearPendingBuild() {
    setState(() {
      _pendingBuildCard = null;
      _pendingBuildConfirm = null;
    });
  }

  void _confirmPendingBuild() {
    final confirm = _pendingBuildConfirm;
    _clearPendingBuild();
    confirm?.call();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    // Turindikatorn (banner/ram/nedtoning) är bara meningsfull under
    // vanligt spel – inte under starthandsvalet, som redan har sin
    // egen banner och där tärningen ändå aldrig är slagen.
    final showTurnEmphasis = state.handsReady;
    final canBuildNow = state.canBuildNow;
    // Om det går att bygga/dra kort just nu, utöver bara "din tur och
    // tärningen slagen" (se [GameState.canBuildRightNow]) – styr om
    // vägar/byar/städer och byggkort över huvud taget går att dra ut
    // (se HandDock/CenterStacksStrip), i stället för att de går att
    // dra och sedan mötas av ett felmeddelande efter "Betalt".
    final canBuildRightNow = state.canBuildRightNow;
    // Båda tärningarna slås alltid tillsammans (se
    // GameNotifier.rollProductionDie) – samma villkor styr om vardera
    // ikonen går att trycka på.
    final diceRollable = state.isMyTurn &&
        !state.diceRolled &&
        !(state.isOnline && !state.handsReady);
    void rollDice() => _handleResult(context, notifier.rollProductionDie());
    final diceRollKey =
        '${state.productionRoll}-${state.eventDieFace}-${state.activePlayerId}';
    // Vilken fas den aktiva spelaren är i just nu, till "DIN TUR"-
    // bannern nedan – "fyll på resurser" särskiljs från "utför actions"
    // med samma nyckel som styr tärningskastets popup
    // (DiceRollSummaryBanner/_dismissedDiceRollKey): innan den är
    // stängd väntar man fortfarande på att trycka + på sina regioner,
    // annars är man fri att bygga/spela kort. Handjustering och
    // kortbytesfasen har egna, redan spårade lägen.
    String turnPhaseLabel() {
      if (!state.diceRolled) return 'slå tärningarna';
      if (state.handAdjustmentPhase == HandAdjustmentPhase.drawing) {
        return 'fyll på kort';
      }
      if (state.handAdjustmentPhase == HandAdjustmentPhase.discarding) {
        return 'släng kort';
      }
      if (state.tradePhase != TradePhase.none) return 'byt kort';
      if (_dismissedDiceRollKey != diceRollKey) return 'fyll på resurser';
      return 'utför actions';
    }

    // HandDocks kortval (se nedan) återanvänds för handjusteringens
    // släng-läge, kortbytesfasens gratisbyte och kika-alternativets
    // slängsteg – de är aldrig aktiva samtidigt (kortbytesfasen börjar
    // först efter att handjusteringen är klar), så samma lokala
    // UI-state (_selectedDiscardCard) räcker för alla tre.
    final isDiscarding =
        state.handAdjustmentPhase == HandAdjustmentPhase.discarding ||
            state.tradePhase == TradePhase.exchangeDiscard ||
            state.tradePhase == TradePhase.peekDiscard;
    // Ett tidigare valt handkort hör bara hemma medan släng-läget
    // faktiskt pågår – annars är det en kvarleva från en tidigare omgång.
    if (!isDiscarding) _selectedDiscardCard = null;

    // Fejd/Brödrafejd (styrkeövertag avgör vem som förlorar ett kort,
    // se FeudResolutionCard) ersätter den vanliga EventCardRevealCard
    // för just de här två korten. `showFeudResolution` är sant bara
    // under själva "vem har övertaget"-steget – när en av
    // väljar-flödena startat (feudBuildingPickActive/
    // fraternalFeudsPicking) visas i stället de egna överlagren nedan.
    final drawnEventBaseId = state.drawnEventCard?.baseId;
    final isFeudCard = drawnEventBaseId == BasicSetCards.feud.id;
    final isFraternalFeudsCard =
        drawnEventBaseId == BasicSetCards.fraternalFeuds.id;
    final showFeudResolution = (isFeudCard || isFraternalFeudsCard) &&
        !state.feudBuildingPickActive &&
        !state.fraternalFeudsPicking;
    if (!state.fraternalFeudsPicking) _pendingFraternalFeudsCard = null;

    // Hero Token/Trade Token (se GameNotifier.recomputeTokenHolders) –
    // räknas ut en gång här och delas mellan ScoreSummary-rutorna och
    // TotalScoreBoard så de alltid visar samma sak.
    final youHaveHeroToken = state.heroTokenHolder == state.you.id;
    final youHaveTradeToken = state.tradeTokenHolder == state.you.id;
    final opponentHasHeroToken = state.heroTokenHolder == state.opponent.id;
    final opponentHasTradeToken = state.tradeTokenHolder == state.opponent.id;
    final youTotalVictoryPoints = state.totalVictoryPointsFor(state.you);
    final opponentTotalVictoryPoints =
        state.totalVictoryPointsFor(state.opponent);

    return Scaffold(
      // Rumskoden behövs bara medan den andra spelaren ännu inte gått
      // med – när båda är inne försvinner remsan automatiskt för att
      // ge mer plats åt själva brädet.
      appBar: (state.roomCode == null || state.opponentConnected)
          ? null
          : AppBar(
              title: Text('Rum: ${state.roomCode}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Lämna rummet',
                  onPressed: () {
                    notifier.playLocally();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
      body: Stack(
        children: [
          // Gemensam träbakgrund bakom hela brädet (samma bild som
          // riksrutnäten redan tapetserar med sin egen pergament-slöja,
          // se PrincipalityGrid) – ett första steg mot mer "bordskänsla"
          // (se användarens Gemini-referens). Statusfälten ovanför
          // riket ([TopStatusBar]/[CenterStacksStrip]/[HandDock]) är
          // medvetet lätt genomskinliga (samma mönster som HandDock
          // redan använde för sig själv) så att den syns igenom även
          // där, i stället för att bara synas i marginalerna.
          const Positioned.fill(
            child: Image(
              image: AssetImage(CatanAssets.boardBackground),
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Stack(
                children: [
                  Column(
                    children: [
                      if (state.sessionError != null)
                        PillBanner(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Text(
                            state.sessionError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer),
                          ),
                        )
                      else if (state.mode == SessionMode.host &&
                          !state.opponentConnected)
                        PillBanner(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          child: Text(
                            'Väntar på att motståndaren ska gå med rummet ${state.roomCode} …',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (state.isOnline && !state.handsReady)
                        PillBanner(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          child: Text(
                            state.isMyTurnToChooseHand
                                ? 'Din tur: tryck på en draghög för att ta dina 3 starthandkort'
                                : 'Väntar på att ${state.opponent.name} väljer en draghög …',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (showTurnEmphasis)
                        // Rundad pill i stället för en helbred remsa – lika
                        // omöjligt att missa vems tur det är, kompletterar den
                        // gröna ramen runt egna riket och den lätta
                        // nedtoningen när det inte är din tur.
                        PillBanner(
                          color: state.activePlayerIsMe
                              ? const Color(0xFF4F6F45)
                              : CatanColors.woodFrameDark,
                          child: Text(
                            state.activePlayerIsMe
                                ? 'DIN TUR – ${turnPhaseLabel()}'
                                : '${state.opponent.name}s TUR',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      TopStatusBar(
                        opponent: state.opponent,
                        opponentIsRed: !state.amIRed,
                        totalVictoryPoints: opponentTotalVictoryPoints,
                        hasHeroToken: opponentHasHeroToken,
                        hasTradeToken: opponentHasTradeToken,
                      ),
                    ],
                  ),
                  // Totalställningen (segerpoäng för båda spelarna, se
                  // TotalScoreBoard) svävar i övre högra hörnet och
                  // sträcker sig över både DIN TUR-pillen och raden med
                  // motståndarens namn i stället för att pressas in i den
                  // senare – då slapp den raden växa på höjden bara för att
                  // få plats med två rader poäng.
                  if (showTurnEmphasis)
                    Positioned(
                      top: 4,
                      right: 10,
                      child: TotalScoreBoard(
                        youName: state.you.name,
                        youPoints: youTotalVictoryPoints,
                        youHaveHeroToken: youHaveHeroToken,
                        youHaveTradeToken: youHaveTradeToken,
                        amIRed: state.amIRed,
                        opponentName: state.opponent.name,
                        opponentPoints: opponentTotalVictoryPoints,
                        opponentHasHeroToken: opponentHasHeroToken,
                        opponentHasTradeToken: opponentHasTradeToken,
                      ),
                    ),
                ],
              ),
              // Kortbytesfasen (regelhäftet s. 9), sist i omgången efter
              // handjusteringen – en vanlig rad högst upp (inte en
              // dialogruta), precis som DiceRollSummaryBanner ovan.
              // TradePhase.peekViewing visas inte här utan som
              // PeekStackOverlay nedan, eftersom den behöver plats för
              // flera kort.
              TradePhaseCard(
                phase: state.tradePhase,
                onSkip: () => _handleResult(context, notifier.skipTrade()),
                onStartExchange: () =>
                    _handleResult(context, notifier.startExchange()),
                onStartPeek: () => _handleResult(context, notifier.startPeek()),
                onConfirmPeekPayment: () =>
                    _handleResult(context, notifier.confirmPeekPayment()),
                onCancelPeek: () =>
                    _handleResult(context, notifier.cancelPeek()),
              ),
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 2, 4),
                            child: CarvedFrame(
                              child: PrincipalityGrid(
                                board: state.opponent.principality,
                                unit: 58,
                                gap: 4,
                              ),
                            ),
                          ),
                        ),
                        // Tärningen står till höger om motståndarens rike i
                        // stället för i mittremsan, så att mittremsan (och
                        // därmed alla kort) kan vara så stora som möjligt.
                        Container(
                          width: 76,
                          // Samma genomskinlighet som TopStatusBar/
                          // CenterStacksStrip/HandDock, så den delade
                          // träbakgrunden syns igenom här också.
                          color: CatanColors.woodFrameDark.withValues(alpha: 0.75),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DiceRollButton(
                                value: state.productionRoll,
                                rollable: diceRollable,
                                onTap: rollDice,
                              ),
                              // Händelsetärningen slås samtidigt som
                              // produktionstärningen (se EventDieFace) –
                              // visas alltid tillsammans med den, även
                              // innan första kastet (samma "väntar"-
                              // utseende, samma storlek), inte bara i
                              // den tillfälliga popupen ovan. Båda
                              // tärningarna går att trycka på för att
                              // slå (de slås alltid ihop).
                              const SizedBox(height: 6),
                              EventDieIcon(
                                face: state.eventDieFace,
                                rollable: diceRollable,
                                onTap: rollDice,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Tärningspopupen läggs ovanpå motståndarens rike
                    // (inte en dialogruta) i stället för att trycka ner
                    // hela brädet i sidflödet – den täcker bara
                    // motståndarens planhalva, dina egna regioners +/-
                    // går fortfarande att trycka på. `key: ValueKey(...)`
                    // gör att den visas på nytt (återställer ev. tidigare
                    // "OK") för varje kast. Hela täckningen (mörk
                    // bakgrund + banner) döljs vid "OK" – se
                    // [_dismissedDiceRollKey].
                    if (state.diceRolled &&
                        state.productionRoll != null &&
                        state.eventDieFace != null &&
                        _dismissedDiceRollKey != diceRollKey)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: DiceRollSummaryBanner(
                            key: ValueKey(diceRollKey),
                            productionRoll: state.productionRoll!,
                            eventDieFace: state.eventDieFace!,
                            rolledByMe: state.activePlayerIsMe,
                            opponentName: state.opponent.name,
                            onDismiss: () => setState(
                                () => _dismissedDiceRollKey = diceRollKey),
                          ),
                        ),
                      ),
                    // Bekräftelsekortet läggs ovanpå motståndarens rike (inte
                    // en modal dialogruta) – så att det inte täcker dina egna
                    // regioner: du kommer åt +/- knapparna på ditt eget rike
                    // medan det syns, och det stängs aldrig av misstag genom
                    // att man trycker utanför, bara med Betalt/Avbryt.
                    if (_pendingBuildCard != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: BuildConfirmCard(
                            card: _pendingBuildCard!,
                            onConfirm: _confirmPendingBuild,
                            onCancel: _clearPendingBuild,
                          ),
                        ),
                      ),
                    if (state.tradePhase == TradePhase.peekViewing &&
                        state.peekedCards != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: PeekStackOverlay(
                            cards: state.peekedCards!,
                            onTakeCard: (card) => _handleResult(
                                context, notifier.peekTakeCard(card)),
                          ),
                        ),
                      ),
                    // Uppslaget händelsekort (se drawEventCard) – synkat
                    // till båda spelarna, precis som bekräftelsekortet
                    // och kika-vyn ovan: inte en modal dialogruta. Fejd
                    // och Brödrafejd visas i stället med
                    // FeudResolutionCard (se nedan), eftersom de kräver
                    // att veta vem som har styrkeövertaget.
                    if (state.drawnEventCard != null &&
                        !isFeudCard &&
                        !isFraternalFeudsCard)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: EventCardRevealCard(
                            card: state.drawnEventCard!,
                            onDismiss: () => _handleResult(
                                context, notifier.dismissEventCard()),
                          ),
                        ),
                      ),
                    if (showFeudResolution)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: FeudResolutionCard(
                            card: state.drawnEventCard!,
                            isTie: state.strengthAdvantagePlayerId == null,
                            youHaveAdvantage: state.strengthAdvantagePlayerId ==
                                state.myPlayerId,
                            isOnline: state.isOnline,
                            opponentName: state.opponent.name,
                            hasBuildingToRemove:
                                state.strengthAdvantagePlayerId ==
                                        state.myPlayerId
                                    ? state.opponent.principality.hasAnyBuilding
                                    : state.you.principality.hasAnyBuilding,
                            onDismiss: () => _handleResult(
                                context, notifier.dismissEventCard()),
                            onStartFeudPick: () => _handleResult(
                                context, notifier.startFeudBuildingPick()),
                            onStartFraternalFeudsPick: () => _handleResult(
                                context, notifier.startFraternalFeudsPick()),
                          ),
                        ),
                      ),
                    // Fejd: efter att en egen byggnad valts (se
                    // PrincipalityGrid.onSelectFeudBuilding nedan) väntar
                    // bara valet av vilken draghög den ska läggas underst
                    // i.
                    if (state.feudBuildingPickActive &&
                        state.feudPickedBuilding != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: StackChoiceOverlay(
                            title:
                                'Vilken draghög ska byggnaden läggas underst i?',
                            onChooseStack: (index) => _handleResult(context,
                                notifier.resolveFeudBuildingRemoval(index)),
                            onCancel: () => _handleResult(
                                context, notifier.cancelFeudBuildingPick()),
                          ),
                        ),
                      ),
                    // Brödrafejd (bara lokalt läge, se
                    // GameNotifier.startFraternalFeudsPick): motståndarens
                    // hand öppen för fritt val, sedan (per valt kort) vilken
                    // draghög det ska läggas underst i.
                    if (state.fraternalFeudsPicking &&
                        _pendingFraternalFeudsCard == null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: FraternalFeudsHandPicker(
                            hand: state.opponent.hand,
                            pickedCount: state.fraternalFeudsPicked.length,
                            onPick: (card) => setState(
                                () => _pendingFraternalFeudsCard = card),
                          ),
                        ),
                      ),
                    if (state.fraternalFeudsPicking &&
                        _pendingFraternalFeudsCard != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: StackChoiceOverlay(
                            title:
                                'Vilken draghög ska kortet läggas underst i?',
                            onChooseStack: (index) {
                              final card = _pendingFraternalFeudsCard!;
                              setState(() => _pendingFraternalFeudsCard = null);
                              _handleResult(context,
                                  notifier.pickFraternalFeudsCard(card, index));
                            },
                            onCancel: () => setState(
                                () => _pendingFraternalFeudsCard = null),
                          ),
                        ),
                      ),
                    // Spejare (se dropSettlement/useScout/declineScout):
                    // "Vill du använda kortet?"-frågan väcks automatiskt
                    // av by-bygget i stället för ett handkortstryck (se
                    // HandDock), sedan den öppna regionstapeln att välja
                    // 2 kort ur.
                    if (state.awaitingScoutDecision &&
                        state.scoutChoices == null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: ScoutPromptCard(
                            onUseScout: () =>
                                _handleResult(context, notifier.useScout()),
                            onDecline: () =>
                                _handleResult(context, notifier.declineScout()),
                          ),
                        ),
                      ),
                    if (state.scoutChoices != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          padding: const EdgeInsets.all(12),
                          child: ScoutRegionPicker(
                            cards: state.scoutChoices!,
                            pickedCount: state.pendingRegions.length,
                            onPick: (card) => _handleResult(
                                context, notifier.pickScoutRegion(card)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              CenterStacksStrip(
                stackCounts: state.centerStacks,
                onDragStarted: notifier.startDrag,
                onDragEnd: notifier.endDrag,
                canBuild: canBuildRightNow,
                isChoosingHand: state.isOnline && !state.handsReady,
                isMyTurnToChooseHand: state.isMyTurnToChooseHand,
                onChooseStack: (index) =>
                    _handleResult(context, notifier.chooseStartingStack(index)),
                isYourTurn: state.isMyTurn,
                diceRolled: state.diceRolled,
                onEndTurn: () =>
                    _handleResult(context, notifier.endActionPhase()),
                handAdjustmentPhase: state.handAdjustmentPhase,
                handCount: state.you.hand.length,
                handLimit: state.handLimit,
                onDrawStack: (index) =>
                    _handleResult(context, notifier.drawHandCard(index)),
                hasSelectedDiscardCard: state.handAdjustmentPhase ==
                        HandAdjustmentPhase.discarding &&
                    _selectedDiscardCard != null,
                onDiscardToStack: (index) {
                  final card = _selectedDiscardCard;
                  if (card == null) return;
                  final error = notifier.discardHandCard(card, index);
                  if (error == null) {
                    setState(() => _selectedDiscardCard = null);
                  } else {
                    _handleResult(context, error);
                  }
                },
                tradePhase: state.tradePhase,
                hasSelectedExchangeCard:
                    (state.tradePhase == TradePhase.exchangeDiscard ||
                            state.tradePhase == TradePhase.peekDiscard) &&
                        _selectedDiscardCard != null,
                onExchangeDiscardToStack: (index) {
                  final card = _selectedDiscardCard;
                  if (card == null) return;
                  final error = state.tradePhase == TradePhase.peekDiscard
                      ? notifier.peekDiscardCard(card, index)
                      : notifier.exchangeDiscard(card, index);
                  if (error == null) {
                    setState(() => _selectedDiscardCard = null);
                  } else {
                    _handleResult(context, error);
                  }
                },
                onExchangeDrawStack: (index) =>
                    _handleResult(context, notifier.exchangeDraw(index)),
                onPeekStack: (index) =>
                    _handleResult(context, notifier.choosePeekStack(index)),
                canDrawEventCard:
                    state.eventDieFace == EventDieFace.eventCard &&
                        state.diceRolled &&
                        state.isMyTurn &&
                        state.drawnEventCard == null,
                onDrawEventCard: () =>
                    _handleResult(context, notifier.drawEventCard()),
              ),
              if (state.pendingRegions.isNotEmpty)
                PendingRegionsBar(
                  cards: state.pendingRegions,
                  onDragStarted: notifier.startDrag,
                  onDragEnd: notifier.endDrag,
                ),
              if (state.relocationActive)
                RelocationInstructionBar(
                  hasFirstSelection: state.relocationFirst != null,
                  onCancel: () =>
                      _handleResult(context, notifier.cancelRelocation()),
                ),
              if (state.feudBuildingPickActive)
                FeudBuildingInstructionBar(
                  onCancel: () =>
                      _handleResult(context, notifier.cancelFeudBuildingPick()),
                ),
              Expanded(
                flex: 5,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: showTurnEmphasis && canBuildNow
                          ? const Color(0xFF7CBF6A)
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: showTurnEmphasis && canBuildNow
                        ? [
                            BoxShadow(
                                color: const Color(0xFF7CBF6A)
                                    .withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1),
                          ]
                        : null,
                  ),
                  // Lätt nedtoning (inte heltäckande) när det inte är din
                  // tur att bygga – korten ska fortfarande gå att läsa och
                  // trycka på för att förstora, bara se "inaktiva" ut.
                  child: Opacity(
                    opacity: showTurnEmphasis && !canBuildNow ? 0.6 : 1,
                    child: CarvedFrame(
                      child: PrincipalityGrid(
                        board: state.you.principality,
                        interactive: true,
                        draggingCard: state.draggingCard,
                        onDropExpansion: (column, row, slotIndex, card) =>
                            _handleResult(
                                context,
                                notifier.dropExpansion(
                                    column, row, slotIndex, card)),
                        onDropRoad: (column, card) => _handleResult(
                            context, notifier.dropRoad(column, card)),
                        onDropSettlement: (column, card) => _handleResult(
                            context, notifier.dropSettlement(column, card)),
                        onDropCityUpgrade: (column, card) => _handleResult(
                            context, notifier.dropCityUpgrade(column, card)),
                        onAdjustRegion: notifier.adjustRegionResource,
                        onRequestBuildConfirm: _requestBuildConfirm,
                        pendingRegionJunction: state.pendingRegionJunction,
                        onDropPendingRegion: (row, card) => _handleResult(
                            context, notifier.placePendingRegion(row, card)),
                        relocationActive: state.relocationActive,
                        relocationFirst: state.relocationFirst,
                        onSelectRelocationTarget: (kind, column, row, slot) =>
                            _handleResult(
                                context,
                                notifier.selectRelocationTarget(
                                    kind, column, row, slot)),
                        feudBuildingPickActive: state.feudBuildingPickActive,
                        feudPickedBuilding: state.feudPickedBuilding,
                        onSelectFeudBuilding: (column, row, slot) =>
                            _handleResult(context,
                                notifier.selectFeudBuilding(column, row, slot)),
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: showTurnEmphasis && !canBuildNow ? 0.6 : 1,
                child: HandDock(
                  player: state.you,
                  onDragStarted: notifier.startDrag,
                  onDragEnd: notifier.endDrag,
                  onUseActionCard: (card) =>
                      _handleUseActionCard(context, card, notifier),
                  diceRolled: state.diceRolled,
                  canBuild: canBuildRightNow,
                  selectedDiscardCard:
                      isDiscarding ? _selectedDiscardCard : null,
                  onSelectForDiscard: isDiscarding
                      ? (card) => setState(() => _selectedDiscardCard =
                          _selectedDiscardCard == card ? null : card)
                      : null,
                  totalVictoryPoints: youTotalVictoryPoints,
                  hasHeroToken: youHaveHeroToken,
                  hasTradeToken: youHaveTradeToken,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
