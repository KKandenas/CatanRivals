import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressionstest för en bugg där Brigitta/Spejare/Omlokaliserings
/// särbehandling aldrig triggades i riktigt spel: [BasicSetDrawDeck]
/// (och [EventDeck] för icke-Yule-kort) ger varje fysisk kortkopia ett
/// eget, suffixerat id ("$id-draw-$i", t.ex. "action-brigitta-draw-0")
/// – men koden jämförde [GameCard.id] direkt mot de statiska
/// `BasicSetCards.*`-konstanternas id ("action-brigitta"), vilket bara
/// råkade fungera i MockGame-handen (som använder de statiska
/// instanserna direkt) och i tidigare tester (som lade till kortet
/// via `hand.add(BasicSetCards.x)` utan suffix). Alla riktiga dragna
/// kort missades helt tyst.
///
/// Testerna här bygger handkorten precis som [BasicSetDrawDeck] gör
/// (`card.copyWith(id: '${card.id}-draw-0')`) för att fånga den här
/// klassen av bugg – se [GameCard.baseId], som nu används i stället
/// för [GameCard.id] överallt handlingskortens typ avgörs.
void main() {
  GameCard drawnCopyOf(GameCard card, [int i = 0]) =>
      card.copyWith(id: '${card.id}-draw-$i');

  test('GameCard.baseId strippar draghögens per-kopia-suffix', () {
    final drawn = drawnCopyOf(BasicSetCards.brigittaTheWiseWoman, 2);

    expect(drawn.id, 'action-brigitta-draw-2');
    expect(drawn.baseId, BasicSetCards.brigittaTheWiseWoman.id);
    expect(BasicSetCards.brigittaTheWiseWoman.baseId,
        BasicSetCards.brigittaTheWiseWoman.id);
  });

  group('Ett riktigt draget (suffixerat) Brigitta-kort', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('useBrigitta hittar kortet och väljer tärningsresultatet', () {
      final notifier = container.read(gameProvider.notifier);
      final drawn = drawnCopyOf(BasicSetCards.brigittaTheWiseWoman);
      container.read(gameProvider).you.hand.add(drawn);

      final error = notifier.useBrigitta(4);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.productionRoll, 4);
      expect(state.diceRolled, isTrue);
      expect(state.you.hand.contains(drawn), isFalse);
    });
  });

  group('Ett riktigt draget (suffixerat) Spejare-kort', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).rollProductionDie();
      // Mock-handen har redan en icke-suffixerad Spejare – ta bort den
      // så bara den suffixerade kopian nedan kan trigga frågan.
      container
          .read(gameProvider)
          .you
          .hand
          .removeWhere((c) => c.id == BasicSetCards.scout.id);
    });

    test('by-bygge bortom yttergränsen väcker ändå frågan', () {
      final notifier = container.read(gameProvider.notifier);
      container.read(gameProvider).you.hand.add(drawnCopyOf(BasicSetCards.scout));

      notifier.dropRoad(-1, BasicSetCards.road);
      notifier.dropSettlement(-2, BasicSetCards.settlement);

      final state = container.read(gameProvider);
      expect(state.awaitingScoutDecision, isTrue);
      expect(state.pendingRegions, isEmpty);
    });

    test('utan Spejare på handen dras regionerna direkt som vanligt', () {
      final notifier = container.read(gameProvider.notifier);
      // Ingen Spejare alls (varken suffixerad eller inte) den här gången.

      notifier.dropRoad(-1, BasicSetCards.road);
      notifier.dropSettlement(-2, BasicSetCards.settlement);

      final state = container.read(gameProvider);
      expect(state.awaitingScoutDecision, isFalse);
      expect(state.pendingRegions, hasLength(2));
    });

    test('pickScoutRegion tar bort den suffixerade kopian från handen', () {
      final notifier = container.read(gameProvider.notifier);
      final drawn = drawnCopyOf(BasicSetCards.scout);
      container.read(gameProvider).you.hand.add(drawn);
      notifier.dropRoad(-1, BasicSetCards.road);
      notifier.dropSettlement(-2, BasicSetCards.settlement);

      notifier.useScout();
      final choices = container.read(gameProvider).scoutChoices!;
      notifier.pickScoutRegion(choices[0]);
      notifier.pickScoutRegion(container.read(gameProvider).scoutChoices![0]);

      expect(container.read(gameProvider).you.hand.contains(drawn), isFalse);
    });
  });

  group('Ett riktigt draget (suffixerat) Omlokaliserings-kort', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).rollProductionDie();
    });

    test('startRelocation känner igen kortet och startar väljarläget', () {
      final notifier = container.read(gameProvider.notifier);
      container.read(gameProvider).you.hand.add(drawnCopyOf(BasicSetCards.relocation));

      final error = notifier.startRelocation();

      expect(error, isNull);
      expect(container.read(gameProvider).relocationActive, isTrue);
    });

    test('ett fullbordat byte tar bort den suffixerade kopian, inte bara någon slumpmässig',
        () {
      final notifier = container.read(gameProvider.notifier);
      final drawn = drawnCopyOf(BasicSetCards.relocation);
      final state = container.read(gameProvider);
      state.you.hand.add(drawn);
      state.you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: BasicSetCards.storehouse));
      state.you.principality.placeExpansion(
          0, BuildingRow.below, 0, const PlacedCard(card: BasicSetCards.tollBridge));

      notifier.startRelocation();
      notifier.selectRelocationTarget(
          RelocationTargetKind.expansion, 0, BuildingRow.above, 0);
      notifier.selectRelocationTarget(
          RelocationTargetKind.expansion, 0, BuildingRow.below, 0);

      final after = container.read(gameProvider);
      expect(after.you.hand.contains(drawn), isFalse);
      expect(
          after.you.principality.settlementAt(0)!.aboveSites[0]!.card.id,
          BasicSetCards.tollBridge.id);
    });
  });
}
