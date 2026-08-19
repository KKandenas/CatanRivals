import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'region_card_view.dart';
import 'settlement_card_view.dart';

/// Ritar ut ett [RealmBoard] enligt kolumnmodellen: byar/städer i en rad,
/// vägar mellan dem, och regioner delade diagonalt i hörnen ovanför och
/// nedanför (se "Rikets koordinatsystem"-skissen). Zoombart/panorerbart
/// via [InteractiveViewer]. Alla kort är kvadratiska.
///
/// Rent visuellt just nu – ingen interaktion (drag-and-drop, tryck för
/// detaljvy) ännu. `resourceStorage` är mock-data för pip-visningen tills
/// spelstate finns. `unit` styr kortstorleken – ett mindre värde används
/// för motståndarens kompakta rike.
class PrincipalityGrid extends StatelessWidget {
  final RealmBoard board;
  final Map<String, int> resourceStorage;
  final double unit;
  final double gap;

  const PrincipalityGrid({
    super.key,
    required this.board,
    this.resourceStorage = const {},
    this.unit = 78,
    this.gap = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (board.settlements.isEmpty) {
      return const Center(child: Text('Tomt rike'));
    }

    final left = board.leftmostColumn - 1;
    final right = board.rightmostColumn + 1;
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CatanColors.parchment, CatanColors.parchmentDark],
        ),
      ),
      child: InteractiveViewer(
        minScale: 0.6,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.all(200),
        child: Center(
          child: SizedBox(
            width: contentWidth + padding * 2,
            height: contentHeight + padding * 2,
            child: Padding(
              padding: const EdgeInsets.all(padding),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: columns),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumn(int col) {
    final isSettlementColumn = col.isEven;
    if (isSettlementColumn) {
      final node = board.settlementAt(col);
      if (node == null) {
        // Öppen kolumn utan by/stad (utanför rikets kant) – tomt utrymme.
        return SizedBox(width: unit, height: unit * 3 + gap * 2);
      }
      final width = node.isCity ? unit * 2 + gap : unit;
      return SizedBox(
        width: width,
        child: Column(
          children: [
            _siteRow(node.aboveSites, width),
            SizedBox(height: gap),
            SizedBox(height: unit, child: SettlementCardView(card: node.center.card)),
            SizedBox(height: gap),
            _siteRow(node.belowSites, width),
          ],
        ),
      );
    }

    final road = board.roads[col];
    final above = board.regionAt(col, BuildingRow.above);
    final below = board.regionAt(col, BuildingRow.below);
    return SizedBox(
      width: unit,
      child: Column(
        children: [
          SizedBox(height: unit, child: above != null ? _region(above) : const SizedBox()),
          SizedBox(height: gap),
          SizedBox(
            height: unit,
            child: road != null ? const RoadCardView() : const SizedBox(),
          ),
          SizedBox(height: gap),
          SizedBox(height: unit, child: below != null ? _region(below) : const SizedBox()),
        ],
      ),
    );
  }

  Widget _siteRow(List<PlacedCard?> sites, double width) {
    return SizedBox(
      height: unit,
      width: width,
      child: Row(
        children: [
          for (var i = 0; i < sites.length; i++) ...[
            Expanded(child: sites[i] != null ? _expansionCard(sites[i]!) : const BuildingSiteView()),
            if (i != sites.length - 1) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }

  Widget _region(PlacedCard placed) {
    final stored = resourceStorage[placed.card.id] ?? 0;
    return RegionCardView(card: placed.card, stored: stored);
  }

  Widget _expansionCard(PlacedCard placed) {
    // Enkel platshållare för bygg-/enhetskort tills en dedikerad vy finns.
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: CatanColors.woodFrame,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Text(
          placed.card.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, color: Colors.white),
        ),
      ),
    );
  }
}
