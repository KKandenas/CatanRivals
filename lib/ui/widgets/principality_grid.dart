import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/build_requirements.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'expansion_card_view.dart';
import 'pop_in.dart';
import 'region_card_view.dart';
import 'region_expansion_card_view.dart';
import 'settlement_card_view.dart';

/// Anropas när ett kort släpps på en tom byggplats.
typedef ExpansionDropCallback = void Function(
  int column,
  BuildingRow row,
  int slotIndex,
  GameCard card,
);

/// Anropas när ett väg-/by-/stadskort släpps på sin respektive
/// giltiga ruta. `column` är den udda kolumnen (väg) eller jämna
/// kolumnen (by/stads-uppgradering) det gäller.
typedef ColumnDropCallback = void Function(int column, GameCard card);

/// Anropas när +/- trycks på en region för att manuellt justera dess
/// lagrade resurser (regelhäftet s. 7: produktionstärningens utdelning).
typedef RegionAdjustCallback = void Function(int junctionColumn, BuildingRow row, int delta);

/// Anropas när ett av de två väntande, ännu oplacerade regionkorten
/// (efter en nybyggd by, regelhäftet s. 8) släpps på platsen ovanför
/// eller nedanför den byn.
typedef PendingRegionDropCallback = void Function(BuildingRow row, GameCard card);

/// Anropas när ett väg-/by-/stads-/utbyggnadskort släpps på en giltig
/// plats – innan det faktiskt byggs. `onConfirm` bygger kortet om
/// spelaren bekräftar (se `BuildConfirmCard` i game_board_screen.dart).
/// `replacedCard` är satt bara när platsen redan har ett bygg-/enhets-/
/// skeppskort (se [_buildingSite]) – man får byta ut det mot det nya
/// kortet (full kostnad, det gamla hamnar i slänghögen, se
/// [GameNotifier.dropExpansion]). `blockedReason` (se
/// `build_requirements.dart`) är satt när platsen tekniskt sett tar
/// emot kortets kategori men ett krav inte är uppfyllt (t.ex. Guldgömma
/// utan hjälte, en stadsutbyggnad på en vanlig by) – kortet landar
/// ändå (så spelaren FÅR en förklaring) men `BuildConfirmCard` visar då
/// bara texten, ingen "Betalt"-väg.
typedef BuildConfirmRequest = void Function(GameCard card, VoidCallback onConfirm,
    {GameCard? replacedCard, String? blockedReason});

/// Anropas när en plats trycks på under Omlokalisering (se
/// [RelocationTargetKind]/[GameNotifier.selectRelocationTarget]) –
/// `slotIndex` är alltid 0 för regioner.
typedef RelocationSelectCallback = void Function(
    RelocationTargetKind kind, int column, BuildingRow row, int slotIndex);

/// Anropas när ett landskapsutbyggnadskort (t.ex. Guldgömma) släpps
/// intill en region – se [GameNotifier.dropRegionExpansion].
typedef RegionExpansionDropCallback = void Function(
    int column, BuildingRow row, GameCard card);

