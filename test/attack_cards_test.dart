import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/game_sync_providers.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_game_sync_service.dart';

/// Testar Bågskytt/Pyroman ("kräver Värdshus... motståndaren måste
/// lägga en av sina egna enheter/byggnader underst i motsvarande
/// draghög") och Plundringsfärd ("kräver styrkeövertag... 2 resurser
/// om motståndaren leder, annars 1").
void main() {
  const heroUnit = EraOfTurmoilCards.carlForkbeard; // strengthPoints: 5

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

  group('Bågskytt', () {
    test('kräver Värdshus: avvisas utan det, går bra med det', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.state = container
          .read(gameProvider)
          .copyWith(you: container.read(gameProvider).you.copyWith(
              hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.archer]));
      container.read(gameProvider).opponent.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: heroUnit));

      final withoutTavern = notifier.useArcher();
      expect(withoutTavern, isNotNull);
      expect(container.read(gameProvider).you.hand.any((c) => c.baseId == EraOfTurmoilCards.archer.id), isTrue,
          reason: 'kortet ska ligga kvar när kravet inte är uppfyllt');

      giveHedgeTavern(container);
      expect(notifier.useArcher(), isNull);
      expect(container.read(gameProvider).you.hand.any((c) => c.baseId == EraOfTurmoilCards.archer.id), isFalse);
    });

    test('motståndaren har ingen enhet med styrkepoäng: inget händer (ingen väntande flagga)', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      notifier.state = container
          .read(gameProvider)
          .copyWith(you: container.read(gameProvider).you.copyWith(
              hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.archer]));
      // Motståndaren har inga utplacerade enheter alls.

      expect(notifier.useArcher(), isNull);
      expect(container.read(gameProvider).pendingAttackCard, isNull);
    });

    test(
        'motståndaren väljer bort en enhet och lägger den underst i rätt draghög',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      notifier.state = container
          .read(gameProvider)
          .copyWith(you: container.read(gameProvider).you.copyWith(
              hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.archer]));
      container.read(gameProvider).opponent.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: heroUnit));

      expect(notifier.useArcher(), isNull);
      expect(container.read(gameProvider).pendingAttackCard, AttackCardKind.archer);

      // I lokalt läge är "motståndaren" bara en mock (ingen egen
      // interaktiv vy, se playLocally-doc) – Bågskytts eget effekt-flöde
      // (selectAttackCardUnit) verkar alltid på state.you.principality,
      // så testet simulerar den DRABBADE sidans egen klient genom att
      // agera på you (matchar hur multiplayer_pirate_ship_test.dart
      // testar samma sak: den drabbade väljer på sin EGEN state.you).
      giveTargetUnitOnYou(container);
      expect(notifier.selectAttackCardUnit(2, BuildingRow.above, 0), isNull);
      expect(container.read(gameProvider).attackCardPickedUnit, isNotNull);

      final wrongError = notifier.resolveAttackCardUnitRemoval(3); // Oroligheternas tid-hög
      expect(wrongError, isNotNull);

      final okError = notifier.resolveAttackCardUnitRemoval(0);
      expect(okError, isNull);
      final state = container.read(gameProvider);
      expect(state.you.principality.settlementAt(2)!.aboveSites[0], isNull);
      expect(state.pendingAttackCard, isNull);
      expect(state.attackCardPickedUnit, isNull);
      expect(notifier.drawStack(0).last.id, heroUnit.id);
    });

    test('går inte att välja en byggnad utan styrkepoäng', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      notifier.state = container
          .read(gameProvider)
          .copyWith(you: container.read(gameProvider).you.copyWith(
              hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.archer]));
      container.read(gameProvider).opponent.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: heroUnit));
      notifier.useArcher();

      // hedgeTavern (0 styrkepoäng) placerad på column 0 ska INTE
      // kvalificera för Bågskytt.
      final error = notifier.selectAttackCardUnit(0, BuildingRow.above, 0);
      expect(error, isNotNull);
    });
  });

  group('Pyroman', () {
    test('gäller byggnader (inte enheter utan strength), motståndaren har inget: inget händer', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      notifier.state = container
          .read(gameProvider)
          .copyWith(you: container.read(gameProvider).you.copyWith(
              hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.arsonist]));
      // Motståndaren har bara en enhet (hjälte), ingen byggnad.
      container.read(gameProvider).opponent.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: heroUnit));

      expect(notifier.useArsonist(), isNull);
      expect(container.read(gameProvider).pendingAttackCard, isNull,
          reason: 'hjälten räknas inte som byggnad för Pyroman');
    });

    test('tar bort en byggnad och lägger den underst i rätt draghög', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      notifier.state = container
          .read(gameProvider)
          .copyWith(you: container.read(gameProvider).you.copyWith(
              hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.arsonist]));
      container.read(gameProvider).opponent.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.drillGround));

      expect(notifier.useArsonist(), isNull);
      expect(container.read(gameProvider).pendingAttackCard, AttackCardKind.arsonist);

      giveTargetBuildingOnYou(container);
      expect(notifier.selectAttackCardUnit(2, BuildingRow.above, 0), isNull);
      expect(notifier.resolveAttackCardUnitRemoval(0), isNull);
      final state = container.read(gameProvider);
      expect(state.you.principality.settlementAt(2)!.aboveSites[0], isNull);
      expect(state.pendingAttackCard, isNull);
    });
  });

  group('_checkCanBuild-spärr', () {
    test('går inte att bygga medan enhetsvalet väntar på draghög', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      giveHedgeTavern(container);
      notifier.state = container
          .read(gameProvider)
          .copyWith(you: container.read(gameProvider).you.copyWith(
              hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.archer]));
      container.read(gameProvider).opponent.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: heroUnit));
      notifier.useArcher();
      giveTargetUnitOnYou(container);
      notifier.selectAttackCardUnit(2, BuildingRow.above, 0);

      final error = notifier.discardActionCard(BasicSetCards.merchantCaravan);
      expect(error, isNotNull);
      expect(error, contains('händelsekortet'));
    });
  });

  group('Plundringsfärd', () {
    test('kräver styrkeövertag: avvisas utan det, går bra med det', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.state = container
          .read(gameProvider)
          .copyWith(you: container.read(gameProvider).you.copyWith(
              hand: [...container.read(gameProvider).you.hand, EraOfTurmoilCards.voyageOfPlunder]));
      // Ingen har styrkepoäng: oavgjort, inte styrkeövertag.

      final withoutAdvantage = notifier.useVoyageOfPlunder();
      expect(withoutAdvantage, isNotNull);

      container.read(gameProvider).you.principality.placeExpansion(
          0, BuildingRow.above, 0, const PlacedCard(card: heroUnit));
      expect(notifier.useVoyageOfPlunder(), isNull);
      expect(
          container
              .read(gameProvider)
              .you
              .hand
              .any((c) => c.baseId == EraOfTurmoilCards.voyageOfPlunder.id),
          isFalse);
    });
  });
}

/// Placerar [heroUnit]-liknande enhet (styrkepoäng) på state.you – se
/// kommentaren i "motståndaren väljer bort en enhet"-testet ovan för
/// varför den DRABBADE sidans eget val alltid sker på state.you.
void giveTargetUnitOnYou(ProviderContainer container) {
  container.read(gameProvider).you.principality.placeExpansion(
      2, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.carlForkbeard));
}

void giveTargetBuildingOnYou(ProviderContainer container) {
  container.read(gameProvider).you.principality.placeExpansion(
      2, BuildingRow.above, 0, const PlacedCard(card: EraOfTurmoilCards.drillGround));
}
