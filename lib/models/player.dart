import 'game_card.dart';
import 'realm_board.dart';

/// En spelare – handkort, poäng och det egna riket.
///
/// Resurser lagras inte här som en egen pool, utan direkt på varje
/// regionkort i [principality] (se [PlacedCard.storedResources]) – det
/// är så det fysiska spelet faktiskt fungerar (regelhäftet s. 3), och
/// gör [principality] till den enda sanningskällan.
class Player {
  final String id;
  final String name;
  final List<GameCard> hand;
  final int victoryPoints;
  final RealmBoard principality;

  Player({
    required this.id,
    required this.name,
    List<GameCard>? hand,
    this.victoryPoints = 0,
    RealmBoard? principality,
  })  : hand = hand ?? [],
        principality = principality ?? RealmBoard(ownerId: id);

  int resourceCount(ResourceType type) => principality.resourceTotal(type);

  Player copyWith({
    String? id,
    String? name,
    List<GameCard>? hand,
    int? victoryPoints,
    RealmBoard? principality,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      victoryPoints: victoryPoints ?? this.victoryPoints,
      principality: principality ?? this.principality,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hand': hand.map((c) => c.toJson()).toList(),
        'victoryPoints': victoryPoints,
        'principality': principality.toJson(),
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        hand: (json['hand'] as List? ?? [])
            .map((c) => GameCard.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        victoryPoints: json['victoryPoints'] as int? ?? 0,
        principality: RealmBoard.fromJson(
            Map<String, dynamic>.from(json['principality'] as Map)),
      );
}