/// Ritar ut ett [RealmBoard] enligt kolumnmodellen: byar/städer i en rad,
/// vägar mellan dem, och regioner delade diagonalt i hörnen ovanför och
/// nedanför (se "Rikets koordinatsystem"-skissen). Alla kort är
/// kvadratiska.
///
/// Hela riket byggs vid en fast basstorlek (`unit`) och skalas sedan
/// proportionerligt med en enda [FittedBox] för att alltid fylla så
/// mycket av det tillgängliga utrymmet som möjligt utan att hamna
/// utanför – ju fler vägar/byar/städer som byggs, desto mindre blir
/// den slutgiltiga skalan. Eftersom kostnad, poäng, tärningsprickar och
/// +/- knappar bara är en del av samma innehållsträd skalas de
/// automatiskt med, utan någon egen skalningslogik.
///
/// `unit` styr kortens *inbördes* storlek (text-/ikonstorlek relativt
/// kortet) – ett mindre värde används för motståndarens kompakta rike.
///
/// Sätt `interactive: true` (bara för ditt eget rike) för att aktivera
/// drop-mål: tomma byggplatser (bygg-/enhetskort), den öppna vägplatsen
/// i vardera änden av kedjan (vägkort), en "spökby"-plats bortom en
/// hängande väg (bykort), och befintliga byar (stadskort, för
/// uppgradering). `draggingCard` styr vilken typ av rutor som tänds i
/// en mjuk glöd medan man drar – bara de som faktiskt matchar kortets
/// kategori.
class PrincipalityGrid extends StatelessWidget {
  final RealmBoard board;
  final double unit;
  final double gap;
  final bool interactive;
  final GameCard? draggingCard;
  final ExpansionDropCallback? onDropExpansion;
  final ColumnDropCallback? onDropRoad;
  final ColumnDropCallback? onDropSettlement;
  final ColumnDropCallback? onDropCityUpgrade;
  final RegionAdjustCallback? onAdjustRegion;
  final BuildConfirmRequest? onRequestBuildConfirm;

  /// Landskapsutbyggnad (t.ex. Guldgömma, se [RegionExpansionDropCallback])
  /// – dropp-mål intill en region, och +/- för dess egna lagrade
  /// resurser (samma mönster som [onAdjustRegion]).
  final RegionExpansionDropCallback? onDropRegionExpansion;
  final RegionAdjustCallback? onAdjustRegionExpansion;

  /// Om en redan bebyggd byggplats går att släppa ett nytt kort på för
  /// att byta ut det gamla (se [_buildingSite]) – den mekaniken finns
  /// bara med minst ett tema aktivt (regelhäftet har ingen sådan regel
  /// för grundspelet), se [GameState.activeExpansions]/
  /// [GameNotifier.dropExpansion]. `false` som standard: en upptagen
  /// plats är då inte ett giltigt drop-mål alls, precis som innan
  /// byt-ut-mekaniken fanns.
  final bool allowReplaceExpansion;

  /// Knutpunkten (om någon) som just nu väntar på att få sina 2
  /// regionkort placerade (se [PendingRegionDropCallback]).
  final int? pendingRegionJunction;
  final PendingRegionDropCallback? onDropPendingRegion;

  /// Omlokalisering (se [RelocationSelectCallback]): om aktiv blir
  /// varje egen, ockuperad region/byggplats tryckbar i stället för
  /// draghjälpen – [relocationFirst] är det första valet (om något),
  /// markerat med en gul ram tills det andra trycket genomför bytet.
  final bool relocationActive;
  final RelocationSelection? relocationFirst;
  final RelocationSelectCallback? onSelectRelocationTarget;

  /// Fejd (se [GameNotifier.selectFeudBuilding]): om aktiv blir bara
  /// egna, ockuperade byggplatser med ett byggnadskort (inte
  /// skepp/hjältar) tryckbara – markerade med en gul ram efter valet,
  /// tills draghögen väljs (se [FeudResolutionCard]/StackChoiceOverlay
  /// i game_board_screen.dart).
  final bool feudBuildingPickActive;
  final RelocationSelection? feudPickedBuilding;
  final void Function(int column, BuildingRow row, int slotIndex)?
      onSelectFeudBuilding;

  /// Fri regionomflyttning direkt efter starthandsutdelningen med ett
  /// tema aktivt (se [GameNotifier.selectRegionRearrangementTarget]) –
  /// ett tredje, parallellt väljarläge till [relocationActive]/
  /// [feudBuildingPickActive]: BARA regioner, aldrig byggkort.
  final bool startingRegionRearrangementActive;
  final RelocationSelection? startingRegionRearrangementFirst;
  final void Function(int column, BuildingRow row)?
      onSelectStartingRegionRearrangementTarget;

  /// Piratskepp (se [GameNotifier.resolvePirateShipDiscard]): om aktiv
  /// blir bara egna, utplacerade handelsskepp tryckbara – ett enda tryck
  /// räcker (till skillnad från Fejd finns ingen efterföljande
  /// draghögsval, kortet hamnar direkt i slänghögen).
  final bool pirateShipDiscardActive;
  final void Function(int column, BuildingRow row, int slotIndex)?
      onSelectPirateShipDiscard;

