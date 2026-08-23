import 'package:flutter/material.dart';

import '../../data/basic_set_cards.dart';
import '../../data/era_of_gold_cards.dart';
import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import '../widgets/card_detail_dialog.dart';

/// Regelsidan: en kort sammanfattning av hur en omgång går till och
/// vinstvillkoret, händelsetärningens fem sidor, och (det som faktiskt
/// efterfrågades) en genomsökbar bildkatalog över samtliga korttyper i
/// grundspelet – tryck på ett kort för att se det förstorat med
/// kostnad/poäng/regeltext (samma [showCardDetail]-dialog som redan
/// används överallt annars i spelet, i stället för att bygga en egen,
/// duplicerad kortvy här).
///
/// Längst ner finns temaseten (t.ex. Gulderan/"The Era of Gold"), i en
/// egen, tydligt avgränsad sektion – de är BARA med här för
/// granskning (rätt kort/text/bilder) innan de eventuellt vävs in i
/// själva spelet, se [_EraSection]. Kort utan en riktig bild ännu
/// visas med en tydlig "Bild saknas"-platshållare (se [_CardTile])
/// i stället för att tyst falla tillbaka till en generisk brun ruta.
///
/// Nås via [RulesButton] (uppe till vänster) både på startskärmen
/// (lobby_screen.dart) och under själva spelet (game_board_screen.dart).
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CatanColors.parchment,
      appBar: AppBar(title: const Text('Regler')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Så funkar en omgång'),
          const _RuleStep(
              number: 1,
              text:
                  'Slå produktions- och händelsetärningen samtidigt. '
                  'Varje region med det slagna talet ger 1 resurs, om det '
                  'finns lagringsutrymme kvar.'),
          const _RuleStep(
              number: 2,
              text:
                  'Utför dina actions: bygg vägar/byar/städer/utbyggnader, '
                  'spela handlingskort, handla med motståndaren.'),
          const _RuleStep(
              number: 3,
              text:
                  'Kontrollera handen: dra upp till, eller slänger ner till, '
                  'ditt handkortslimit (3 + 1 per framstegspoäng du har i '
                  'spel).'),
          const _RuleStep(
              number: 4,
              text:
                  'Byt kort: låt handen vara, byt ett kort gratis, eller '
                  'betala 2 valfria resurser för att kika i en hel '
                  'draghög innan turen lämnas över.'),
          const SizedBox(height: 20),
          const _SectionHeader('Vinstvillkor'),
          const _InfoCard(
            icon: Icons.emoji_events,
            text:
                'Den som har 7 eller fler segerpoäng vid slutet av sin '
                'EGEN runda vinner matchen direkt.',
          ),
          const SizedBox(height: 20),
          const _SectionHeader('Händelsetärningen'),
          for (final face in EventDieFace.values)
            _EventFaceTile(face: face),
          const SizedBox(height: 20),
          const _SectionHeader('Alla kort i grundspelet'),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Tryck på ett kort för att se det förstorat med kostnad, '
              'poäng och regeltext.',
              style: TextStyle(fontSize: 12.5, color: CatanColors.inkSoft),
            ),
          ),
          _CardGroup(
            title: 'Regioner',
            cards: BasicSetCards.all
                .where((c) => c.category == CardCategory.region)
                .toList(),
          ),
          _CardGroup(
            title: 'Byar, städer & vägar',
            cards: BasicSetCards.all
                .where((c) => c.category == CardCategory.settlement ||
                    c.category == CardCategory.city ||
                    c.category == CardCategory.road)
                .toList(),
          ),
          _CardGroup(
            title: 'Handlingskort',
            cards: BasicSetCards.all
                .where((c) => c.category == CardCategory.action)
                .toList(),
          ),
          _CardGroup(
            title: 'Byggnader',
            cards: BasicSetCards.all
                .where((c) =>
                    c.category == CardCategory.expansion &&
                    c.expansionKind == ExpansionKind.building)
                .toList(),
          ),
          _CardGroup(
            title: 'Hjältar',
            cards: BasicSetCards.all
                .where((c) =>
                    c.category == CardCategory.expansion &&
                    c.expansionKind == ExpansionKind.hero)
                .toList(),
          ),
          _CardGroup(
            title: 'Handelsskepp',
            cards: BasicSetCards.all
                .where((c) =>
                    c.category == CardCategory.expansion &&
                    c.expansionKind == ExpansionKind.tradeShip)
                .toList(),
          ),
          _CardGroup(
            title: 'Övriga enheter',
            cards: BasicSetCards.all
                .where((c) =>
                    c.category == CardCategory.expansion &&
                    c.expansionKind == ExpansionKind.otherUnit)
                .toList(),
          ),
          _CardGroup(
            title: 'Händelsekort',
            cards: BasicSetCards.all
                .where((c) => c.category == CardCategory.event)
                .toList(),
          ),
          const SizedBox(height: 28),
          const Divider(color: CatanColors.woodFrame, thickness: 1),
          const SizedBox(height: 12),
          _EraSection(
            title: 'Gulderan (The Era of Gold)',
            backAsset: CatanAssets.backEraGold,
            allCards: EraOfGoldCards.all,
            supplyCounts: EraOfGoldCards.supplyCounts,
            groups: [
              _EraGroup(
                  'Handlingskort',
                  (c) => c.category == CardCategory.action),
              _EraGroup('Landskapsutbyggnad',
                  (c) => c.category == CardCategory.regionExpansion),
              _EraGroup(
                  'Enheter', (c) => c.category == CardCategory.expansion),
              _EraGroup('Stadsutbyggnader',
                  (c) => c.category == CardCategory.cityExpansion),
              _EraGroup(
                  'Händelsekort', (c) => c.category == CardCategory.event),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: CatanColors.ink),
      ),
    );
  }
}

