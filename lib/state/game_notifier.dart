import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_game.dart';
import '../models/models.dart';
import 'game_state.dart';

/// Spelets state-provider. Läs med `ref.watch(gameProvider)` och mutera
/// via `ref.read(gameProvider.notifier)`.
final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

/// Håller och muterar [GameState]: bygga vägar/byar/städer från
/// center-dragstaplarna, spela bygg-/enhetskort från handen, och
/// drag-state (vilket kort som just nu dras).
///
/// Metoderna som bygger något returnerar `null` vid lyckad byggnation
/// eller ett felmeddelande (t.ex. "Inte råd med X") som UI-lagret kan
/// visa i ett snackbar – notifiern har ingen BuildContext att visa det
/// själv med.
///
/// [RealmBoard] är fortfarande en muterbar klass (se realm_board.dart)
/// – vi skriver alltså till samma bräd-instans och byter sedan ut
/// `state` för att trigga ombyggnad, snarare än att bygga om hela
/// brädet immutabelt. En fullt immutabel spelbräde-modell är en större
/// omskrivning som får vänta till den behövs (t.ex. för ångra/logg).
class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() {
    return GameState(
      you: MockGame.buildYou(),
      opponent: MockGame.buildOpponent(),
      centerStacks: MockGame.centerStackCounts(),
    );
  }

  void startDrag(GameCard card) => state = state.copyWith(draggingCard: card);

  void endDrag() => state = state.copyWith(clearDraggingCard: true);

  bool _canAfford(GameCard card) {
    return card.buildingCost.entries.every((entry) => state.you.resourceCount(entry.key) >= entry.value);
  }

  Player _spend(Player player, GameCard card) {
    var updated = player;
    for (final entry in card.buildingCost.entries) {
      updated = updated.addResource(entry.key, -entry.value);
    }
    return updated;
  }

  /// Kollar att stapeln inte är slut och att spelaren har råd. Null om
  /// allt stämmer, annars ett felmeddelande.
  String? _checkStack(String stackKey, GameCard card) {
    if ((state.centerStacks[stackKey] ?? 0) <= 0) {
      return 'Inga fler ${card.name.toLowerCase()}or kvar i stapeln';
    }
    if (!_canAfford(card)) {
      return 'Inte råd med ${card.name}';
    }
    return null;
  }

  String? dropExpansion(int column, BuildingRow row, int slotIndex, GameCard card) {
    if (!state.you.hand.contains(card)) return null;
    if (!_canAfford(card)) return 'Inte råd med ${card.name}';

    state.you.principality.placeExpansion(column, row, slotIndex, PlacedCard(card: card));
    final updated = _spend(state.you.copyWith(hand: List.of(state.you.hand)..remove(card)), card);

    state = state.copyWith(you: updated, clearDraggingCard: true);
    return null;
  }

  String? dropRoad(int column, GameCard card) {
    final error = _checkStack('roads', card);
    if (error != null) return error;

    state.you.principality.placeRoad(column, PlacedCard(card: card));
    final updated = _spend(state.you, card);

    state = state.copyWith(
      you: updated,
      centerStacks: Map.of(state.centerStacks)..update('roads', (v) => v - 1),
      clearDraggingCard: true,
    );
    return null;
  }

  String? dropSettlement(int column, GameCard card) {
    final error = _checkStack('settlements', card);
    if (error != null) return error;

    final oldLeft = state.you.principality.leftmostColumn;
    final oldRight = state.you.principality.rightmostColumn;

    state.you.principality.placeSettlement(column, PlacedCard(card: card));

    // Regelhäftet s. 8: en ny by ger automatiskt de 2 översta korten
    // från regionstapeln, placerade i den nya, ännu tomma knutpunkten.
    final newJunction = column < oldLeft ? column - 1 : column + 1;
    final wasNewSettlementFurtherOut = column < oldLeft || column > oldRight;
    if (wasNewSettlementFurtherOut) {
      state.you.principality
          .placeRegion(newJunction, BuildingRow.above, PlacedCard(card: MockGame.drawRandomRegion()));
      state.you.principality
          .placeRegion(newJunction, BuildingRow.below, PlacedCard(card: MockGame.drawRandomRegion()));
    }

    final updated = _spend(state.you, card);

    state = state.copyWith(
      you: updated,
      centerStacks: Map.of(state.centerStacks)
        ..update('settlements', (v) => v - 1)
        ..update('regions', (v) => wasNewSettlementFurtherOut ? v - 2 : v),
      clearDraggingCard: true,
    );
    return null;
  }

  String? dropCityUpgrade(int column, GameCard card) {
    final error = _checkStack('cities', card);
    if (error != null) return error;

    state.you.principality.upgradeToCity(column, PlacedCard(card: card));
    final updated = _spend(state.you, card);

    state = state.copyWith(
      you: updated,
      centerStacks: Map.of(state.centerStacks)..update('cities', (v) => v - 1),
      clearDraggingCard: true,
    );
    return null;
  }
}
