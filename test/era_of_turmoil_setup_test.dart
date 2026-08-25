import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Oroligheternas tid-uppställningen: 3 grundspels-draghögar à
/// 12 + 2 Oroligheternas tid-draghögar à 11 (i stället för 4 à 9 utan
/// tema), samt ansikte-upp-kortet Värdshus – exakt samma mönster som
/// Gulderan (se era_of_gold_setup_test.dart), fast med Värdshus i
/// stället för Köpmansgille (se [Player.faceUpExpansionCard]-doc).
/// VARJE spelare har sin EGEN, separata plats med som mest 1 eget kort,
/// inte en delad hög båda kan bygga från. De två temaseten kombineras
/// aldrig i samma match (se LobbyScreen).
void main() {
  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [gameSyncServiceProvider.overrideWithValue(FakeGameSyncService())],
    );
  }

  group('uppställning (playLocally)', () {
    test(
        'med Oroligheternas tid: 5 draghögar (3x12, 2x11) och varsitt eget Värdshus',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      container
          .read(gameProvider.notifier)
          .playLocally(expansions: {ExpansionSet.eraOfTurmoil});

      final state = container.read(gameProvider);
      expect(state.you.faceUpExpansionCard?.baseId,
          EraOfTurmoilCards.hedgeTavern.id);
      expect(state.opponent.faceUpExpansionCard?.baseId,
          EraOfTurmoilCards.hedgeTavern.id);
      // Två SKILDA fysiska kopior, inte samma kort visat två gånger.
      expect(state.you.faceUpExpansionCard!.id,
          isNot(state.opponent.faceUpExpansionCard!.id));
      expect(state.victoryPointTarget, 12);
      // Starthänderna dras från hög 1/2 (12 vardera), så 12-3=9.
      expect(state.centerStacks['draw1'], 9);
      expect(state.centerStacks['draw2'], 9);
      expect(state.centerStacks['draw3'], 12);
      expect(state.centerStacks['draw4'], 11);
      expect(state.centerStacks['draw5'], 11);
      expect(state.initialDrawStackSizes, [12, 12, 12, 11, 11]);
    });

    test(
        'Oroligheternas tid-kort hamnar bara i de två sista högarna (3-4), aldrig i grundspelets (0-2)',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.playLocally(expansions: {ExpansionSet.eraOfTurmoil});

      bool isTurmoilCard(GameCard c) => c.id.contains('-turmoil-draw-');
      for (var i = 0; i < 3; i++) {
        expect(notifier.drawStack(i).any(isTurmoilCard), isFalse,
            reason: 'hög $i är en grundspelshög');
      }
      for (var i = 3; i < 5; i++) {
        expect(notifier.drawStack(i).every(isTurmoilCard), isTrue,
            reason: 'hög $i är en Oroligheternas tid-hög');
      }
    });

    test(
        'händelsekortsstapeln innehåller Oroligheternas tids 4 extra händelsekort',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);

      notifier.playLocally();
      final baseLength = notifier.eventDeck.length;

      notifier.playLocally(expansions: {ExpansionSet.eraOfTurmoil});
      expect(notifier.eventDeck.length, baseLength + 4);
      final riotsCount = notifier.eventDeck
          .where((c) => c.baseId == EraOfTurmoilCards.riots.id)
          .length;
      expect(riotsCount, 2);
    });
  });
}
