import 'package:catan_rivals/data/basic_set_draw_deck.dart';
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