  /// Upplopp (se [GameNotifier.selectRiotsUnit]): om aktiv blir egna,
  /// ockuperade byggplatser med EN ENHET (byggnad, skepp ELLER hjälte –
  /// bredare kriterium än Fejd, som bara gäller byggnader) med styrke-
  /// eller handelspoäng tryckbara – markerade med en gul ram efter
  /// valet, tills draghögen väljs (se [RiotsResolutionCard]/
  /// StackChoiceOverlay i game_board_screen.dart).
  final bool riotsUnitPickActive;
  final RelocationSelection? riotsPickedUnit;
  final void Function(int column, BuildingRow row, int slotIndex)?
      onSelectRiotsUnit;

  /// Bågskytt/Pyroman (se [GameNotifier.selectAttackCardUnit]): om
  /// satt (till skillnad från de andra väljarlägena ovan, som styrs av
  /// en `bool`, avgör VILKET kort – Bågskytt eller Pyroman – vilket
  /// kriterium som gäller, se [AttackCardKind]) blir egna, ockuperade
  /// byggplatser som uppfyller kortets kriterium tryckbara – markerade
  /// med en gul ram efter valet, tills draghögen väljs (se
  /// StackChoiceOverlay i game_board_screen.dart).
  final AttackCardKind? pendingAttackCard;
  final RelocationSelection? attackCardPickedUnit;
  final void Function(int column, BuildingRow row, int slotIndex)?
      onSelectAttackCardUnit;

  const PrincipalityGrid({
    super.key,
    required this.board,
    this.unit = 78,
    this.gap = 5,
    this.interactive = false,
    this.draggingCard,
    this.onDropExpansion,
    this.onDropRoad,
    this.onDropSettlement,
    this.onDropCityUpgrade,
    this.onAdjustRegion,
    this.onRequestBuildConfirm,
    this.onDropRegionExpansion,
    this.onAdjustRegionExpansion,
    this.allowReplaceExpansion = false,
    this.pendingRegionJunction,
    this.onDropPendingRegion,
    this.relocationActive = false,
    this.relocationFirst,
    this.onSelectRelocationTarget,
    this.feudBuildingPickActive = false,
    this.feudPickedBuilding,
    this.onSelectFeudBuilding,
    this.startingRegionRearrangementActive = false,
    this.startingRegionRearrangementFirst,
    this.onSelectStartingRegionRearrangementTarget,
    this.pirateShipDiscardActive = false,
    this.onSelectPirateShipDiscard,
    this.riotsUnitPickActive = false,
    this.riotsPickedUnit,
    this.onSelectRiotsUnit,
    this.pendingAttackCard,
    this.attackCardPickedUnit,
    this.onSelectAttackCardUnit,
  });

  bool get _draggingRoad => draggingCard?.category == CardCategory.road;
  bool get _draggingSettlement =>
      draggingCard?.category == CardCategory.settlement;
  bool get _draggingCity => draggingCard?.category == CardCategory.city;
  bool get _draggingExpansion =>
      draggingCard?.category == CardCategory.expansion ||
      draggingCard?.category == CardCategory.cityExpansion;
  bool get _draggingRegion => draggingCard?.category == CardCategory.region;
  bool get _draggingRegionExpansion =>
      draggingCard?.category == CardCategory.regionExpansion;

