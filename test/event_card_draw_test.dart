import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar att dra händelsekort när händelsetärningen visar "?" (se
/// EventDieFace.eventCard och GameNotifier.drawEventCard). Julkortet
/// ligger alltid på index 5 i den 9-kortsstapel
/// EventDeck.shuffledWithYuleFourthFromBottom bygger (5 slumpade kort
/// överst, sedan Jul, sedan 3 slumpade underst) – oavsett hur
/// blandningen faller ut. Det gör att man deterministiskt kan tvinga
/// fram Jul-fallet: dra 5 kort (aldrig Jul), det sjätte är garanterat
/// Jul.
void main() {
  ProviderContainer readyContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();
    return container;
  }

  /// Tvingar fram händelsetärningens "?"-utfall och att tärningen är
  /// slagen, utan att bry sig om vad produktionstärningen visar –
  /// notifierns egen slumpade rollProductionDie() styr inte vilken
  /// EventDieFace som sätts.
  void forceEventCardFace(ProviderContainer container) {
    final notifier = container.read(gameProvider.notifier);
    notifier.state = container
        .read(gameProvider)
        .copyWith(diceRolled: true, eventDieFace: EventDieFace.eventCard);
  }

  test('drawEventCard är no-op om tärningen inte visar "?"', () {
    final container = readyContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.state =
        container.read(gameProvider).copyWith(diceRolled: true, eventDieFace: EventDieFace.trade);

    expect(notifier.drawEventCard(), isNull);
    expect(container.read(gameProvider).drawnEventCard, isNull);
    expect(container.read(gameProvider).centerStacks['event'], 9);
  });

  test('drawEventCard drar översta kortet, minskar stapeln, och går bara att göra en gång', () {
    final container = readyContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    forceEventCardFace(container);

    final error = notifier.drawEventCard();

    expect(error, isNull);
    var state = container.read(gameProvider);
    expect(state.drawnEventCard, isNotNull);
    expect(state.drawnEventCard!.category, CardCategory.event);
    expect(state.centerStacks['event'], 8);

    final firstCard = state.drawnEventCard;
    // Ett andra försök samma omgång ska inte dra ett nytt kort.
    expect(notifier.drawEventCard(), isNull);
    state = container.read(gameProvider);
    expect(state.drawnEventCard, firstCard);
    expect(state.centerStacks['event'], 8);
  });

  test('dismissEventCard stänger det uppslagna kortet', () {
    final container = readyContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    forceEventCardFace(container);
    notifier.drawEventCard();
    expect(container.read(gameProvider).drawnEventCard, isNotNull);

    expect(notifier.dismissEventCard(), isNull);

    expect(container.read(gameProvider).drawnEventCard, isNull);
  });

  test(
      'Jul (alltid index 5 i en färsk stapel) blandar om och drar nästa kort automatiskt, utan att någonsin visas',
      () {
    final container = readyContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    for (var i = 0; i < 5; i++) {
      forceEventCardFace(container);
      final error = notifier.drawEventCard();
      expect(error, isNull);
      final drawn = container.read(gameProvider).drawnEventCard!;
      expect(drawn.id, isNot(BasicSetCards.yule.id));
      notifier.dismissEventCard();
    }

    // Det sjätte draget (index 5) är garanterat Jul – ska blandas om
    // och nästa kort dras direkt, osynligt för spelaren.
    forceEventCardFace(container);
    final error = notifier.drawEventCard();

    expect(error, isNull);
    final state = container.read(gameProvider);
    expect(state.drawnEventCard, isNotNull);
    expect(state.drawnEventCard!.id, isNot(BasicSetCards.yule.id),
        reason: 'Jul ska aldrig visas för spelaren, bara kortet efter');
    // Stapeln byggdes om till 9 färska kort och sedan drogs ett,
    // så 8 kvarstår – inte 9-6=3 som en enkel nedräkning skulle ge.
    expect(state.centerStacks['event'], 8);
  });

  /// Testar rapporterad bugg: ombladningen vid Jul byggde tidigare en
  /// helt ny stapel med bara grundspelets 9 kort (se EventDeck.
  /// shuffledWithYuleFourthFromBottom), oavsett tema – temasetets egna
  /// extra händelsekort försvann permanent ur spelet i stället för att
  /// följa med tillbaka in i stapeln (se GameNotifier._themeEventCards).
  void testYuleKeepsThemeEventCards(
      {required Set<ExpansionSet> expansions, required int totalCards}) {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: expansions);

    expect(container.read(gameProvider).centerStacks['event'], totalCards);

    // Jul ligger garanterat på index totalCards-4 i en färsk stapel (se
    // EventDeck-doc: alltid 4:e från botten, oavsett stapelstorlek) –
    // drar förbi den, ett kort i taget, tills nästa drag garanterat
    // träffar Jul och triggar ombladningen.
    for (var i = 0; i < totalCards - 4; i++) {
      notifier.state = container
          .read(gameProvider)
          .copyWith(diceRolled: true, eventDieFace: EventDieFace.eventCard);
      expect(notifier.drawEventCard(), isNull);
      notifier.dismissEventCard();
    }

    notifier.state = container
        .read(gameProvider)
        .copyWith(diceRolled: true, eventDieFace: EventDieFace.eventCard);
    expect(notifier.drawEventCard(), isNull);

    final state = container.read(gameProvider);
    expect(state.drawnEventCard!.id, isNot(BasicSetCards.yule.id));
    // Skulle temasetets egna kort ha tappats bort vid ombladningen (den
    // rapporterade buggen) hade den nya stapeln bara haft grundspelets
    // kort kvar i stället för alla [totalCards] - 1 (det just dragna).
    expect(state.centerStacks['event'], totalCards - 1);
  }

  test('Jul med Gulderan aktivt: Gulderans egna händelsekort följer med i ombladningen',
      () => testYuleKeepsThemeEventCards(
          expansions: {ExpansionSet.eraOfGold}, totalCards: 12));

  test(
      'Jul med Oroligheternas tid aktivt: dess egna händelsekort följer med i ombladningen',
      () => testYuleKeepsThemeEventCards(
          expansions: {ExpansionSet.eraOfTurmoil}, totalCards: 13));

  test('online: händelsekortet synkas till motståndarens klient', () async {
    Future<void> pump() => Future<void>.delayed(Duration.zero);
    final fake = FakeGameSyncService();
    final host = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest = ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final roomCode = await host.read(gameProvider.notifier).hostRoom('Astrid');
    await pump();
    await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();
    host.read(gameProvider.notifier).chooseStartingStack(0);
    await pump();
    guest.read(gameProvider.notifier).chooseStartingStack(1);
    await pump();

    final hostNotifier = host.read(gameProvider.notifier);
    hostNotifier.state =
        host.read(gameProvider).copyWith(diceRolled: true, eventDieFace: EventDieFace.eventCard);

    expect(hostNotifier.drawEventCard(), isNull);
    await pump();

    final hostCard = host.read(gameProvider).drawnEventCard;
    expect(hostCard, isNotNull);
    expect(guest.read(gameProvider).drawnEventCard?.id, hostCard!.id);

    expect(hostNotifier.dismissEventCard(), isNull);
    await pump();

    expect(guest.read(gameProvider).drawnEventCard, isNull);
  });
}
