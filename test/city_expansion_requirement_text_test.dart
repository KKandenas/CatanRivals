import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/data/era_of_gold_cards.dart';
import 'package:catan_rivals/data/era_of_progress_cards.dart';
import 'package:catan_rivals/data/era_of_turmoil_cards.dart';
import 'package:catan_rivals/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar att VARJE stadsutbyggnadskort (CardCategory.cityExpansion,
/// regelhäftets röda textruta: "kräver en befintlig stad") har "Stad"
/// med i sin [GameCard.requirement] – det fältet är den ENDA källan
/// till "Kräver: ..."-texten i kortets förstorade vy (se
/// card_detail_dialog.dart), och den kollas bara mot en riktig
/// byggplats (build_requirements.dart) när man faktiskt FÖRSÖKER
/// placera ut kortet – utan det här skulle spelaren aldrig se kravet
/// bara genom att trycka på kortet för att titta på det (rapporterad
/// bugg).
void main() {
  final allCards = [
    ...BasicSetCards.all,
    ...EraOfGoldCards.all,
    ...EraOfTurmoilCards.all,
    ...EraOfProgressCards.all,
  ];

  test('alla stadsutbyggnadskort nämner "Stad" i sitt requirement-fält', () {
    final cityExpansions =
        allCards.where((c) => c.category == CardCategory.cityExpansion);

    // Om det här slår till betyder det att listan nedan är tom (t.ex.
    // en framtida refaktor som byter kategori-enum) – bättre att
    // upptäcka det direkt än att testet tyst blir meningslöst.
    expect(cityExpansions, isNotEmpty);

    for (final card in cityExpansions) {
      expect(card.requirement, isNotNull,
          reason: '${card.name} saknar requirement helt');
      expect(card.requirement, contains('Stad'),
          reason:
              '${card.name} har requirement "${card.requirement}" men nämner inte "Stad"');
    }
  });

  test('inget kort UTANFÖR stadsutbyggnader nämner "Stad" i requirement '
      '(annars skulle vanliga by-/handlingskort felaktigt se ut att kräva stad)',
      () {
    final nonCityExpansions =
        allCards.where((c) => c.category != CardCategory.cityExpansion);

    for (final card in nonCityExpansions) {
      final requirement = card.requirement;
      if (requirement == null) continue;
      expect(requirement, isNot(contains('Stad')),
          reason:
              '${card.name} (${card.category}) nämner "Stad" men är ingen stadsutbyggnad');
    }
  });
}
