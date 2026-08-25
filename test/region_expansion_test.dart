import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar landskapsutbyggnad (brun textruta, t.ex. Guldgömma) –
/// [GameNotifier.dropRegionExpansion]/[GameNotifier.adjustRegionExpansionResource]
/// – se region_expansion_card_view_test.dart för widgeten och
/// models_test.dart för RealmBoard-nivåns regler.
///
/// Startuppställningen (StarterCards) har Skog (lumber) på (-1, ovanför)
/// och Guldfält (gold) på (1, ovanför) – Guldgömma kräver en region av
/// MATCHANDE resurstyp (gold), så testerna nedan placerar den på (1,
/// ovanför), inte (-1, ovanför).
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    // dropRegionExpansion kräver action-fasen (samma villkor som ett
    // vanligt bygge, se GameNotifier._checkCanBuild).
    container.read(gameProvider.notifier).rollProductionDie();
  });

  test('dropRegionExpansion flyttar kortet hand->bräde och synkar', () {
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    state.you.hand.add(EraOfGoldCards.goldCache);
    // Guldgömma kräver en utplacerad hjälte med minst 1 styrkepoäng.
    state.you.principality
        .placeExpansion(0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.harald));

    final error =
        notifier.dropRegionExpansion(1, BuildingRow.above, EraOfGoldCards.goldCache);

    expect(error, isNull);
    final after = container.read(gameProvider);
    expect(after.you.hand.contains(EraOfGoldCards.goldCache), isFalse);
    expect(after.you.principality.regionExpansionAt(1, BuildingRow.above)!.card.id,
        EraOfGoldCards.goldCache.id);
  });

  test('avvisas om ingen region finns på platsen', () {
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    state.you.hand.add(EraOfGoldCards.goldCache);

    final error =
        notifier.dropRegionExpansion(5, BuildingRow.above, EraOfGoldCards.goldCache);

    expect(error, isNull);
    expect(container.read(gameProvider).you.hand.contains(EraOfGoldCards.goldCache),
        isTrue);
  });

  test(
      'avvisas om regionen har fel resurstyp (Guldgömma får bara plats på Guldfält)',
      () {
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    state.you.hand.add(EraOfGoldCards.goldCache);
    // (-1, ovanför) är Skog (lumber), inte Guldfält (gold).
    expect(state.you.principality.regionAt(-1, BuildingRow.above)!.card.resource,
        ResourceType.lumber);

    final error =
        notifier.dropRegionExpansion(-1, BuildingRow.above, EraOfGoldCards.goldCache);

    expect(error, 'Guldgömma kan bara placeras på en region av rätt resurstyp.');
    expect(container.read(gameProvider).you.hand.contains(EraOfGoldCards.goldCache),
        isTrue);
    expect(
        container.read(gameProvider).you.principality
            .regionExpansionAt(-1, BuildingRow.above),
        isNull);
  });

  test('avvisas om platsen redan har en landskapsutbyggnad', () {
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    state.you.principality.placeRegionExpansion(
        1, BuildingRow.above, const PlacedCard(card: EraOfGoldCards.goldCache));
    final secondCopy = EraOfGoldCards.goldCache.copyWith(id: 'region-expansion-gold-cache-2');
    state.you.hand.add(secondCopy);

    final error = notifier.dropRegionExpansion(1, BuildingRow.above, secondCopy);

    expect(error, 'Den regionen har redan en landskapsutbyggnad.');
    expect(container.read(gameProvider).you.hand.contains(secondCopy), isTrue);
  });

  test('avvisas innan tärningen slagits', () {
    final freshContainer = ProviderContainer();
    addTearDown(freshContainer.dispose);
    final notifier = freshContainer.read(gameProvider.notifier);
    final state = freshContainer.read(gameProvider);
    state.you.hand.add(EraOfGoldCards.goldCache);

    final error =
        notifier.dropRegionExpansion(1, BuildingRow.above, EraOfGoldCards.goldCache);

    expect(error, isNotNull);
    expect(freshContainer.read(gameProvider).you.hand.contains(EraOfGoldCards.goldCache),
        isTrue);
  });

  test('no-op om kortet inte finns på handen', () {
    final notifier = container.read(gameProvider.notifier);

    final error =
        notifier.dropRegionExpansion(1, BuildingRow.above, EraOfGoldCards.goldCache);

    expect(error, isNull);
    expect(container.read(gameProvider).you.principality.regionExpansionAt(1, BuildingRow.above),
        isNull);
  });

  test('adjustRegionExpansionResource justerar och synkar', () {
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    state.you.principality.placeRegionExpansion(
        1, BuildingRow.above, const PlacedCard(card: EraOfGoldCards.goldCache));

    notifier.adjustRegionExpansionResource(1, BuildingRow.above, 2);

    expect(
        container.read(gameProvider).you.principality
            .regionExpansionAt(1, BuildingRow.above)!
            .storedResources,
        2);
  });
}