class _RuleStep extends StatelessWidget {
  final int number;
  final String text;

  const _RuleStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
                color: CatanColors.woodFrame, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$number',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 14, color: CatanColors.ink, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4DFA0).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC9A227), width: 1.4),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8A6A2A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 14, color: CatanColors.ink, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _EventFaceTile extends StatelessWidget {
  final EventDieFace face;

  const _EventFaceTile({required this.face});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CatanColors.parchmentDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(face.swedishName,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CatanColors.ink)),
            const SizedBox(height: 3),
            Text(face.ruleText,
                style: const TextStyle(
                    fontSize: 13, color: CatanColors.ink, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

/// En kategori-grupp inom ett temaset – bara titeln + vilka kort som
/// hör dit (se [_EraSection]).
class _EraGroup {
  final String title;
  final bool Function(GameCard) matches;

  const _EraGroup(this.title, this.matches);
}

/// Ett helt temaset (t.ex. Gulderan/"The Era of Gold"), tydligt
/// avgränsat från grundspelet: en guldkantad rubrik med kortbaksidan,
/// en granskningsnotis, kortgrupperna (se [_EraGroup]/[_CardGroup]),
/// och till sist en lista på de kort som ÅTERANVÄNDS rakt av från
/// grundspelet (bara fler fysiska kopior i det här setets stapel, se
/// t.ex. [EraOfGoldCards]s egen doc-kommentar) – de får ingen egen
/// kortruta här (det vore bara en dubblett av grundspelets), bara
/// namnen så att hela setets 27/... kort ändå går att stämma av mot
/// regelhäftets kortindex.
class _EraSection extends StatelessWidget {
  final String title;
  final String backAsset;
  final List<GameCard> allCards;
  final Map<String, int> supplyCounts;
  final List<_EraGroup> groups;

  const _EraSection({
    required this.title,
    required this.backAsset,
    required this.allCards,
    required this.supplyCounts,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    final newIds = allCards.map((c) => c.id).toSet();
    final byId = {for (final c in BasicSetCards.all) c.id: c};
    final reusedNames = supplyCounts.keys
        .where((id) => !newIds.contains(id))
        .map((id) => byId[id]?.name)
        .whereType<String>()
        .toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(backAsset, width: 44, height: 44 * 283 / 271,
                  fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _InfoCard(
          icon: Icons.construction,
          text:
              'Under granskning – inte med i själva spelet ännu. Kort utan '
              'en riktig bild visas med "Bild saknas" nedan.',
        ),
        const SizedBox(height: 14),
        for (final group in groups)
          _CardGroup(
              title: group.title,
              cards: allCards.where(group.matches).toList()),
        if (reusedNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              'Återanvänds rakt av från grundspelet (bara fler fysiska '
              'kopior i den här stapeln): ${reusedNames.join(', ')}.',
              style: const TextStyle(
                  fontSize: 12.5, color: CatanColors.inkSoft, height: 1.35),
            ),
          ),
      ],
    );
  }
}

/// En rubrik + rutnät av tryckbara korttumnaglar för en kategori.
/// Renderar ingenting (inte ens rubriken) om [cards] är tom – t.ex. om
/// grundspelet råkar sakna en viss [ExpansionKind].
class _CardGroup extends StatelessWidget {
  final String title;
  final List<GameCard> cards;

  const _CardGroup({required this.title, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CatanColors.ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final card in cards) _CardTile(card: card)],
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final GameCard card;

  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showCardDetail(context, card),
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      border: Border.all(color: CatanColors.woodFrame)),
                  child: Image.asset(
                    CatanAssets.resolveCardImage(card),
                    fit: BoxFit.cover,
                    // Tydlig "saknas"-platshållare (i stället för en
                    // tyst, tom brun ruta) – hela poängen med
                    // regelsidan för ett temaset under granskning är
                    // att just det här ska synas i ögonvrån.
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: CatanColors.parchmentDark,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_not_supported_outlined,
                              size: 20, color: CatanColors.inkSoft),
                          SizedBox(height: 2),
                          Text('Bild\nsaknas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: CatanColors.inkSoft,
                                  height: 1.1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              card.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: CatanColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
