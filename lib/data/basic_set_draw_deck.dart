import 'dart:math';

import '../models/models.dart';
import 'basic_set_cards.dart';

/// Grundspelets 4 "draghögar" (regelhäftet s. 4, steg 3): de 36 fysiska
/// korten som INTE är center-kort (by/stad/väg/region) eller
/// händelsekort – alla handlingar, byggnader, enheter och hjältar.
/// "Shuffle the 36 cards whose backs show the Basic Set symbol. Divide
/// these into 4 stacks of 9 cards each."
class BasicSetDrawDeck {
  BasicSetDrawDeck._();

  static final Map<String, GameCard> _byId = {for (final c in BasicSetCards.all) c.id: c};

  static const _excludedIds = {'settlement', 'city', 'road'};

  static List<GameCard> _allDrawCards() {
    final cards = <GameCard>[];
    BasicSetCards.supplyCounts.forEach((id, count) {
      if (_excludedIds.contains(id) || id.startsWith('event-')) return;
      final template = _byId[id];
      if (template == null) return;
      for (var i = 0; i < count; i++) {
        cards.add(template.copyWith(id: '$id-draw-$i'));
      }
    });
    return cards;
  }

  /// Blandar de 36 korten och delar upp dem i 4 jämna, 9-korts högar –
  /// tunn genväg till [shuffledStacks] för grundspelets ordinarie
  /// uppställning (utan aktiva temaset).
  static List<List<GameCard>> shuffledFourStacks({Random? random}) =>
      shuffledStacks(stackCount: 4, random: random);

  /// Blandar de 36 korten och delar upp dem i [stackCount] så jämna
  /// högar som möjligt (36 går jämnt upp i både 4 och 3, se
  /// [GameNotifier._resetDecks] – med Gulderan aktivt blir det 3
  /// högar i stället för 4, för att lämna plats åt Gulderans egna 2).
  static List<List<GameCard>> shuffledStacks(
      {required int stackCount, Random? random}) {
    final rng = random ?? Random();
    final cards = _allDrawCards()..shuffle(rng);
    final stacks = <List<GameCard>>[];
    final base = cards.length ~/ stackCount;
    var offset = 0;
    for (var i = 0; i < stackCount; i++) {
      final isLast = i == stackCount - 1;
      final end = isLast ? cards.length : offset + base;
      stacks.add(cards.sublist(offset, end));
      offset = end;
    }
    return stacks;
  }
}
