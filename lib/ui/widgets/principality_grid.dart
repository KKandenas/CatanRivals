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
  });

  bool get _draggingRoad => draggingCard?.category == CardCategory.road;
  bool get _draggingSettlement =>
      draggingCard?.category == CardCategory.settlement;
  bool get _draggingCity => draggingCard?.category == CardCategory.city;
  bool get _draggingExpansion =>
      draggingCard?.category == CardCategory.expansion;

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

    var contentWidth = 0.0;
    final columns = <Widget>[];
    for (var col = left; col <= right; col++) {
      final isCity = col.isEven && (board.settlementAt(col)?.isCity ?? false);
      final colWidth = isCity ? unit * 2 + gap : unit;
      columns.add(_buildColumn(col));
      contentWidth += colWidth;
      if (col != right) {
        columns.add(SizedBox(width: gap));
        contentWidth += gap;
      }
    }
    final contentHeight = unit * 3 + gap * 2;
    const padding = 20.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(CatanAssets.boardBackground, fit: BoxFit.cover),
        // Pergament-slöja ovanpå träteexturen, så att de tomma
        // byggplatsernas streckade kanter och korten fortfarande
        // syns tydligt – samma ljushet som den gamla gradienten hade.
        Container(color: CatanColors.parchment.withValues(alpha: 0.55)),
        _buildInteractiveContent(contentWidth, contentHeight, padding, columns),
      ],
    );
  }

  Widget _buildInteractiveContent(double contentWidth, double contentHeight,
      double padding, List<Widget> columns) {
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
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: columns),
          ),
        ),
      ),
    );
  }

  Widget _buildColumn(int col) {
    if (col.isEven) return _buildSettlementColumn(col);
    return _buildJunctionColumn(col);
  }

  Widget _buildSettlementColumn(int col) {
    final node = board.settlementAt(col);
    if (node != null) {
      final width = node.isCity ? unit * 2 + gap : unit;
      return SizedBox(
        width: width,
        child: Column(
          children: [
            _siteRow(col, BuildingRow.above, node.aboveSites, width),
            SizedBox(height: gap),
            SizedBox(height: unit, child: _settlementSlot(col, node)),
            SizedBox(height: gap),
            _siteRow(col, BuildingRow.below, node.belowSites, width),
          ],
        ),
      );
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
        height: unit * 3 + gap * 2,
        child: Center(
          child: SizedBox(
            height: unit,
            child: DragTarget<GameCard>(
              onWillAcceptWithDetails: (details) =>
                  details.data.category == CardCategory.settlement,
              onAcceptWithDetails: (details) =>
                  onDropSettlement?.call(col, details.data),
              builder: (context, candidates, rejected) {
                final isHovering = candidates.isNotEmpty;
                return BuildingSiteView(
                    highlighted: isHovering || _draggingSettlement,
                    hovering: isHovering);
              },
            ),
          ),
        ),
      );
    }

    return SizedBox(width: unit, height: unit * 3 + gap * 2);
  }

  Widget _settlementSlot(int column, SettlementNode node) {
    final view = SettlementCardView(card: node.center.card);
    if (!interactive || node.isCity) return view;

    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) =>
          details.data.category == CardCategory.city,
      onAcceptWithDetails: (details) =>
          onDropCityUpgrade?.call(column, details.data),
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

  Widget _buildJunctionColumn(int col) {
    final road = board.roads[col];
    final above = board.regionAt(col, BuildingRow.above);
    final below = board.regionAt(col, BuildingRow.below);
    final isFrontier =
        col == board.leftmostColumn - 1 || col == board.rightmostColumn + 1;

    return SizedBox(
      width: unit,
      child: Column(
        children: [
          SizedBox(
              height: unit,
              child: above != null ? _region(above) : const SizedBox()),
          SizedBox(height: gap),
          SizedBox(height: unit, child: _roadSlot(col, road, isFrontier)),
          SizedBox(height: gap),
          SizedBox(
              height: unit,
              child: below != null ? _region(below) : const SizedBox()),
        ],
      ),
    );
  }

  Widget _roadSlot(int col, PlacedCard? road, bool isFrontier) {
    if (road != null) return const RoadCardView();
    if (!interactive || !isFrontier) return const SizedBox();

    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) =>
          details.data.category == CardCategory.road,
      onAcceptWithDetails: (details) => onDropRoad?.call(col, details.data),
      builder: (context, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;
        return BuildingSiteView(
            highlighted: isHovering || _draggingRoad, hovering: isHovering);
      },
    );
  }

  Widget _siteRow(
      int column, BuildingRow row, List<PlacedCard?> sites, double width) {
    return SizedBox(
      height: unit,
      width: width,
      child: Row(
        children: [
          for (var i = 0; i < sites.length; i++) ...[
            Expanded(child: _buildingSite(column, row, i, sites[i])),
            if (i != sites.length - 1) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }

  Widget _buildingSite(
      int column, BuildingRow row, int slotIndex, PlacedCard? placed) {
    if (placed != null) return _expansionCard(placed);
    if (!interactive) return const BuildingSiteView();

    return DragTarget<GameCard>(
      onWillAcceptWithDetails: (details) =>
          details.data.category == CardCategory.expansion,
      onAcceptWithDetails: (details) =>
          onDropExpansion?.call(column, row, slotIndex, details.data),
      builder: (context, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;
        return BuildingSiteView(
            highlighted: isHovering || _draggingExpansion,
            hovering: isHovering);
      },
    );
  }

  Widget _region(PlacedCard placed) {
    return RegionCardView(card: placed.card, stored: placed.storedResources);
  }

  Widget _expansionCard(PlacedCard placed) {
    return ExpansionCardView(card: placed.card, showCost: false);
  }
}