  @override
  Widget build(BuildContext context) {
    if (board.settlements.isEmpty) {
      return const Center(child: Text('Tomt rike'));
    }

    var left = board.leftmostColumn - 1;
    var right = board.rightmostColumn + 1;
    // Om en väg redan hänger ute i kanten, visa en till kolumn så att
    // spelaren kan bygga nästa by bortom den.
    if (board.roads.containsKey(left)) left -= 1;
    if (board.roads.containsKey(right)) right += 1;

    final cols = [for (var col = left; col <= right; col++) col];

    // En stad har 2 byggplatser i varje riktning i stället för byns 1
    // – de får sedan helt egna rader (inte mindre kort i samma rad),
    // så hela ovanför-/nedanför-sektionen görs så hög som den bredaste
    // (mest utbyggda) staden på brädet kräver. Övriga kolumner (byar,
    // regioner) förblir enkortshöjd och kant-justeras mot mitten.
    int aboveSiteCount(int col) =>
        col.isEven ? (board.settlementAt(col)?.aboveSites.length ?? 1) : 1;
    int belowSiteCount(int col) =>
        col.isEven ? (board.settlementAt(col)?.belowSites.length ?? 1) : 1;
    final maxAbove = cols.map(aboveSiteCount).reduce((a, b) => a > b ? a : b);
    final maxBelow = cols.map(belowSiteCount).reduce((a, b) => a > b ? a : b);
    final aboveHeight = maxAbove * unit + (maxAbove - 1) * gap;
    final belowHeight = maxBelow * unit + (maxBelow - 1) * gap;

    final contentWidth = cols.length * unit + (cols.length - 1) * gap;
    final contentHeight = aboveHeight + gap + unit + gap + belowHeight;
    const padding = 20.0;

    Widget sectionRow(double height, Widget Function(int col) cellBuilder) {
      final children = <Widget>[];
      for (var i = 0; i < cols.length; i++) {
        children.add(cellBuilder(cols[i]));
        if (i != cols.length - 1) children.add(SizedBox(width: gap));
      }
      return SizedBox(height: height, child: Row(children: children));
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sectionRow(aboveHeight, (col) => _aboveCell(col, aboveHeight)),
        SizedBox(height: gap),
        sectionRow(unit, _spineCell),
        SizedBox(height: gap),
        sectionRow(belowHeight, (col) => _belowCell(col, belowHeight)),
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(CatanAssets.boardBackground, fit: BoxFit.cover),
        // Pergament-slöja ovanpå träteexturen, så att de tomma
        // byggplatsernas streckade kanter och korten fortfarande
        // syns tydligt – samma ljushet som den gamla gradienten hade.
        Container(color: CatanColors.parchment.withValues(alpha: 0.55)),
        _buildFittedContent(contentWidth, contentHeight, padding, content),
      ],
    );
  }

  /// Skalar hela riket proportionerligt så att det alltid fyller så
  /// mycket av tillgängligt utrymme som möjligt utan att hamna utanför
  /// – i stället för en fast kortstorlek som skulle kräva manuell
  /// pan/zoom när riket växer sig större än vad som får plats. En enda
  /// [FittedBox] runt hela innehållet räcker: eftersom kostnads-
  /// ikonerna, poängen, tärningsprickarna och +/- knapparna bara är
  /// widgetar längre ner i samma träd skalas de automatiskt med.
  ///
  /// OBS: inget `Center` runt [FittedBox] här – `Center` gör om de
  /// åtstramade begränsningarna som [Stack] (`StackFit.expand`) ger
  /// till lösa, och då vet `FittedBox` inte hur stort utrymme den
  /// faktiskt har att fylla (den skalar då varken upp eller ner).
  /// `FittedBox` centrerar sitt innehåll själv (`alignment.center` är
  /// standard), så resultatet blir detsamma utan `Center`.
  Widget _buildFittedContent(double contentWidth, double contentHeight,
      double padding, Widget content) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: contentWidth + padding * 2,
        height: contentHeight + padding * 2,
        child: Padding(padding: EdgeInsets.all(padding), child: content),
      ),
    );
  }

  /// Cellen i ovanför-sektionen för en kolumn: en region (för
  /// knutpunktskolumner) eller den utbyggda by/stad-kolumnens
  /// byggplatser, botten-justerade så att platsen närmast byn/staden
  /// alltid ligger i samma rad som grannkolumnernas enda platsrad.
  Widget _aboveCell(int col, double sectionHeight) {
    return SizedBox(
      width: unit,
      height: sectionHeight,
      child: col.isEven
          ? _settlementSiteStack(col, BuildingRow.above)
          : _junctionSlot(col, BuildingRow.above),
    );
  }

  /// Motsvarande för nedanför-sektionen, topp-justerad.
  Widget _belowCell(int col, double sectionHeight) {
    return SizedBox(
      width: unit,
      height: sectionHeight,
      child: col.isEven
          ? _settlementSiteStack(col, BuildingRow.below)
          : _junctionSlot(col, BuildingRow.below),
    );
  }

  Widget _junctionSlot(int col, BuildingRow row) {
    final region = board.regionAt(col, row);
    final isPendingJunction = interactive && col == pendingRegionJunction;
    final child = region != null
        ? _regionWithExpansionSlot(region, col, row)
        : (isPendingJunction ? _pendingRegionSlot(row) : const SizedBox());
    return Align(
      alignment: row == BuildingRow.above ? Alignment.bottomCenter : Alignment.topCenter,
      child: SizedBox(width: unit, height: unit, child: child),
    );
  }

  /// Wrappar [_region] med ett litet hörn-märke (uppe till höger, så
  /// varken +/- knapparna eller resurspärlorna längst ner skyms) för en
  /// eventuell landskapsutbyggnad (t.ex. Guldgömma, se
  /// [RealmBoard.regionExpansionAt]). Till skillnad från de vanliga
  /// byggplatserna (som alltid visar en tom platshållare) visas den
  /// tomma drop-ytan bara MEDAN ett landskapsutbyggnadskort faktiskt
  /// dras ÖVER EN REGION AV MATCHANDE RESURSTYP ([_draggingRegionExpansion],
  /// kortets [GameCard.resource] måste stämma med regionens – Guldgömma
  /// får bara plats på Guldfält) – annars skulle varenda region på
  /// brädet permanent få ett extra `DragTarget<GameCard>` i trädet,
  /// vilket bland annat stör tester/kod som räknar drop-mål generiskt
  /// (bara 1 fysisk kopia av Guldgömma finns i hela spelet, så den
  /// permanenta platshållaren gav väldigt lite värde ändå). En redan
  /// utplacerad utbyggnad visas alltid, oavsett dragläge – även på
  /// motståndarens (icke-interaktiva) rike, som ren information.
  Widget _regionWithExpansionSlot(PlacedCard region, int column, BuildingRow row) {
    final regionView = _region(region, column, row);
    final expansion = board.regionExpansionAt(column, row);
    final showEmptySlot = expansion == null &&
        interactive &&
        _draggingRegionExpansion &&
        draggingCard!.resource == region.card.resource;
    if (expansion == null && !showEmptySlot) return regionView;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        regionView,
        Positioned(
          right: -unit * 0.08,
          top: -unit * 0.08,
          width: unit * 0.5,
          height: unit * 0.5,
          child: expansion != null
              ? RegionExpansionCardView(
                  card: expansion.card,
                  stored: expansion.storedResources,
                  onAdjust: interactive && onAdjustRegionExpansion != null
                      ? (delta) => onAdjustRegionExpansion!(column, row, delta)
                      : null)
              : _regionExpansionDropTarget(column, row, region.card.resource),
        ),
      ],
    );
  }

  Widget _regionExpansionDropTarget(
      int column, BuildingRow row, ResourceType regionResource) {
    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) =>
          details.data.category == CardCategory.regionExpansion &&
          details.data.resource == regionResource,
      onAcceptWithDetails: (details) => onRequestBuildConfirm?.call(
        details.data,
        () => onDropRegionExpansion?.call(column, row, details.data),
        blockedReason:
            buildRequirementBlockedReason(details.data, board, column, row),
      ),
      builder: (context, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;
        return BuildingSiteView(
            highlighted: isHovering || _draggingRegionExpansion,
            hovering: isHovering);
      },
    );
  }

  Widget _spineCell(int col) {
    if (col.isEven) return _settlementSpine(col);
    final isFrontier =
        col == board.leftmostColumn - 1 || col == board.rightmostColumn + 1;
    return SizedBox(
        width: unit, height: unit, child: _roadSlot(col, board.roads[col], isFrontier));
  }

  Widget _settlementSpine(int col) {
    final node = board.settlementAt(col);
    if (node != null) {
      return SizedBox(width: unit, height: unit, child: _settlementSlot(col, node));
    }

    // Ingen by/stad här – kolla om det är en giltig "spökby"-plats
    // bortom en redan utplacerad hängande väg.
    final isWestPhantom = col == board.leftmostColumn - 2 &&
        board.roads.containsKey(board.leftmostColumn - 1);
    final isEastPhantom = col == board.rightmostColumn + 2 &&
        board.roads.containsKey(board.rightmostColumn + 1);

    if (interactive && (isWestPhantom || isEastPhantom)) {
      return SizedBox(
        width: unit,
        height: unit,
        child: DragTarget<GameCard>(
          onWillAcceptWithDetails: (details) =>
              details.data.category == CardCategory.settlement,
          onAcceptWithDetails: (details) => onRequestBuildConfirm?.call(
            details.data,
            () => onDropSettlement?.call(col, details.data),
          ),
          builder: (context, candidates, rejected) {
            final isHovering = candidates.isNotEmpty;
            return BuildingSiteView(
                highlighted: isHovering || _draggingSettlement,
                hovering: isHovering);
          },
        ),
      );
    }

    return SizedBox(width: unit, height: unit);
  }

  Widget _settlementSlot(int column, SettlementNode node) {
    // Se kommentaren i _roadSlot – samma PopIn-utan-Key-resonemang gäller
    // här (både för en helt ny by och för en stadsuppgradering: bytet
    // by→stad byter kort-widget, alltså ny montering och ny intoning).
    final view = PopIn(child: SettlementCardView(card: node.center.card));
    if (!interactive || node.isCity) return view;

    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) =>
          details.data.category == CardCategory.city,
      onAcceptWithDetails: (details) => onRequestBuildConfirm?.call(
        details.data,
        () => onDropCityUpgrade?.call(column, details.data),
      ),
      builder: (context, candidates, rejected) {
        // Byggnadskortets egen bild ska alltid synas; vi lägger bara på
        // en glödande ram ovanpå när ett stadskort dras.
        final isHovering = candidates.isNotEmpty;
        return Stack(
          fit: StackFit.expand,
          children: [
            view,
            if (isHovering || _draggingCity)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFF7CBF6A),
                      width: isHovering ? 3 : 2),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Tom platshållare för ett av de väntande regionkorten (regelhäftet
  /// s. 8) – bara aktiv för den knutpunkt som just fick en ny by. Inget
  /// bekräftelsekort här – regionerna är redan betalda (dras
  /// automatiskt vid by-bygget), bara oplacerade.
  Widget _pendingRegionSlot(BuildingRow row) {
    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) =>
          details.data.category == CardCategory.region,
      onAcceptWithDetails: (details) =>
          onDropPendingRegion?.call(row, details.data),
      builder: (context, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;
        return BuildingSiteView(
            highlighted: isHovering || _draggingRegion, hovering: isHovering);
      },
    );
  }

  Widget _roadSlot(int col, PlacedCard? road, bool isFrontier) {
    // PopIn utan Key: en tom→byggd övergång byter widget-typ på den här
    // trädpositionen (från DragTarget/SizedBox till PopIn), så Flutter
    // monterar den fräscht och spelar upp intoningen – ett Omlokaliserings-
    // byte som bara flyttar en redan synlig väg behåller samma typ här
    // och blinkar därför inte om (se motståndaren-ser-actions-designen).
    if (road != null) return const PopIn(child: RoadCardView());
    if (!interactive || !isFrontier) return const SizedBox();

    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) =>
          details.data.category == CardCategory.road,
      onAcceptWithDetails: (details) => onRequestBuildConfirm?.call(
        details.data,
        () => onDropRoad?.call(col, details.data),
      ),
      builder: (context, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;
        return BuildingSiteView(
            highlighted: isHovering || _draggingRoad, hovering: isHovering);
      },
    );
  }

  /// Byggplatserna för en by/stad, staplade i egna, fullstora rader
  /// (inte förminskade sida vid sida) – en stad har 2 platser i samma
  /// riktning. Plats 0 (den ursprungliga byggplatsen) ligger alltid
  /// närmast byn/staden, plats 1 (stadens nya, tillkomna plats) längre
  /// bort – se [SettlementNode.upgradeToCity].
  Widget _settlementSiteStack(int col, BuildingRow row) {
    final node = board.settlementAt(col);
    if (node == null) return const SizedBox();
    final sites = row == BuildingRow.above ? node.aboveSites : node.belowSites;
    final order = row == BuildingRow.above
        ? [for (var i = sites.length - 1; i >= 0; i--) i] // längst bort först (överst)
        : [for (var i = 0; i < sites.length; i++) i]; // närmast spinan först (överst)

    return Column(
      mainAxisAlignment:
          row == BuildingRow.above ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        for (var i = 0; i < order.length; i++) ...[
          SizedBox(
              width: unit,
              height: unit,
              child: _buildingSite(col, row, order[i], sites[order[i]])),
          if (i != order.length - 1) SizedBox(height: gap),
        ],
      ],
    );
  }

  Widget _buildingSite(
      int column, BuildingRow row, int slotIndex, PlacedCard? placed) {
    if (placed != null) {
      final card = _expansionCard(placed, column, row, slotIndex);
      // En redan bebyggd plats går också att släppa ett nytt kort på –
      // du får då byta ut det gamla mot det nya (kostar det nya kortets
      // fulla pris, det gamla hamnar i slänghögen, se
      // GameNotifier.dropExpansion) – precis som en tom platshållare,
      // bara med kortet ovanpå i stället för BuildingSiteView. Bara när
      // [allowReplaceExpansion] är sant (minst ett tema aktivt) – annars
      // är en upptagen plats inte ett giltigt drop-mål alls.
      if (!interactive || !allowReplaceExpansion) return card;
      return DragTarget<GameCard>(
        onWillAcceptWithDetails: (details) =>
            details.data.category == CardCategory.expansion ||
            details.data.category == CardCategory.cityExpansion,
        onAcceptWithDetails: (details) => onRequestBuildConfirm?.call(
          details.data,
          () => onDropExpansion?.call(column, row, slotIndex, details.data),
          replacedCard: placed.card,
          blockedReason: buildRequirementBlockedReason(
              details.data, board, column, row, slotIndex),
        ),
        builder: (context, candidates, rejected) => card,
      );
    }
    if (!interactive) return const BuildingSiteView();

    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) =>
          details.data.category == CardCategory.expansion ||
          details.data.category == CardCategory.cityExpansion,
      onAcceptWithDetails: (details) => onRequestBuildConfirm?.call(
        details.data,
        () => onDropExpansion?.call(column, row, slotIndex, details.data),
        blockedReason: buildRequirementBlockedReason(
            details.data, board, column, row, slotIndex),
      ),
      builder: (context, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;
        return BuildingSiteView(
            highlighted: isHovering || _draggingExpansion,
            hovering: isHovering);
      },
    );
  }

  Widget _region(PlacedCard placed, int column, BuildingRow row) {
    final canSelect =
        relocationActive && interactive && onSelectRelocationTarget != null;
    final canSelectForRearrangement = startingRegionRearrangementActive &&
        interactive &&
        onSelectStartingRegionRearrangementTarget != null;
    // Se kommentaren i _roadSlot – en ny region på en tidigare tom
    // knutpunkt byter widget-typ här och toppas därför korrekt in.
    final view = PopIn(
      child: RegionCardView(
        card: placed.card,
        stored: placed.storedResources,
        // +/- knapparna stängs av under Omlokalisering/regionomflyttning:
        // annars skulle ett tryck på kortets bakgrund (för att välja det
        // till bytet) och ett tryck på en +/- knapp konkurrera om samma
        // yta.
        onAdjust: interactive &&
                onAdjustRegion != null &&
                !relocationActive &&
                !startingRegionRearrangementActive
            ? (delta) => onAdjustRegion!(column, row, delta)
            : null,
        onTap: canSelect
            ? () => onSelectRelocationTarget!(
                RelocationTargetKind.region, column, row, 0)
            : canSelectForRearrangement
                ? () => onSelectStartingRegionRearrangementTarget!(column, row)
                : null,
      ),
    );
    final selected = (relocationActive &&
            relocationFirst?.kind == RelocationTargetKind.region &&
            relocationFirst?.column == column &&
            relocationFirst?.row == row) ||
        (startingRegionRearrangementActive &&
            startingRegionRearrangementFirst?.column == column &&
            startingRegionRearrangementFirst?.row == row);
    return selected ? _withSelectionRing(view) : view;
  }

  Widget _expansionCard(
      PlacedCard placed, int column, BuildingRow row, int slotIndex) {
    final canSelect =
        relocationActive && interactive && onSelectRelocationTarget != null;
    final canPickForFeud = feudBuildingPickActive &&
        interactive &&
        onSelectFeudBuilding != null &&
        placed.card.isBuilding;
    final canPickForPirateShip = pirateShipDiscardActive &&
        interactive &&
        onSelectPirateShipDiscard != null &&
        placed.card.expansionKind == ExpansionKind.tradeShip;
    final canPickForRiots = riotsUnitPickActive &&
        interactive &&
        onSelectRiotsUnit != null &&
        (placed.card.strengthPoints > 0 || placed.card.commercePoints > 0);
    final attackCardQualifies = switch (pendingAttackCard) {
      AttackCardKind.archer => placed.card.strengthPoints > 0,
      AttackCardKind.arsonist => placed.card.isBuilding,
      null => false,
    };
    final canPickForAttackCard = pendingAttackCard != null &&
        interactive &&
        onSelectAttackCardUnit != null &&
        attackCardQualifies;
    // Se kommentaren i _roadSlot – en ny utbyggnad på en tidigare tom
    // byggplats byter widget-typ här och toppas därför korrekt in.
    final view = PopIn(
      child: ExpansionCardView(
        card: placed.card,
        showCost: false,
        onTap: canSelect
            ? () => onSelectRelocationTarget!(
                RelocationTargetKind.expansion, column, row, slotIndex)
            : canPickForFeud
                ? () => onSelectFeudBuilding!(column, row, slotIndex)
                : canPickForPirateShip
                    ? () => onSelectPirateShipDiscard!(column, row, slotIndex)
                    : canPickForRiots
                        ? () => onSelectRiotsUnit!(column, row, slotIndex)
                        : canPickForAttackCard
                            ? () => onSelectAttackCardUnit!(
                                column, row, slotIndex)
                            : null,
      ),
    );
    final selected = (relocationActive &&
            relocationFirst?.kind == RelocationTargetKind.expansion &&
            relocationFirst?.column == column &&
            relocationFirst?.row == row &&
            relocationFirst?.slotIndex == slotIndex) ||
        (feudBuildingPickActive &&
            feudPickedBuilding?.column == column &&
            feudPickedBuilding?.row == row &&
            feudPickedBuilding?.slotIndex == slotIndex) ||
        (riotsUnitPickActive &&
            riotsPickedUnit?.column == column &&
            riotsPickedUnit?.row == row &&
            riotsPickedUnit?.slotIndex == slotIndex) ||
        (pendingAttackCard != null &&
            attackCardPickedUnit?.column == column &&
            attackCardPickedUnit?.row == row &&
            attackCardPickedUnit?.slotIndex == slotIndex);
    return selected ? _withSelectionRing(view) : view;
  }

  /// Gul ram runt det först valda kortet under Omlokalisering (se
  /// [GameState.relocationFirst]) tills det andra trycket genomför
  /// bytet.
  Widget _withSelectionRing(Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber, width: 3),
            ),
          ),
        ),
      ],
    );
  }
}
