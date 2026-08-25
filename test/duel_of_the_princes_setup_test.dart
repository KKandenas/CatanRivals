import 'dart:math';

import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/duel_of_the_princes_setup.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar "Duel of the Princes"-uppställningen (alla tre temaseten
/// samtidigt, se DuelOfThePrincesSetup-klassdoc): draghögarna (grund-
/// spelets 3 + en EGEN hög per temaset, med ett förutbestämt urval
/// namngivna kort borttagna) och händelsekortsstapelns 15→6-kurering.
void main() {
  group('shuffledDrawStacks', () {
    test('returnerar exakt 6 högar: grundspelets 3 (à 12) + en per temaset (12/12/14)',
        () {
      final stacks =
          DuelOfThePrincesSetup.shuffledDrawStacks(random: Random(1));

      expect(stacks.length, 6);
      expect(stacks[0].length, 12);
      expect(stacks[1].length, 12);
      expect(stacks[2].length, 12);
      expect(stacks[3].length, 12, reason: 'Gulderans egen hög');
      expect(stacks[4].length, 12, reason: 'Oroligheternas tids egen hög');
      expect(stacks[5].length, 14, reason: 'Utvecklingens tids egen hög');
    });

    test('inga händelsekort i draghögarna – de går till händelsekortsstapeln',
        () {
      final stacks =
          DuelOfThePrincesSetup.shuffledDrawStacks(random: Random(2));
      for (final stack in stacks) {
        expect(stack.any((c) => c.baseId.startsWith('event-')), isFalse);
      }
    });

    test(
        'Gulderans hög: de namngivna korten är helt borttagna, 1 Köpmansgille (av 2) kvar, orörda kort med fullt antal',
        () {
      final gold =
          DuelOfThePrincesSetup.shuffledDrawStacks(random: Random(3))[3];
      bool has(String baseId) => gold.any((c) => c.baseId == baseId);
      int count(String baseId) =>
          gold.where((c) => c.baseId == baseId).length;

      expect(has('building-storehouse'), isFalse);
      expect(has('building-toll-bridge'), isFalse);
      expect(has('unit-large-trade-ship'), isFalse);
      expect(has('city-expansion-harbor'), isFalse);
      expect(has('city-expansion-trading-base'), isFalse);
      expect(has('action-reiner-the-herald'), isFalse);
      expect(has('action-goldsmith'), isFalse);
      expect(has('action-brigands'), isFalse);

      expect(count('city-expansion-merchant-guild'), 1,
          reason:
              'inga ansikte-upp-kort i det här läget – den kvarvarande kopian blandas in i stället');
      expect(count('city-expansion-mint'), 1);
      expect(count('city-expansion-staple-house'), 1);
      expect(count('action-trade-master'), 1);

      expect(count('action-merchant'), 2, reason: 'orört');
      expect(count('unit-pirate-ship'), 2, reason: 'orört');
      expect(count('city-expansion-moneylender'), 1, reason: 'orört');
      expect(count('city-expansion-salt-silo'), 1, reason: 'orört');
      expect(count('action-gudrun'), 1, reason: 'orört');
      expect(count('region-expansion-gold-cache'), 1, reason: 'orört');
    });

    test(
        'Oroligheternas tids hög: de namngivna korten är helt borttagna, 1 Värdshus (av 2) kvar, orörda kort med fullt antal',
        () {
      final turmoil =
          DuelOfThePrincesSetup.shuffledDrawStacks(random: Random(4))[4];
      bool has(String baseId) => turmoil.any((c) => c.baseId == baseId);
      int count(String baseId) =>
          turmoil.where((c) => c.baseId == baseId).length;

      expect(has('building-drill-ground'), isFalse);
      expect(has('hero-carl-forkbeard'), isFalse);
      expect(has('hero-irmgard'), isFalse);
      expect(has('city-expansion-fairgrounds'), isFalse);
      expect(has('city-expansion-tithe-barn'), isFalse);
      expect(has('action-sebastian'), isFalse);

      expect(count('city-expansion-hedge-tavern'), 1,
          reason: 'inga ansikte-upp-kort i det här läget');
      expect(count('city-expansion-fire-brigade'), 1);
      expect(count('action-voyage-of-plunder'), 1);
      expect(count('action-archer'), 1);
      expect(count('action-arsonist'), 1);
      expect(count('action-traitor'), 1);

      expect(count('hero-heinrich-the-sentinel'), 1, reason: 'orört');
      expect(count('building-lookout-tower'), 1, reason: 'orört');
      expect(count('city-expansion-chapel-low'), 1, reason: 'orört');
      expect(count('city-expansion-chapel-high'), 1, reason: 'orört');
      expect(count('city-expansion-large-festival-hall'), 1, reason: 'orört');
      expect(count('action-brigands'), 1,
          reason: 'återanvänt från Gulderan, orört i Oroligheternas tids EGEN pool');
    });

    test(
        'Utvecklingens tids hög: de namngivna korten är helt borttagna, 1 Universitet (av 2) kvar, orörda kort med fullt antal',
        () {
      final progress =
          DuelOfThePrincesSetup.shuffledDrawStacks(random: Random(5))[5];
      bool has(String baseId) => progress.any((c) => c.baseId == baseId);
      int count(String baseId) =>
          progress.where((c) => c.baseId == baseId).length;

      expect(has('city-expansion-parliament'), isFalse);
      expect(has('action-brigitta'), isFalse);
      expect(has('action-relocation'), isFalse);

      expect(count('unit-chief-cannoneer'), 1);
      expect(count('city-expansion-town-hall'), 1);
      expect(count('city-expansion-university'), 1,
          reason: 'inga ansikte-upp-kort i det här läget');
      expect(count('city-expansion-library'), 1);
      expect(count('city-expansion-pharmacy'), 1);
      expect(count('city-expansion-bath-house'), 2);
      expect(count('action-three-field-system'), 1);
      expect(count('action-mineral-mining'), 1);
      expect(count('action-doctor'), 1);

      expect(count('action-benjamin'), 1, reason: 'orört');
      expect(count('action-guido'), 1, reason: 'orört');
      expect(count('action-gustav'), 1, reason: 'orört');
      expect(count('city-expansion-building-crane'), 1, reason: 'orört');
    });
  });

  group('shuffledEventDeck', () {
    test('alltid 12 kort totalt (11 icke-Jul + Jul), Jul 4:e kortet från botten',
        () {
      for (var seed = 0; seed < 50; seed++) {
        final deck =
            DuelOfThePrincesSetup.shuffledEventDeck(random: Random(seed));
        expect(deck.length, 12, reason: 'seed $seed');
        expect(deck[deck.length - 4].id, BasicSetCards.yule.id,
            reason: 'seed $seed');
        expect(deck.where((c) => c.id == BasicSetCards.yule.id).length, 1,
            reason: 'seed $seed');
      }
    });

    test('de automatiskt kvarvarande korten är alltid med (minst 1 vardera)',
        () {
      for (var seed = 0; seed < 50; seed++) {
        final deck =
            DuelOfThePrincesSetup.shuffledEventDeck(random: Random(seed));
        int count(String baseId) =>
            deck.where((c) => c.baseId == baseId).length;
        expect(count('event-invention'), greaterThanOrEqualTo(1),
            reason: 'seed $seed');
        expect(count('event-year-of-plenty'), greaterThanOrEqualTo(1),
            reason: 'seed $seed');
        expect(count('event-traveling-merchant'), greaterThanOrEqualTo(1),
            reason: 'seed $seed');
        expect(count('event-riots'), greaterThanOrEqualTo(1),
            reason: 'seed $seed');
        expect(count('event-plague'), greaterThanOrEqualTo(1),
            reason: 'seed $seed');
      }
    });

    test(
        'exakt 11 icke-Jul-kort varje gång: 5 automatiska + 6 av de 15 namngivna (aldrig fler, aldrig färre)',
        () {
      for (var seed = 0; seed < 50; seed++) {
        final deck =
            DuelOfThePrincesSetup.shuffledEventDeck(random: Random(seed));
        final nonYule =
            deck.where((c) => c.id != BasicSetCards.yule.id).length;
        expect(nonYule, 11, reason: 'seed $seed');
      }
    });

    test(
        'ett kort som ENBART finns i 15-poolen (inga automatiska kopior, t.ex. Gåva till fursten) är ibland med och ibland inte – bevisar att urvalet faktiskt är slumpmässigt',
        () {
      const trials = 60;
      var presentCount = 0;
      for (var seed = 0; seed < trials; seed++) {
        final deck =
            DuelOfThePrincesSetup.shuffledEventDeck(random: Random(seed));
        if (deck.any((c) => c.baseId == 'event-gift-for-the-prince')) {
          presentCount++;
        }
      }
      expect(presentCount, greaterThan(0));
      expect(presentCount, lessThan(trials));
    });
  });
}
