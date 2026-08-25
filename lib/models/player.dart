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

  /// Om spelaren redan tagit sina 3 starthandkort från en draghög
  /// (regelhäftet s. 6). Ett eget flagg-fält i stället för att kolla
  /// `hand.isEmpty`, eftersom handen kan bli tom även under vanligt
  /// spel (spelar man alla kort) utan att starthands-fasen ska räknas
  /// om.
  final bool hasDrawnStartingHand;

  /// Ditt EGET ansikte-upp-kort (t.ex. Gulderans Köpmansgille, se
  /// [GameNotifier._resetDecks]) – varje spelare har sin egen, separata
  /// plats med som mest 1 kort, i stället för en delad hög båda kan
  /// bygga från. `null` när inget tema med den här mekaniken är aktivt,
  /// eller när kortet redan är byggt. Byggs kortet om (se
  /// [GameNotifier.dropExpansion]s "byt ut"-mekanik) läggs det tillbaka
  /// hit i stället för i slänghögen (se
  /// [GameNotifier._placeExpansionCardAndSync]) – det är fortfarande
  /// samma spelares kort, bara oplacerat igen.
  final GameCard? faceUpExpansionCard;

  Player({
    required this.id,
    required this.name,
    List<GameCard>? hand,
    this.victoryPoints = 0,
    RealmBoard? principality,
    this.hasDrawnStartingHand = false,
    this.faceUpExpansionCard,
  })  : hand = hand ?? [],
        principality = principality ?? RealmBoard(ownerId: id);

  int resourceCount(ResourceType type) => principality.resourceTotal(type);

  /// Summan av ALLA lagrade resurser, oavsett typ (se
  /// [RealmBoard.totalStoredResources]).
  int get totalResourceCount => principality.totalStoredResources;

  Player copyWith({
    String? id,
    String? name,
    List<GameCard>? hand,
    int? victoryPoints,
    RealmBoard? principality,
    bool? hasDrawnStartingHand,
    GameCard? faceUpExpansionCard,
    bool clearFaceUpExpansionCard = false,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      victoryPoints: victoryPoints ?? this.victoryPoints,
      principality: principality ?? this.principality,
      hasDrawnStartingHand: hasDrawnStartingHand ?? this.hasDrawnStartingHand,
      faceUpExpansionCard: clearFaceUpExpansionCard
          ? null
          : (faceUpExpansionCard ?? this.faceUpExpansionCard),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hand': hand.map((c) => c.toJson()).toList(),
        'victoryPoints': victoryPoints,
        'principality': principality.toJson(),
        'hasDrawnStartingHand': hasDrawnStartingHand,
        if (faceUpExpansionCard != null)
          'faceUpExpansionCard': faceUpExpansionCard!.toJson(),
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
        hasDrawnStartingHand: json['hasDrawnStartingHand'] as bool? ?? false,
        faceUpExpansionCard: json['faceUpExpansionCard'] == null
            ? null
            : GameCard.fromJson(
                Map<String, dynamic>.from(json['faceUpExpansionCard'] as Map)),
      );
}
