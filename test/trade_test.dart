import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar kortbytesfasen (regelhäftet s. 9 "Trading cards"), sist i
/// omgången efter handjusteringen (se hand_adjustment_test.dart): tre
/// val – låt handen vara, byt ett kort gratis, eller betala 2 valfria
/// resurser för att kika i en hel draghög. Se [TradePhase].
void main() {
  /// Rullar tärningen och avslutar action-fasen tills kortbytesfasens
  /// tre val väntar – playLocally() ger en starthand på exakt
  /// handLimit (3) kort, så handjusteringen hoppas alltid över.
  ProviderContainer readyContainer() {
    final container = ProviderContainer();
    final notifier = container.read(gameProvider.notifier);
    notifier.playLocally();
    notifier.rollProductionDie();
    notifier.endActionPhase();
    expect(container.read(gameProvider).tradePhase, TradePhase.choosing);
    return container;
  }

  group('Kortbytesfasen', () {
    test('skipTrade lämnar turen direkt', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.skipTrade(), isNull);

      final state = container.read(gameProvider);
      expect(state.tradePhase, TradePhase.none);
      expect(state.activePlayerId, 'opponent');
    });

    test('gratis byte: slänger ett kort till en hög, drar ett från en annan, sedan lämnas turen över', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.startExchange(), isNull);
      expect(container.read(gameProvider).tradePhase, TradePhase.exchangeDiscard);

      final handBefore = container.read(gameProvider).you.hand;
      final discarded = handBefore.first;
      final stack0Before = container.read(gameProvider).centerStacks['draw1']!;

      expect(notifier.exchangeDiscard(discarded, 0), isNull);
      final afterDiscard = container.read(gameProvider);
      expect(afterDiscard.tradePhase, TradePhase.exchangeDraw);
      expect(afterDiscard.you.hand.contains(discarded), isFalse);
      expect(afterDiscard.you.hand, hasLength(2));
      expect(afterDiscard.centerStacks['draw1'], stack0Before + 1);
      expect(afterDiscard.activePlayerId, 'you'); // turen väntar fortfarande

      final stack1Before = container.read(gameProvider).centerStacks['draw2']!;
      expect(notifier.exchangeDraw(1), isNull);

      final after = container.read(gameProvider);
      expect(after.you.hand, hasLength(3));
      expect(after.centerStacks['draw2'], stack1Before - 1);
      expect(after.tradePhase, TradePhase.none);
      expect(after.activePlayerId, 'opponent');
    });

    test('kika: betala, släng, välj hög, se alla kort i ordning, behåll ett – resten läggs tillbaka i samma ordning', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);

      expect(notifier.startPeek(), isNull);
      expect(container.read(gameProvider).tradePhase, TradePhase.peekPaying);

      expect(notifier.confirmPeekPayment(), isNull);
      expect(container.read(gameProvider).tradePhase, TradePhase.peekDiscard);

      // Precis som det gratis bytet slänger man ett kort innan man
      // kikar – annars skulle handen bara växa med ett extra kort.
      final handBeforeDiscard = container.read(gameProvider).you.hand;
      final discarded = handBeforeDiscard.first;
      final stack0Before = container.read(gameProvider).centerStacks['draw1']!;

      expect(notifier.peekDiscardCard(discarded, 0), isNull);
      final afterDiscard = container.read(gameProvider);
      expect(afterDiscard.tradePhase, TradePhase.peekChoosingStack);
      expect(afterDiscard.you.hand.contains(discarded), isFalse);
      expect(afterDiscard.centerStacks['draw1'], stack0Before + 1);

      final stackBefore = notifier.drawStack(2);
      expect(stackBefore, isNotEmpty);

      expect(notifier.choosePeekStack(2), isNull);
      final peeking = container.read(gameProvider);
      expect(peeking.tradePhase, TradePhase.peekViewing);
      expect(peeking.peekStackIndex, 2);
      expect(peeking.peekedCards, stackBefore); // exakt samma ordning

      final chosen = stackBefore[stackBefore.length ~/ 2]; // ett kort mitt i högen
      final handBefore = peeking.you.hand.length;

      expect(notifier.peekTakeCard(chosen), isNull);
      final after = container.read(gameProvider);
      expect(after.you.hand, hasLength(handBefore + 1));
      expect(after.you.hand.contains(chosen), isTrue);
      expect(after.tradePhase, TradePhase.none);
      expect(after.activePlayerId, 'opponent');
      expect(after.peekStackIndex, isNull);
      expect(after.peekedCards, isNull);

      // De kvarvarande korten ligger fortfarande i exakt samma
      // inbördes ordning, bara med det valda kortet borttaget.
      final expectedRemaining = List<GameCard>.of(stackBefore)..remove(chosen);
      expect(notifier.drawStack(2), expectedRemaining);
    });

    test('cancelPeek går tillbaka till de tre huvudvalen', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);

      notifier.startPeek();
      expect(container.read(gameProvider).tradePhase, TradePhase.peekPaying);

      expect(notifier.cancelPeek(), isNull);
      expect(container.read(gameProvider).tradePhase, TradePhase.choosing);
      expect(container.read(gameProvider).activePlayerId, 'you');
    });

    test('bygga är blockerat under kortbytesfasen', () {
      final container = readyContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);

      final card = container.read(gameProvider).you.hand.first;
      final error = notifier.dropExpansion(0, BuildingRow.above, 0, card);

      expect(error, isNotNull);
      expect(container.read(gameProvider).you.hand.contains(card), isTrue);
    });

    test('kortbytesmetoderna är no-op utanför sin fas', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.rollProductionDie(); // standardläget: tradePhase är none

      expect(notifier.skipTrade(), isNull);
      expect(notifier.startExchange(), isNull);
      expect(notifier.startPeek(), isNull);
      expect(notifier.confirmPeekPayment(), isNull);
      expect(notifier.cancelPeek(), isNull);
      expect(notifier.choosePeekStack(0), isNull);
      expect(container.read(gameProvider).tradePhase, TradePhase.none);

      final hand = container.read(gameProvider).you.hand;
      expect(notifier.exchangeDiscard(hand.first, 0), isNull);
      expect(notifier.exchangeDraw(0), isNull);
      expect(notifier.peekDiscardCard(hand.first, 0), isNull);
      expect(notifier.peekTakeCard(hand.first), isNull);
      expect(container.read(gameProvider).you.hand, hasLength(5)); // oförändrad
    });
  });
}
