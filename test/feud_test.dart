import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar styrkeövertags-jämförelsen ([GameState.strengthAdvantagePlayerId]),
/// [RealmBoard.removeExpansion], och händelsekorten Fejd/Brödrafejd
/// (regelhäftets referenskort: den med styrkeövertaget agerar mot den
/// utan, se game_notifier.dart).
void main() {
  ProviderContainer readyContainer() => ProviderContainer();

  /// Ger [player]s rike ett hjältekort med [strength] styrkepoäng på en
  /// tom byggplats (kolumn 0, ovanför) – enda sättet att kontrollera
  /// [GameState.strengthAdvantagePlayerId] deterministiskt utan att
  /// bygga upp ett helt spelförlopp.
  void giveStrength(Player player, int strength) {
    player.principality.placeExpansion(
      0,
      BuildingRow.above,
      0,
      PlacedCard(
          card: BasicSetCards.harald.copyWith(strengthPoints: strength)),
    );
  }

  /// Ger [player]s rike en byggnad (Kloster) på en tom byggplats
  /// (kolumn 2, nedanför) – krävs för att [GameNotifier.startFeudBuildingPick]
  /// ska aktiveras alls (se [RealmBoard.hasAnyBuilding]).
  void giveBuilding(Player player) {
    player.principality.placeExpansion(
        2, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.abbey));
  }

  void forceFeudCard(ProviderContainer container, GameCard card) {
    final notifier = container.read(gameProvider.notifier);
    notifier.state =
        container.read(gameProvider).copyWith(drawnEventCard: card);
  }

  group('GameState.strengthAdvantagePlayerId', () {
    test('oavgjort (båda 0 styrka) ger null', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      expect(container.read(gameProvider).strengthAdvantagePlayerId, isNull);
    });

    test('du har övertaget om din styrka är högre', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).you, 2);
      expect(container.read(gameProvider).strengthAdvantagePlayerId, 'you');
    });

    test('motståndaren har övertaget om hens styrka är högre', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 3);
      expect(
          container.read(gameProvider).strengthAdvantagePlayerId, 'opponent');
    });
  });

  group('RealmBoard.removeExpansion', () {
    test('tar bort och returnerar kortet på en upptagen byggplats', () {
      final board = RealmBoard(ownerId: 'test');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeExpansion(0, BuildingRow.above, 0,
          const PlacedCard(card: BasicSetCards.abbey));

      final removed = board.removeExpansion(0, BuildingRow.above, 0);

      expect(removed?.card.id, BasicSetCards.abbey.id);
      expect(board.settlementAt(0)!.aboveSites[0], isNull);
    });

    test('returnerar null för en redan tom byggplats', () {
      final board = RealmBoard(ownerId: 'test');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));

      expect(board.removeExpansion(0, BuildingRow.above, 0), isNull);
    });

    test('kastar StateError om det inte finns någon by/stad i kolumnen', () {
      final board = RealmBoard(ownerId: 'test');

      expect(() => board.removeExpansion(0, BuildingRow.above, 0),
          throwsStateError);
    });
  });

  group('RealmBoard.hasAnyBuilding', () {
    test('false för ett rike utan några utbyggnadskort alls', () {
      final board = RealmBoard(ownerId: 'test');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));

      expect(board.hasAnyBuilding, isFalse);
    });

    test('false när riket bara har skepp/hjältar, inga byggnader', () {
      final board = RealmBoard(ownerId: 'test');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeExpansion(0, BuildingRow.above, 0,
          const PlacedCard(card: BasicSetCards.austin));

      expect(board.hasAnyBuilding, isFalse);
    });

    test('true så fort minst en byggnad är utplacerad', () {
      final board = RealmBoard(ownerId: 'test');
      board.placeSettlement(
          0, const PlacedCard(card: BasicSetCards.settlement));
      board.placeExpansion(0, BuildingRow.above, 0,
          const PlacedCard(card: BasicSetCards.austin));
      board.placeExpansion(0, BuildingRow.below, 0,
          const PlacedCard(card: BasicSetCards.abbey));

      expect(board.hasAnyBuilding, isTrue);
    });
  });

  group('Fejd', () {
    test('startFeudBuildingPick är no-op utan uppslaget händelsekort', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      final notifier = container.read(gameProvider.notifier);

      notifier.startFeudBuildingPick();

      expect(container.read(gameProvider).feudBuildingPickActive, isFalse);
    });

    test('startFeudBuildingPick är no-op vid oavgjort', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      forceFeudCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);

      notifier.startFeudBuildingPick();

      expect(container.read(gameProvider).feudBuildingPickActive, isFalse);
    });

    test('startFeudBuildingPick är no-op om DU har övertaget', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).you, 2);
      forceFeudCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);

      notifier.startFeudBuildingPick();

      expect(container.read(gameProvider).feudBuildingPickActive, isFalse);
    });

    test('startFeudBuildingPick aktiveras när motståndaren har övertaget',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      giveBuilding(container.read(gameProvider).you);
      forceFeudCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.startFeudBuildingPick();

      expect(error, isNull);
      expect(container.read(gameProvider).feudBuildingPickActive, isTrue);
    });

    test(
        'startFeudBuildingPick är no-op om du inte har någon byggnad att ta bort (bara skepp/hjältar eller inget alls)',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      // Ingen byggnad placerad hos "you" – bara starthänder/regioner.
      forceFeudCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.startFeudBuildingPick();

      expect(error, isNull);
      expect(container.read(gameProvider).feudBuildingPickActive, isFalse);
    });

    test('selectFeudBuilding avvisar hjältar/skepp', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      giveBuilding(container.read(gameProvider).you);
      container.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.austin));
      forceFeudCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);
      notifier.startFeudBuildingPick();

      final error = notifier.selectFeudBuilding(0, BuildingRow.above, 0);

      expect(error, 'Fejd gäller bara byggnader, inte skepp eller hjältar.');
      expect(container.read(gameProvider).feudPickedBuilding, isNull);
    });

    test(
        'selectFeudBuilding godtar en byggnad, resolveFeudBuildingRemoval flyttar den till vald draghög',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      container.read(gameProvider).you.principality.placeExpansion(
          2, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.abbey));
      forceFeudCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);
      notifier.startFeudBuildingPick();

      expect(notifier.selectFeudBuilding(2, BuildingRow.below, 0), isNull);
      final picked = container.read(gameProvider).feudPickedBuilding;
      expect(picked, isNotNull);
      expect(picked!.column, 2);

      final beforeCount = notifier.drawStack(1).length;
      final beforeCenterCount = container.read(gameProvider).centerStacks['draw2'];
      final error = notifier.resolveFeudBuildingRemoval(1);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.feudBuildingPickActive, isFalse);
      expect(state.feudPickedBuilding, isNull);
      expect(state.drawnEventCard, isNull);
      expect(state.you.principality.settlementAt(2)!.belowSites[0], isNull);
      expect(notifier.drawStack(1).length, beforeCount + 1);
      expect(notifier.drawStack(1).last.id, BasicSetCards.abbey.id);
      expect(state.centerStacks['draw2'], beforeCenterCount! + 1);
    });

    test('att bygga vidare är blockerat medan Fejds bygg-väljare är aktiv',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      giveBuilding(container.read(gameProvider).you);
      forceFeudCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);
      notifier.startFeudBuildingPick();
      expect(container.read(gameProvider).feudBuildingPickActive, isTrue);

      final error = notifier.dropRoad(3, BasicSetCards.road);

      expect(error, isNotNull);
    });

    test('cancelFeudBuildingPick avbryter utan att ändra riket', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      giveBuilding(container.read(gameProvider).you);
      forceFeudCard(container, BasicSetCards.feud);
      final notifier = container.read(gameProvider.notifier);
      notifier.startFeudBuildingPick();
      expect(container.read(gameProvider).feudBuildingPickActive, isTrue);

      notifier.cancelFeudBuildingPick();

      expect(container.read(gameProvider).feudBuildingPickActive, isFalse);
    });
  });

  group('Brödrafejd', () {
    test('startFraternalFeudsPick är no-op online även om du har övertaget',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).you, 2);
      forceFeudCard(container, BasicSetCards.fraternalFeuds);
      final notifier = container.read(gameProvider.notifier);
      notifier.state =
          container.read(gameProvider).copyWith(mode: SessionMode.host);

      notifier.startFraternalFeudsPick();

      expect(container.read(gameProvider).fraternalFeudsPicking, isFalse);
    });

    test('startFraternalFeudsPick är no-op om motståndaren har övertaget',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).opponent, 2);
      forceFeudCard(container, BasicSetCards.fraternalFeuds);
      final notifier = container.read(gameProvider.notifier);

      notifier.startFraternalFeudsPick();

      expect(container.read(gameProvider).fraternalFeudsPicking, isFalse);
    });

    test('startFraternalFeudsPick aktiveras lokalt när du har övertaget', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).you, 2);
      forceFeudCard(container, BasicSetCards.fraternalFeuds);
      final notifier = container.read(gameProvider.notifier);

      final error = notifier.startFraternalFeudsPick();

      expect(error, isNull);
      expect(container.read(gameProvider).fraternalFeudsPicking, isTrue);
    });

    test(
        'pickFraternalFeudsCard flyttar 2 kort från motståndarens hand, sedan avslutas det automatiskt',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).you, 2);
      forceFeudCard(container, BasicSetCards.fraternalFeuds);
      final notifier = container.read(gameProvider.notifier);
      notifier.startFraternalFeudsPick();
      final hand =
          List<GameCard>.of(container.read(gameProvider).opponent.hand);
      expect(hand, hasLength(2));

      final error1 = notifier.pickFraternalFeudsCard(hand[0], 0);
      expect(error1, isNull);
      var state = container.read(gameProvider);
      expect(state.opponent.hand.contains(hand[0]), isFalse);
      expect(state.fraternalFeudsPicking, isTrue);
      expect(state.fraternalFeudsPicked, [hand[0]]);
      expect(notifier.drawStack(0).last.id, hand[0].id);

      final error2 = notifier.pickFraternalFeudsCard(hand[1], 2);
      expect(error2, isNull);
      state = container.read(gameProvider);
      expect(state.opponent.hand, isEmpty);
      expect(state.fraternalFeudsPicking, isFalse);
      expect(state.fraternalFeudsPicked, [hand[0], hand[1]]);
      expect(state.drawnEventCard, isNull);
      expect(notifier.drawStack(2).last.id, hand[1].id);
    });

    test('cancelFraternalFeudsPick avbryter utan att ändra motståndarens hand',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).you, 2);
      forceFeudCard(container, BasicSetCards.fraternalFeuds);
      final notifier = container.read(gameProvider.notifier);
      notifier.startFraternalFeudsPick();
      final handBefore =
          List<GameCard>.of(container.read(gameProvider).opponent.hand);

      notifier.cancelFraternalFeudsPick();

      final state = container.read(gameProvider);
      expect(state.fraternalFeudsPicking, isFalse);
      expect(state.opponent.hand, handBefore);
    });

    test(
        'att bygga vidare är blockerat medan Brödrafejds handväljare är aktiv',
        () {
      final container = readyContainer();
      addTearDown(container.dispose);
      giveStrength(container.read(gameProvider).you, 2);
      forceFeudCard(container, BasicSetCards.fraternalFeuds);
      final notifier = container.read(gameProvider.notifier);
      notifier.startFraternalFeudsPick();

      final error = notifier.dropRoad(3, BasicSetCards.road);

      expect(error, isNotNull);
    });
  });
}
