import 'package:catan_rivals/data/basic_set_draw_deck.dart';
import 'package:catan_rivals/data/era_of_gold_draw_deck.dart';
import 'package:catan_rivals/data/era_of_progress_draw_deck.dart';
import 'package:catan_rivals/data/era_of_turmoil_draw_deck.dart';
import 'package:catan_rivals/data/event_deck.dart';
import 'package:catan_rivals/data/region_deck.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BasicSetDrawDeck', () {
    test('shuffles the 36 non-center, non-event cards into 4 stacks of 9', () {
      final stacks = BasicSetDrawDeck.shuffledFourStacks();

      expect(stacks, hasLength(4));
      for (final stack in stacks) {
        expect(stack, hasLength(9));
      }
      final allIds = stacks.expand((s) => s).map((c) => c.id).toSet();
      expect(allIds, hasLength(36)); // alla instanser har unika id:n
    });

    test('shuffledStacks(stackCount: 3) delar samma 36 kort i 3 högar à 12 (Gulderan)', () {
      final stacks = BasicSetDrawDeck.shuffledStacks(stackCount: 3);

      expect(stacks, hasLength(3));
      for (final stack in stacks) {
        expect(stack, hasLength(12));
      }
      final allIds = stacks.expand((s) => s).map((c) => c.id).toSet();
      expect(allIds, hasLength(36));
    });
  });

  group('EraOfGoldDrawDeck', () {
    test('faceUpCards() ger 2 unika Köpmansgille-kopior', () {
      final cards = EraOfGoldDrawDeck.faceUpCards();

      expect(cards, hasLength(2));
      expect(cards.map((c) => c.baseId).toSet(), {'city-expansion-merchant-guild'});
      expect(cards.map((c) => c.id).toSet(), hasLength(2)); // unika id:n
    });

    test('eventCards() ger de 3 händelsekorten som hör till setet', () {
      final cards = EraOfGoldDrawDeck.eventCards();

      expect(cards, hasLength(3));
      expect(
        cards.map((c) => c.baseId).toSet(),
        {'event-gift-for-the-prince', 'event-trade-ships-race', 'event-traveling-merchant'},
      );
    });

    test('shuffledTwoStacks() delar de 22 återstående korten i 2 högar à 11, utan förlust/dubblett', () {
      final stacks = EraOfGoldDrawDeck.shuffledTwoStacks();

      expect(stacks, hasLength(2));
      for (final stack in stacks) {
        expect(stack, hasLength(11));
      }

      // Facit: 27 fysiska kort totalt - 3 händelsekort - 2 ansikte-upp
      // Köpmansgille = 22 kvar till draghögarna (se EraOfGoldCards.supplyCounts).
      final drawnIds = stacks.expand((s) => s).map((c) => c.id).toSet();
      expect(drawnIds, hasLength(22));

      final faceUpIds = EraOfGoldDrawDeck.faceUpCards().map((c) => c.id).toSet();
      final eventIds = EraOfGoldDrawDeck.eventCards().map((c) => c.id).toSet();
      // Inga kort delas mellan draghögarna, ansikte-upp-högen och
      // händelsekortsstapeln.
      expect(drawnIds.intersection(faceUpIds), isEmpty);
      expect(drawnIds.intersection(eventIds), isEmpty);
      expect(drawnIds.length + faceUpIds.length + eventIds.length, 27);
    });
  });

  group('EraOfTurmoilDrawDeck', () {
    test('faceUpCards() ger 2 unika Värdshus-kopior', () {
      final cards = EraOfTurmoilDrawDeck.faceUpCards();

      expect(cards, hasLength(2));
      expect(cards.map((c) => c.baseId).toSet(), {'city-expansion-hedge-tavern'});
      expect(cards.map((c) => c.id).toSet(), hasLength(2)); // unika id:n
    });

    test('eventCards() ger de 4 händelsekorten som hör till setet', () {
      final cards = EraOfTurmoilDrawDeck.eventCards();

      expect(cards, hasLength(4));
      expect(
        cards.map((c) => c.baseId).toSet(),
        {'event-riots', 'event-feud', 'event-fraternal-feuds'},
      );
      expect(
          cards.where((c) => c.baseId == 'event-riots').length, 2);
    });

    test('shuffledTwoStacks() delar de 22 återstående korten i 2 högar à 11, utan förlust/dubblett', () {
      final stacks = EraOfTurmoilDrawDeck.shuffledTwoStacks();

      expect(stacks, hasLength(2));
      for (final stack in stacks) {
        expect(stack, hasLength(11));
      }

      // Facit: 28 fysiska kort totalt - 4 händelsekort - 2 ansikte-upp
      // Värdshus = 22 kvar till draghögarna (se
      // EraOfTurmoilCards.supplyCounts).
      final drawnIds = stacks.expand((s) => s).map((c) => c.id).toSet();
      expect(drawnIds, hasLength(22));

      final faceUpIds =
          EraOfTurmoilDrawDeck.faceUpCards().map((c) => c.id).toSet();
      final eventIds =
          EraOfTurmoilDrawDeck.eventCards().map((c) => c.id).toSet();
      expect(drawnIds.intersection(faceUpIds), isEmpty);
      expect(drawnIds.intersection(eventIds), isEmpty);
      expect(drawnIds.length + faceUpIds.length + eventIds.length, 28);
    });

    test('action-brigands (återanvänt från Gulderan) hamnar i draghögarna med rätt baseId', () {
      final drawnIds =
          EraOfTurmoilDrawDeck.shuffledTwoStacks().expand((s) => s);

      final brigands =
          drawnIds.where((c) => c.baseId == 'action-brigands').toList();
      expect(brigands, hasLength(1));
      expect(brigands.single.id, contains('-turmoil-draw-'));
    });
  });

  group('EraOfProgressDrawDeck', () {
    test('faceUpCards() ger 2 unika Universitet-kopior', () {
      final cards = EraOfProgressDrawDeck.faceUpCards();

      expect(cards, hasLength(2));
      expect(cards.map((c) => c.baseId).toSet(), {'city-expansion-university'});
      expect(cards.map((c) => c.id).toSet(), hasLength(2)); // unika id:n
    });

    test('eventCards() ger de 5 händelsekorten som hör till setet', () {
      final cards = EraOfProgressDrawDeck.eventCards();

      expect(cards, hasLength(5));
      expect(
        cards.map((c) => c.baseId).toSet(),
        {'event-plague', 'event-invention'},
      );
      expect(cards.where((c) => c.baseId == 'event-plague').length, 3);
      expect(cards.where((c) => c.baseId == 'event-invention').length, 2);
    });

    test('shuffledTwoStacks() delar de 24 återstående korten i 2 högar à 12, utan förlust/dubblett', () {
      final stacks = EraOfProgressDrawDeck.shuffledTwoStacks();

      expect(stacks, hasLength(2));
      for (final stack in stacks) {
        expect(stack, hasLength(12));
      }

      // Facit: 31 fysiska kort totalt - 5 händelsekort - 2 ansikte-upp
      // Universitet = 24 kvar till draghögarna (se
      // EraOfProgressCards.supplyCounts).
      final drawnIds = stacks.expand((s) => s).map((c) => c.id).toSet();
      expect(drawnIds, hasLength(24));

      final faceUpIds =
          EraOfProgressDrawDeck.faceUpCards().map((c) => c.id).toSet();
      final eventIds =
          EraOfProgressDrawDeck.eventCards().map((c) => c.id).toSet();
      expect(drawnIds.intersection(faceUpIds), isEmpty);
      expect(drawnIds.intersection(eventIds), isEmpty);
      expect(drawnIds.length + faceUpIds.length + eventIds.length, 31);
    });

    test('action-brigitta/action-relocation (återanvänt från grundspelet) hamnar i draghögarna med rätt baseId', () {
      final drawnIds =
          EraOfProgressDrawDeck.shuffledTwoStacks().expand((s) => s);

      final brigitta =
          drawnIds.where((c) => c.baseId == 'action-brigitta').toList();
      expect(brigitta, hasLength(1));
      expect(brigitta.single.id, contains('-progress-draw-'));
      final relocation =
          drawnIds.where((c) => c.baseId == 'action-relocation').toList();
      expect(relocation, hasLength(1));
      expect(relocation.single.id, contains('-progress-draw-'));
    });
  });

  group('EventDeck', () {
    test('has 9 cards with Yule as the 4th from the bottom', () {
      final deck = EventDeck.shuffledWithYuleFourthFromBottom();

      expect(deck, hasLength(9));
      // Index 0 = överst (dras först); Yule ska vara det 6:e kortet
      // uppifrån = 4:e från botten (3 kort under den).
      expect(deck[5].id, 'event-yule');
      expect(deck.where((c) => c.id == 'event-yule'), hasLength(1));
    });

    test('med extraCards (Gulderan) blir det 12 kort, Yule fortfarande 4:e från botten', () {
      final deck = EventDeck.shuffledWithYuleFourthFromBottom(
          extraCards: EraOfGoldDrawDeck.eventCards());

      expect(deck, hasLength(12));
      // 3 kort under Yule => Yule ligger på index length-4.
      expect(deck[deck.length - 4].id, 'event-yule');
      expect(deck.where((c) => c.id == 'event-yule'), hasLength(1));
      final allIds = deck.map((c) => c.id).toSet();
      expect(allIds, hasLength(12)); // inga dubbletter mellan bas och Gulderan
    });
  });

  group('RegionDeck', () {
    test('shuffles the 12 remaining region cards, 2 distinct numbers per type', () {
      final deck = RegionDeck.shuffledRemainingDeck();

      expect(deck, hasLength(12));
      final byType = <String, Set<int>>{};
      for (final card in deck) {
        byType.putIfAbsent(card.name, () => {}).add(card.productionNumber!);
      }
      for (final numbers in byType.values) {
        expect(numbers, hasLength(2)); // ingen regiontyp upprepar samma tal
      }
    });
  });
}
