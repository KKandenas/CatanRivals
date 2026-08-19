import 'game_card.dart';
import 'realm_board.dart';

/// En spelare – handkort, resurser, poäng och det egna riket.
class Player {
  final String id;
  final String name;
  final List<GameCard> hand;
  final Map<ResourceType, int> resources;
  final int victoryPoints;
  final RealmBoard principality;

  Player({
    required this.id,
    required this.name,
    List<GameCard>? hand,
    Map<ResourceType, int>? resources,
    this.victoryPoints = 0,
    RealmBoard? principality,
  })  : hand = hand ?? [],
        resources = resources ??
            {
              for (final type in ResourceType.values)
                if (type != ResourceType.none) type: 0,
            },
        principality = principality ?? RealmBoard(ownerId: id);

  int resourceCount(ResourceType type) => resources[type] ?? 0;

  Player copyWith({
    String? id,
    String? name,
    List<GameCard>? hand,
    Map<ResourceType, int>? resources,
    int? victoryPoints,
    RealmBoard? principality,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      resources: resources ?? this.resources,
      victoryPoints: victoryPoints ?? this.victoryPoints,
      principality: principality ?? this.principality,
    );
  }

  /// Returnerar en ny [Player] med `amount` mer av given resurs
  /// (negativt `amount` för att förbruka resurser).
  Player addResource(ResourceType type, int amount) {
    final updated = Map<ResourceType, int>.from(resources);
    updated[type] = (updated[type] ?? 0) + amount;
    return copyWith(resources: updated);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hand': hand.map((c) => c.toJson()).toList(),
        'resources': resources.map((type, count) => MapEntry(type.name, count)),
        'victoryPoints': victoryPoints,
        'principality': principality.toJson(),
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        hand: (json['hand'] as List? ?? [])
            .map((c) => GameCard.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        resources: (json['resources'] as Map? ?? {}).map(
          (type, count) =>
              MapEntry(ResourceType.values.byName(type as String), count as int),
        ),
        victoryPoints: json['victoryPoints'] as int? ?? 0,
        principality: RealmBoard.fromJson(
            Map<String, dynamic>.from(json['principality'] as Map)),
      );
}
