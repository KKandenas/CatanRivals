import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/state/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar handjusteringen i slutet av action-fasen (regelhäftet s. 9):
/// för få kort ska dras upp, för många ska slängas, tills handen matchar
/// [GameState.handLimit] (3 + framstegspoäng). Se [GameNotifier.endActionPhase].
void main() {
  group('Handjustering', () {
    test('rätt antal kort från start: avsluta action-fasen går direkt till kortbytesfasen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.playLocally();

      expect(container.read(gameProvider).you.hand, hasLength(3));
      expect(container.read(gameProvider).handLimit, 3);

      notifier.rollProductionDie();
      final error = notifier.endActionPhase();

      expect(error, isNull);
      final state = container.read(gameProvider);
      expect(state.handAdjustmentPhase, HandAdjustmentPhase.none);
      expect(state.tradePhase, TradePhase.choosing);
      expect(state.activePlayerId, 'you'); // turen väntar på kortbytesvalet

      notifier.skipTrade();
      expect(container.read(gameProvider).activePlayerId, 'opponent');
    });

    test('för få handkort: dra-läge tills gränsen är nådd, sedan lämnas turen över', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      // Standardläget (utan playLocally) har en fast hand på 5 kort och
      // 4 lediga byggplatser på starturppställningen – spela bort 3 av
      // dem för att hamna under gränsen (3) på ett deterministiskt sätt.
      notifier.rollProductionDie();
      final hand = container.read(gameProvider).you.hand;
      expect(hand, hasLength(5));

      notifier.dropExpansion(0, BuildingRow.above, 0, hand[0]);
      notifier.dropExpansion(0, BuildingRow.below, 0, hand[1]);
      notifier.dropExpansion(2, BuildingRow.above, 0, hand[2]);
      expect(container.read(gameProvider).you.hand, hasLength(2));

      final error = notifier.endActionPhase();
      expect(error, isNull);
      expect(container.read(gameProvider).handAdjustmentPhase, HandAdjustmentPhase.drawing);
      expect(container.read(gameProvider).activePlayerId, 'you'); // turen väntar

      final drawStack0Before = container.read(gameProvider).centerStacks['draw1'];
      final drawError1 = notifier.drawHandCard(0);
      expect(drawError1, isNull);
      expect(container.read(gameProvider).you.hand, hasLength(3));
      expect(container.read(gameProvider).centerStacks['draw1'], drawStack0Before! - 1);
      // Fortfarande under gränsen (3 < handLimit efter att den ökat med
      // 0 framstegspoäng är fortfarande bara 3) – alltså redan klar här,
      // eftersom handLimit är 3 och vi nu har 3 kort. Går direkt vidare
      // till kortbytesfasen (inte turen) – se trade_test.dart.
      final after = container.read(gameProvider);
      expect(after.handAdjustmentPhase, HandAdjustmentPhase.none);
      expect(after.tradePhase, TradePhase.choosing);
      expect(after.activePlayerId, 'you');

      notifier.skipTrade();
      final finished = container.read(gameProvider);
      expect(finished.activePlayerId, 'opponent');
      expect(finished.diceRolled, isFalse);
    });

    test('för många handkort: släng-läge tills gränsen är nådd, sedan lämnas turen över', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      // Standardläget (utan playLocally) har en fast hand på 5 kort,
      // vilket är fler än handLimit (3) utan att något behöver spelas
      // bort först.
      notifier.rollProductionDie();
      final before = container.read(gameProvider);
      expect(before.you.hand, hasLength(5));
      expect(before.handLimit, 3);

      final enterError = notifier.endActionPhase();
      expect(enterError, isNull);
      expect(container.read(gameProvider).handAdjustmentPhase, HandAdjustmentPhase.discarding);
      expect(container.read(gameProvider).activePlayerId, 'you'); // turen väntar

      final drawStack0Before = container.read(gameProvider).centerStacks['draw1']!;
      final firstCard = container.read(gameProvider).you.hand.first;
      final discardError1 = notifier.discardHandCard(firstCard, 0);
      expect(discardError1, isNull);
      expect(container.read(gameProvider).you.hand, hasLength(4));
      expect(container.read(gameProvider).you.hand.contains(firstCard), isFalse);
      expect(container.read(gameProvider).centerStacks['draw1'], drawStack0Before + 1);
      expect(container.read(gameProvider).handAdjustmentPhase, HandAdjustmentPhase.discarding);
      expect(container.read(gameProvider).activePlayerId, 'you'); // fortfarande inte klar

      final secondCard = container.read(gameProvider).you.hand.first;
      final discardError2 = notifier.discardHandCard(secondCard, 1);
      expect(discardError2, isNull);
      final after = container.read(gameProvider);
      expect(after.you.hand, hasLength(3));
      expect(after.handAdjustmentPhase, HandAdjustmentPhase.none);
      expect(after.tradePhase, TradePhase.choosing);
      expect(after.activePlayerId, 'you');

      notifier.skipTrade();
      final finished = container.read(gameProvider);
      expect(finished.activePlayerId, 'opponent');
      expect(finished.diceRolled, isFalse);
    });

    test('drawHandCard/discardHandCard är no-op utanför sitt läge', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      notifier.rollProductionDie();
      final hand = container.read(gameProvider).you.hand;

      expect(notifier.drawHandCard(0), isNull);
      expect(container.read(gameProvider).you.hand, hasLength(5)); // oförändrad

      expect(notifier.discardHandCard(hand.first, 0), isNull);
      expect(container.read(gameProvider).you.hand, hasLength(5)); // oförändrad
    });
  });
}
