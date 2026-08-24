import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar vinstvillkoret (regelhäftet: 7 eller fler segerpoäng vid
/// slutet av sin egen runda, se [GameState.winnerId]/
/// [GameNotifier._advanceToNextPlayer]) – kollas bara i det ögonblick
/// en runda faktiskt tar slut (skipTrade/exchangeDraw/peekTakeCard),
/// och lämnar då INTE över turen (spelet fryser i vinnarens
/// slutställning, se GameOverOverlay).
void main() {
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  /// Ger [player] [extraPoints] segerpoäng UTÖVER de 2 startbyarna
  /// redan ger (regelhäftet: en by är värd 1 VP – se
  /// [BasicSetCards.settlement] – och startuppställningen har 2, se
  /// starter_cards.dart) genom en byggnad på en annars tom byggplats
  /// (kolumn 0, ovanför) – samma teknik som feud_test.dart använder för
  /// att kontrollera poäng deterministiskt. `progressPoints: 0` skriver
  /// medvetet över Klostrets (abbey) egna framstegspoäng (regelhäftet:
  /// den ger normalt både VP OCH ett framstegskort) – annars skulle
  /// handLimit (som beror på [RealmBoard.totalProgressPoints]) ändras
  /// och rubba testets antagande om att starthanden redan har rätt
  /// antal kort.
  void giveVictoryPoints(Player player, int extraPoints) {
    player.principality.placeExpansion(
      0,
      BuildingRow.above,
      0,
      PlacedCard(
          card: BasicSetCards.abbey
              .copyWith(victoryPoints: extraPoints, progressPoints: 0)),
    );
  }

  test(
      '7 segerpoäng totalt vid slutet av din runda: winnerId sätts, turen lämnas INTE över',
      () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();

    // 2 (startbyarna) + 5 = 7.
    giveVictoryPoints(container.read(gameProvider).you, 5);
    expect(container.read(gameProvider).winnerId, isNull);

    notifier.rollProductionDie();
    expect(notifier.endActionPhase(), isNull);
    expect(container.read(gameProvider).tradePhase, TradePhase.choosing);
    expect(notifier.skipTrade(), isNull);

    final state = container.read(gameProvider);
    expect(state.winnerId, 'you');
    expect(state.activePlayerId, 'you',
        reason: 'turen ska INTE lämnas över när matchen redan är vunnen');
  });

  test('5 segerpoäng totalt: ingen vinnare, turen lämnas över som vanligt',
      () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();

    // 2 (startbyarna) + 3 = 5, under gränsen.
    giveVictoryPoints(container.read(gameProvider).you, 3);
    notifier.rollProductionDie();
    notifier.endActionPhase();
    notifier.skipTrade();

    final state = container.read(gameProvider);
    expect(state.winnerId, isNull);
    expect(state.activePlayerId, 'opponent');
  });

  test(
      'med Gulderan aktivt krävs 12 poäng, inte 7 (GameState.victoryPointTarget)',
      () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfGold});
    expect(container.read(gameProvider).victoryPointTarget, 12);

    // 2 (startbyarna) + 5 = 7 – hade räckt i grundspelet, men inte här.
    giveVictoryPoints(container.read(gameProvider).you, 5);
    notifier.rollProductionDie();
    expect(notifier.endActionPhase(), isNull);
    expect(notifier.skipTrade(), isNull);
    expect(container.read(gameProvider).winnerId, isNull,
        reason: '7 poäng ska inte räcka när Gulderan är aktivt (mål: 12)');
  });

  test('med Gulderan aktivt: 12 poäng räcker för vinst', () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally(expansions: {ExpansionSet.eraOfGold});

    // 2 (startbyarna) + 10 = 12.
    giveVictoryPoints(container.read(gameProvider).you, 10);
    notifier.rollProductionDie();
    expect(notifier.endActionPhase(), isNull);
    expect(notifier.skipTrade(), isNull);

    final state = container.read(gameProvider);
    expect(state.winnerId, 'you');
    expect(state.activePlayerId, 'you');
  });

  test('utan aktiv expansion är segervillkoret fortfarande 7 (oförändrat)',
      () {
    final container = ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();
    expect(container.read(gameProvider).victoryPointTarget, 7);
  });

  test('online: vinsten synkas till motståndarens klient', () async {
    final fake = FakeGameSyncService();
    final host =
        ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    final guest =
        ProviderContainer(overrides: [gameSyncServiceProvider.overrideWithValue(fake)]);
    addTearDown(host.dispose);
    addTearDown(guest.dispose);

    final roomCode = await host.read(gameProvider.notifier).hostRoom('Astrid');
    await pump();
    await guest.read(gameProvider.notifier).joinRoom(roomCode, 'Björn');
    await pump();

    expect(host.read(gameProvider.notifier).chooseStartingStack(0), isNull);
    await pump();
    expect(guest.read(gameProvider.notifier).chooseStartingStack(1), isNull);
    await pump();

    final hostNotifier = host.read(gameProvider.notifier);
    // 2 (startbyarna) + 5 = 7.
    giveVictoryPoints(host.read(gameProvider).you, 5);

    expect(hostNotifier.rollProductionDie(), isNull);
    expect(hostNotifier.endActionPhase(), isNull);
    expect(hostNotifier.skipTrade(), isNull);
    await pump();

    final hostState = host.read(gameProvider);
    final guestState = guest.read(gameProvider);
    expect(hostState.winnerId, 'host');
    expect(guestState.winnerId, 'host',
        reason: 'gästens klient ska se vinnaren via turnState-synken');
    expect(guestState.activePlayerId, 'host',
        reason: 'turen ska inte ha lämnats över till gästen');
  });
}
