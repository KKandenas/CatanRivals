import 'dart:math';

import '../models/models.dart';
import 'basic_set_cards.dart';

/// Grundspelets fysiska regionkortsstapel: 24 kort totalt (matchar
/// grundspelets 94-korssumma: 9 by + 7 stad + 9 väg + 24 region + 36
/// draghögskort + 9 händelsekort = 94).
///
/// Regelhäftet säger bara att de två spelarnas starttal är "distribuerade
/// olika" (s. 4) utan att lista exakt vilka tal som finns på de kort som
/// INTE används i startuppställningen. Vi vet att varje regiontyp har 4
/// fysiska kopior (24 / 6 typer) och att de röda/blå starttalen (se
/// [StarterCards]) upptar 2 av de 4 – de återstående 2 per typ är en
/// rimlig, jämnt fördelad gissning (ingen regiontyp upprepar samma tal,
/// och varje tal 1–6 förekommer totalt 4 gånger över hela stapeln) i
/// väntan på att kollas mot de fysiska korten.
class RegionDeck {
  RegionDeck._();

  /// De 12 regionkort (2 per typ) som INTE ingår i någon av
  /// startuppställningarna – detta är den stapel man drar ifrån när man
  /// bygger nya byar under spelets gång.
  static const Map<String, List<int>> remainingNumbers = {
    'forest': [1, 6],
    'hills': [4, 5],
    'goldField': [2, 5],
    'pasture': [3, 6],
    'fields': [1, 2],
    'mountains': [3, 4],
  };

  static const Map<String, GameCard> _templates = {
    'forest': BasicSetCards.forest,
    'hills': BasicSetCards.hills,
    'goldField': BasicSetCards.goldField,
    'pasture': BasicSetCards.pasture,
    'fields': BasicSetCards.fields,
    'mountains': BasicSetCards.mountains,
  };

  /// Bygger en ny, blandad kopia av de 12 återstående regionkorten.
  /// Ny instans och nytt `id` per kort varje gång, så ett helt nytt
  /// parti inte råkar återanvända identiska korts-id:n från ett
  /// tidigare parti.
  static List<GameCard> shuffledRemainingDeck({Random? random}) {
    final rng = random ?? Random();
    var counter = 0;
    final cards = <GameCard>[
      for (final entry in remainingNumbers.entries)
        for (final number in entry.value)
          _templates[entry.key]!.copyWith(
            id: '${_templates[entry.key]!.id}-deck-${counter++}',
            productionNumber: number,
          ),
    ];
    cards.shuffle(rng);
    return cards;
  }
}
