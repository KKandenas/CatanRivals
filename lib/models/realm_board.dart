import 'game_card.dart';
import 'hex_coordinate.dart';

/// Ett kortexemplar som är utplacerat på ett rike – kortets definition
/// ([card]) plus var det ligger och hur det är roterat.
///
/// Rotation (0–5) representerar de sex sätt ett landskapskort kan vändas
/// på i sin hexagon-position; behövs bl.a. för att räkna ut vilka kort som
/// gränsar till en given väg/by-plats.
class PlacedCard {
  final GameCard card;
  final HexCoordinate position;
  final int rotation;

  const PlacedCard({
    required this.card,
    required this.position,
    this.rotation = 0,
  });

  PlacedCard copyWith({GameCard? card, HexCoordinate? position, int? rotation}) {
    return PlacedCard(
      card: card ?? this.card,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
        'card': card.toJson(),
        'position': position.toJson(),
        'rotation': rotation,
      };

  factory PlacedCard.fromJson(Map<String, dynamic> json) => PlacedCard(
        card: GameCard.fromJson(Map<String, dynamic>.from(json['card'] as Map)),
        position:
            HexCoordinate.fromJson(Map<String, dynamic>.from(json['position'] as Map)),
        rotation: json['rotation'] as int? ?? 0,
      );
}

/// En spelares rike (Fyrstendöme) – rutnätet av utplacerade kort.
///
/// Modellerar just nu ett enda rutnät av [HexCoordinate] -> [PlacedCard].
/// Exakta regler för var byar/vägar får placeras i förhållande till
/// landskapshexagonerna läggs till i ett senare steg, när regelhäftet
/// finns tillgängligt.
class RealmBoard {
  final String ownerId;
  final Map<HexCoordinate, PlacedCard> _grid;

  RealmBoard({required this.ownerId, Map<HexCoordinate, PlacedCard>? grid})
      : _grid = grid ?? {};

  /// Oföränderlig vy av rutnätet.
  Map<HexCoordinate, PlacedCard> get grid => Map.unmodifiable(_grid);

  PlacedCard? cardAt(HexCoordinate position) => _grid[position];

  bool isOccupied(HexCoordinate position) => _grid.containsKey(position);

  /// Placerar ett kort på given position. Kastar [StateError] om positionen
  /// redan är upptagen.
  void placeCard(HexCoordinate position, PlacedCard placedCard) {
    if (isOccupied(position)) {
      throw StateError('Position $position är redan upptagen.');
    }
    _grid[position] = placedCard;
  }

  PlacedCard? removeCard(HexCoordinate position) => _grid.remove(position);

  List<PlacedCard> get regions =>
      _grid.values.where((p) => p.card.type == CardType.region).toList();

  /// De utplacerade kort som gränsar till given position.
  List<PlacedCard> neighborsOf(HexCoordinate position) => position.neighbors
      .map((n) => _grid[n])
      .whereType<PlacedCard>()
      .toList();

  int get totalVictoryPoints =>
      _grid.values.fold(0, (sum, p) => sum + p.card.victoryPoints);

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'grid': _grid.entries
            .map((e) => {
                  'position': e.key.toJson(),
                  'placedCard': e.value.toJson(),
                })
            .toList(),
      };

  factory RealmBoard.fromJson(Map<String, dynamic> json) {
    final entries = (json['grid'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map((e) => PlacedCard.fromJson(
            Map<String, dynamic>.from(e['placedCard'] as Map)))
        .map((placed) => MapEntry(placed.position, placed));
    return RealmBoard(
      ownerId: json['ownerId'] as String,
      grid: Map.fromEntries(entries),
    );
  }
}
