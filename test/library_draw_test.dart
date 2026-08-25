import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Bibliotek (Utvecklingens tid, regelhäftet: "När du bygger
/// Biblioteket får du omedelbart välja ett kort från en draghög") – se
/// GameNotifier._maybeTriggerLibraryDraw/drawLibraryCard och
/// GameState.libraryDrawPending. Till skillnad från Guido/Gustavs
/// slänghögsval (se discard_pile_pick_test.dart) rör det här en riktig
/// draghög, så draghögarna görs tryckbara i CenterStacksStrip i stället
/// för en egen väljar-overlay.
void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfProgress});
    notifier.state = container.read(gameProvider).copyWith(diceRolled: true);
    container.read(gameProvider).you.principality
        .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    return container;
  }

  void giveLibrary(ProviderContainer container) {
    final notifier = container.read(gameProvider.notifier);
    notifier.state = container.read(gameProvider).copyWith(
        you: container.read(gameProvider).you.copyWith(hand: [
      ...container.read(gameProvider).you.hand,
      EraOfProgressCards.library
    ]));
  }

  test('att bygga Biblioteket sätter libraryDrawPending och blockerar vidare bygge',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveLibrary(container);

    final error = notifier.dropExpansion(
        0, BuildingRow.above, 0, EraOfProgressCards.library);

    expect(error, isNull);
    final state = container.read(gameProvider);
    expect(state.libraryDrawPending, isTrue);
    expect(state.canBuildRightNow, isFalse);
    expect(
        state.you.principality.settlementAt(0)!.aboveSites[0]!.card.baseId,
        EraOfProgressCards.library.id);
  });

  test('drawLibraryCard drar toppkortet från vald hög till handen', () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveLibrary(container);
    notifier.dropExpansion(0, BuildingRow.above, 0, EraOfProgressCards.library);
    final topCard = notifier.drawStack(0).first;
    final countBefore = container.read(gameProvider).centerStacks['draw1']!;

    final error = notifier.drawLibraryCard(0);

    expect(error, isNull);
    final state = container.read(gameProvider);
    expect(state.libraryDrawPending, isFalse);
    expect(state.you.hand.any((c) => c.id == topCard.id), isTrue);
    expect(state.centerStacks['draw1'], countBefore - 1);
  });

  test('drawLibraryCard är no-op utan en väntande dragning', () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    final handBefore = List<GameCard>.of(container.read(gameProvider).you.hand);

    final error = notifier.drawLibraryCard(0);

    expect(error, isNull);
    expect(container.read(gameProvider).you.hand, handBefore);
  });

  test('att spela ett handlingskort är blockerat medan Biblioteks-dragningen väntar',
      () {
    final container = buildContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    giveLibrary(container);
    notifier.dropExpansion(0, BuildingRow.above, 0, EraOfProgressCards.library);

    final error = notifier.discardActionCard(BasicSetCards.merchantCaravan);

    expect(error, isNotNull);
    expect(error, contains('Biblioteket'));
  });
}
