import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Förrädare (Oroligheternas tid): "kräver Värdshus. Man får
/// titta på motståndarens kort de har på handen och välja ett som
/// läggs till den egna handen" – se
/// [GameNotifier.useTraitor]/[GameNotifier.pickTraitorCard]. Till
/// skillnad från Brödrafejd (se multiplayer_fraternal_feuds_test.dart)
/// hamnar det valda kortet i den AKTIVA spelarens hand, inte underst i
/// en draghög – se [TraitorRequest]-doc för varför det ändå krävs en
/// egen synkad förfrågan online.
void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfTurmoil});
    notifier.state = container.read(gameProvider).copyWith(diceRolled: true);
    return container;
  }

  void giveHedgeTavern(ProviderContainer container) {
    container.read(gameProvider).you.principality.placeExpansion(
        0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.hedgeTavern));
  }

  void giveTraitorCard(ProviderContainer container) {
    final notifier = container.read(gameProvider.notifier);
    notifier.state = container
        .read(gameProvider)
        .copyWith(you: container.read(gameProvider).you.copyWith(
            hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.traitor]));
  }

  group('lokalt läge', () {
    test('kräver Värdshus: avvisas utan det, går bra med det', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveTraitorCard(container);

      final withoutTavern = notifier.useTraitor();
      expect(withoutTavern, isNotNull);
      expect(
          container.read(gameProvider).you.hand.any((c) => c.baseId == EraOfTurmoilCards.traitor.id),
          isTrue,
          reason: 'kortet ska ligga kvar när kravet inte är uppfyllt');

      giveHedgeTavern(container);
      expect(notifier.useTraitor(), isNull);
      expect(
          container.read(gameProvider).you.hand.any((c) => c.baseId == EraOfTurmoilCards.traitor.id),
          isFalse);
      final state = container.read(gameProvider);
      expect(state.discardPile.last.baseId, EraOfTurmoilCards.traitor.id);
    });

    test('motståndaren har tom hand: inget att välja, ingen väljarvy öppnas', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      giveTraitorCard(container);
      final opponent = container.read(gameProvider).opponent;
      notifier.state = container
          .read(gameProvider)
          .copyWith(opponent: opponent.copyWith(hand: const []));

      expect(notifier.useTraitor(), isNull);
      expect(container.read(gameProvider).traitorPicking, isFalse);
    });

    test(
        'väljer ett kort ur motståndarens hand: läggs till din hand, tas bort från motståndarens',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      giveTraitorCard(container);
      final opponentHandBefore =
          List<GameCard>.of(container.read(gameProvider).opponent.hand);
      expect(opponentHandBefore, isNotEmpty);

      expect(notifier.useTraitor(), isNull);
      expect(container.read(gameProvider).traitorPicking, isTrue);

      final picked = opponentHandBefore.first;
      expect(notifier.pickTraitorCard(picked), isNull);

      final state = container.read(gameProvider);
      expect(state.traitorPicking, isFalse);
      expect(state.you.hand.any((c) => c.id == picked.id), isTrue);
      expect(state.opponent.hand.any((c) => c.id == picked.id), isFalse);
      expect(state.opponent.hand, hasLength(opponentHandBefore.length - 1));
    });

    test('cancelTraitorPick stänger väljaren utan att ändra någon hand', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      giveTraitorCard(container);
      notifier.useTraitor();
      final opponentHandBefore =
          List<GameCard>.of(container.read(gameProvider).opponent.hand);

      notifier.cancelTraitorPick();

      final state = container.read(gameProvider);
      expect(state.traitorPicking, isFalse);
      expect(state.opponent.hand, opponentHandBefore);
    });

    test('att bygga vidare är blockerat medan handväljaren är aktiv', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      giveTraitorCard(container);
      notifier.useTraitor();

      final error = notifier.discardActionCard(BasicSetCards.merchantCaravan);
      expect(error, isNotNull);
      expect(error, contains('händelsekortet'));
    });
  });

  group('online (två klienter)', () {
    Future<void> pump() => Future<void>.delayed(Duration.zero);

    Future<(ProviderContainer, ProviderContainer)> connectedRoom() async {
      final fake = FakeGameSyncService();
      final host = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
      final guest = ProviderContainer(
          overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);

      final roomCode = await host.read(gameProvider.notifier).hostRoom('Astrid');
      await pump();
      await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
      await pump();
      expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
      await pump();
      expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
      await pump();

      return (host, guest);
    }

    test(
        'host spelar Förrädare och väljer ett kort ur gästens hand: hamnar direkt i hosts hand, gästens klient tar bort det ur sin egen',
        () async {
      final (host, guest) = await connectedRoom();
      addTearDown(host.dispose);
      addTearDown(guest.dispose);

      final hostNotifier = host.read(gameProvider.notifier);
      host.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.hedgeTavern));
      hostNotifier.state = host.read(gameProvider).copyWith(
          diceRolled: true,
          you: host.read(gameProvider).you.copyWith(
              hand: [...host.read(gameProvider).you.hand, EraOfTurmoilCards.traitor]));
      hostNotifier.adjustRegionResource(-1, BuildingRow.above, 0);
      await pump();

      final guestHandBefore =
          List<GameCard>.of(host.read(gameProvider).opponent.hand);
      expect(guestHandBefore, hasLength(3));

      expect(hostNotifier.useTraitor(), isNull);
      expect(host.read(gameProvider).traitorPicking, isTrue);

      final picked = guestHandBefore.first;
      expect(hostNotifier.pickTraitorCard(picked), isNull);
      final hostState = host.read(gameProvider);
      expect(hostState.traitorPicking, isFalse);
      expect(hostState.you.hand.any((c) => c.id == picked.id), isTrue,
          reason: 'host har redan skrivrätt till sin egen hand direkt');

      // Väntar in Firebase-tur-och-retur: förfrågan -> gästens klient
      // tillämpar den -> synkar tillbaka sin nya hand -> host ser den.
      await pump();
      await pump();

      final guestState = guest.read(gameProvider);
      expect(guestState.you.hand.any((c) => c.id == picked.id), isFalse,
          reason: 'gästens klient ska ha tagit bort det valda kortet ur sin '
              'EGEN hand, som svar på förfrågan');
      expect(guestState.you.hand, hasLength(guestHandBefore.length - 1));

      final hostAfterSync = host.read(gameProvider);
      expect(hostAfterSync.opponent.hand.any((c) => c.id == picked.id), isFalse,
          reason: 'host ska se gästens uppdaterade (kortare) hand via den '
              'vanliga players-synken');
    });
  });
}
