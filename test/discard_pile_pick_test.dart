import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Guido ambassadören/Gustav bibliotekarien (Utvecklingens tid,
/// regelhäftet: "Du får välja 1 kort från kasserade kort") – se
/// GameNotifier._useDiscardPilePick/pickFromDiscardPile. Slänghögen är
/// redan en delad, fullt synkad resurs (till skillnad från Bågskytt/
/// Pyroman/Förrädare krävs alltså ingen förfrågan online), så bara
/// notifier-nivån testas här (samma kod oavsett läge).
void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfProgress});
    notifier.state = container.read(gameProvider).copyWith(diceRolled: true);
    return container;
  }

  void giveTownHall(ProviderContainer container) {
    container.read(gameProvider).you.principality
        .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: EraOfProgressCards.townHall));
  }

  void giveGuido(ProviderContainer container) {
    final notifier = container.read(gameProvider.notifier);
    notifier.state = container.read(gameProvider).copyWith(
        you: container.read(gameProvider).you.copyWith(hand: [
      ...container.read(gameProvider).you.hand,
      EraOfProgressCards.guidoTheAmbassador
    ]));
  }

  void giveDiscardPile(ProviderContainer container, List<GameCard> cards) {
    final notifier = container.read(gameProvider.notifier);
    notifier.state = container.read(gameProvider).copyWith(discardPile: cards);
  }

  group('Guido ambassadören', () {
    test('kräver Rådhus eller färre segerpoäng: avvisas utan det', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveGuido(container);
      giveDiscardPile(container, [BasicSetCards.storehouse]);

      final error = notifier.useGuidoTheAmbassador();

      expect(error, 'Kräver Rådhus, eller färre segerpoäng än motståndaren.');
      expect(container.read(gameProvider).discardPilePicking, isFalse);
      expect(
          container.read(gameProvider).you.hand.any(
              (c) => c.baseId == EraOfProgressCards.guidoTheAmbassador.id),
          isTrue,
          reason: 'kortet ska ligga kvar när kravet inte är uppfyllt');
    });

    test('med Rådhus: tom slänghög avslutar kortet direkt utan att öppna väljaren',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveTownHall(container);
      giveGuido(container);
      expect(container.read(gameProvider).discardPile, isEmpty);

      final error = notifier.useGuidoTheAmbassador();

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.discardPilePicking, isFalse);
      expect(
          state.you.hand
              .any((c) => c.baseId == EraOfProgressCards.guidoTheAmbassador.id),
          isFalse);
      expect(state.discardPile, hasLength(1));
      expect(state.discardPile.last.baseId,
          EraOfProgressCards.guidoTheAmbassador.id);
    });

    test(
        'med Rådhus och en icke-tom slänghög: öppnar väljaren, kortet ligger kvar på handen',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveTownHall(container);
      giveGuido(container);
      giveDiscardPile(container, [BasicSetCards.storehouse]);

      final error = notifier.useGuidoTheAmbassador();

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.discardPilePicking, isTrue);
      expect(state.discardPileSourceCard?.baseId,
          EraOfProgressCards.guidoTheAmbassador.id);
      expect(
          state.you.hand
              .any((c) => c.baseId == EraOfProgressCards.guidoTheAmbassador.id),
          isTrue,
          reason: 'kortet ska INTE slängas förrän efter att ett val gjorts');
    });

    test(
        'pickFromDiscardPile: valt kort läggs till handen, källkortet läggs underst i slänghögen',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveTownHall(container);
      giveGuido(container);
      giveDiscardPile(
          container, [BasicSetCards.storehouse, BasicSetCards.abbey]);
      notifier.useGuidoTheAmbassador();
      final sourceCard = container.read(gameProvider).discardPileSourceCard!;

      final error =
          notifier.pickFromDiscardPile(BasicSetCards.storehouse);

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.discardPilePicking, isFalse);
      expect(state.discardPileSourceCard, isNull);
      expect(
          state.you.hand.any((c) => c.id == BasicSetCards.storehouse.id),
          isTrue,
          reason: 'det valda kortet ska läggas till handen');
      expect(state.you.hand.any((c) => c.id == sourceCard.id), isFalse,
          reason: 'Guido själv ska tas bort från handen');
      expect(state.discardPile.any((c) => c.id == BasicSetCards.storehouse.id),
          isFalse,
          reason: 'det valda kortet ska tas bort ur slänghögen');
      expect(state.discardPile.last.id, sourceCard.id,
          reason: 'Guido ska läggas underst (sist) i slänghögen efteråt');
      expect(state.discardPile.any((c) => c.id == BasicSetCards.abbey.id),
          isTrue,
          reason: 'övriga kort i slänghögen ska vara orörda');
    });

    test('pickFromDiscardPile är no-op utan en väntande väljare', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveDiscardPile(container, [BasicSetCards.storehouse]);

      final error = notifier.pickFromDiscardPile(BasicSetCards.storehouse);

      expect(error, isNull);
      expect(container.read(gameProvider).you.hand
          .any((c) => c.id == BasicSetCards.storehouse.id), isFalse);
    });

    test('cancelDiscardPilePick lämnar handen och slänghögen orörda', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveTownHall(container);
      giveGuido(container);
      giveDiscardPile(container, [BasicSetCards.storehouse]);
      notifier.useGuidoTheAmbassador();
      final handBefore = List<GameCard>.of(container.read(gameProvider).you.hand);
      final discardBefore =
          List<GameCard>.of(container.read(gameProvider).discardPile);

      notifier.cancelDiscardPilePick();

      final state = container.read(gameProvider);
      expect(state.discardPilePicking, isFalse);
      expect(state.discardPileSourceCard, isNull);
      expect(state.you.hand, handBefore);
      expect(state.discardPile, discardBefore);
    });

    test('att bygga vidare är blockerat medan slänghögsväljaren är aktiv', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveTownHall(container);
      giveGuido(container);
      giveDiscardPile(container, [BasicSetCards.storehouse]);
      notifier.useGuidoTheAmbassador();

      final error = notifier.discardActionCard(BasicSetCards.merchantCaravan);
      expect(error, isNotNull);
      expect(error, contains('händelsekortet'));
    });
  });

  group('Gustav bibliotekarien', () {
    test('kräver Bibliotek eller färre segerpoäng: avvisas utan det', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final state = container.read(gameProvider);
      notifier.state = state.copyWith(
          you: state.you.copyWith(
              hand: [...state.you.hand, EraOfProgressCards.gustavTheLibrarian]));
      giveDiscardPile(container, [BasicSetCards.storehouse]);

      final error = notifier.useGustavTheLibrarian();

      expect(
          error, 'Kräver Bibliotek, eller färre segerpoäng än motståndaren.');
    });

    test('med Bibliotek: öppnar väljaren och kan välja ett kort', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      container.read(gameProvider).you.principality
          .upgradeToCity(0, const PlacedCard(card: BasicSetCards.city));
      container.read(gameProvider).you.principality.placeExpansion(0,
          BuildingRow.above, 0, const PlacedCard(card: EraOfProgressCards.library));
      final state = container.read(gameProvider);
      notifier.state = state.copyWith(
          you: state.you.copyWith(
              hand: [...state.you.hand, EraOfProgressCards.gustavTheLibrarian]));
      giveDiscardPile(container, [BasicSetCards.storehouse]);

      expect(notifier.useGustavTheLibrarian(), isNull);
      expect(container.read(gameProvider).discardPilePicking, isTrue);

      expect(notifier.pickFromDiscardPile(BasicSetCards.storehouse), isNull);
      final finalState = container.read(gameProvider);
      expect(
          finalState.you.hand.any((c) => c.id == BasicSetCards.storehouse.id),
          isTrue);
      expect(finalState.discardPile.last.baseId,
          EraOfProgressCards.gustavTheLibrarian.id);
    });
  });
}
