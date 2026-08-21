import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import 'expansion_card_view.dart';
import 'region_card_view.dart';
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
typedef BuildConfirmRequest = void Function(GameCard card, VoidCallback onConfirm);

/// Ritar ut ett [RealmBoard] enligt kolumnmodellen: byar/städer i en rad,
/// vägar mellan dem, och regioner delade diagonalt i hörnen ovanför och
/// nedanför (se "Rikets koordinatsystem"-skissen). Zoombart/panorerbart
/// via [InteractiveViewer]. Alla kort är kvadratiska.
///
/// `unit` styr kortstorleken – ett mindre värde används för
/// motståndarens kompakta rike.
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

  /// Knutpunkten (om någon) som just nu väntar på att få sina 2
  /// regionkort placerade (se [PendingRegionDropCallback]).
  final int? pendingRegionJunction;
  final PendingRegionDropCallback? onDropPendingRegion;

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
    this.pendingRegionJunction,
    this.onDropPendingRegion,
  });

  bool get _draggingRoad => draggingCard?.category == CardCategory.road;
  bool get _draggingSettlement =>
      draggingCard?.category == CardCategory.settlement;
  bool get _draggingCity => draggingCard?.category == CardCategory.city;
  bool get _draggingExpansion =>
      draggingCard?.category == CardCategory.expansion;
  bool get _draggingRegion => draggingCard?.category == CardCategory.region;

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
        _buildInteractiveContent(contentWidth, contentHeight, padding, content),
      ],
    );
  }

  Widget _buildInteractiveContent(double contentWidth, double contentHeight,
      double padding, Widget content) {
    return InteractiveViewer(
      // Pan/zoom stängs av på det interaktiva (egna) brädet: på
      // pekskärmar tävlar InteractiveViewers egen pan-gest med
      // LongPressDraggable om samma pekhändelser, och panorering
      // vinner ofta innan långtrycket hinner registreras – då går
      // det inte att dra ut kort alls. Motståndarens skrivskyddade
      // bräde (interactive: false) har inga dragbara mål, så där är
      // pan/zoom kvar för att kunna zooma in det.
      panEnabled: !interactive,
      scaleEnabled: !interactive,
      minScale: 0.6,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(200),
      child: Center(
        child: SizedBox(
          width: contentWidth + padding * 2,
          height: contentHeight + padding * 2,
          child: Padding(padding: EdgeInsets.all(padding), child: content),
        ),
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
        ? _region(region, col, row)
        : (isPendingJunction ? _pendingRegionSlot(row) : const SizedBox());
    return Align(
      alignment: row == BuildingRow.above ? Alignment.bottomCenter : Alignment.topCenter,
      child: SizedBox(width: unit, height: unit, child: child),
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
    final view = SettlementCardView(card: node.center.card);
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
    if (road != null) return const RoadCardView();
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
    if (placed != null) return _expansionCard(placed);
    if (!interactive) return const BuildingSiteView();

    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) =>
          details.data.category == CardCategory.expansion,
      onAcceptWithDetails: (details) => onRequestBuildConfirm?.call(
        details.data,
        () => onDropExpansion?.call(column, row, slotIndex, details.data),
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
    return RegionCardView(
      card: placed.card,
      stored: placed.storedResources,
      onAdjust: interactive && onAdjustRegion != null
          ? (delta) => onAdjustRegion!(column, row, delta)
          : null,
    );
  }

  Widget _expansionCard(PlacedCard placed) {
    return ExpansionCardView(card: placed.card, showCost: false);
  }
}
