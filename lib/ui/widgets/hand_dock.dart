import 'package:flutter/material.dart';

import '../../data/basic_set_cards.dart';
import '../../data/era_of_gold_cards.dart';
import '../../models/models.dart';
import '../theme/catan_colors.dart';
import 'card_detail_dialog.dart';
import 'expansion_card_view.dart';
import 'face_up_expansion_pile.dart';
import 'pop_in.dart';
import 'score_summary.dart';

/// Om [card] är ett handlingskort med ett krav som [player] inte
/// uppfyller just nu, returneras en förklarande text (visas i stället
/// för "Använd kortet", se [showCardDetail]:blockedReason) – annars
/// `null`. Handelskaravan ("Släng exakt 2 av dina resurser...") kräver
/// minst 2 resurser av valfri typ totalt, Guldsmed ("Släng 3 guld...")
/// kräver minst 3 guld – båda måste gå att betala för att kortet
/// överhuvudtaget ska gå att spela. Gulderans Rövare/Köpman/
/// Handelsmästare har egna, tidigare okontrollerade krav (se
/// [GameCard.requirement], som bara är visningstext – den här
/// funktionen är den faktiska spärren): styrkeövertag, 3 handelspoäng
/// eller stad, respektive ett utplacerat Köpmansgille.
/// [hasStrengthAdvantage] måste skickas in separat eftersom den kräver
/// att jämföra BÅDA spelarnas styrkepoäng ([GameState.strengthAdvantagePlayerId]),
/// inte något som går att räkna ut från bara [player].
String? _actionCardBlockedReason(GameCard card, Player player,
    {required bool hasStrengthAdvantage}) {
  if (card.baseId == BasicSetCards.merchantCaravan.id) {
    if (player.totalResourceCount < 2) {
      return 'Du behöver minst 2 resurser för att kunna använda det här kortet.';
    }
  }
  if (card.baseId == BasicSetCards.goldsmith.id) {
    if (player.resourceCount(ResourceType.gold) < 3) {
      return 'Du behöver minst 3 guld för att kunna använda det här kortet.';
    }
  }
  if (card.baseId == EraOfGoldCards.brigands.id) {
    if (!hasStrengthAdvantage) return 'Kräver styrkeövertag.';
  }
  if (card.baseId == EraOfGoldCards.merchant.id) {
    if (player.principality.totalCommercePoints < 3 &&
        !player.principality.hasCity) {
      return 'Kräver 3 handelspoäng eller en stad.';
    }
  }
  if (card.baseId == EraOfGoldCards.tradeMaster.id) {
    if (!player.principality.hasExpansionCard(EraOfGoldCards.merchantGuild.id)) {
      return 'Kräver Köpmansgille i ditt rike.';
    }
  }
  return null;
}

/// Bottenfältet (~10%): halvtransparent docka med handkort samt
/// spelarens aktuella ställning (VP och poäng).
///
/// Bygg-/enhetskort (kategori [CardCategory.expansion]) går att
/// långtrycka-och-dra upp på det egna riket för att spela dem – se
/// [PrincipalityGrid]. Handlingskort (kategori [CardCategory.action])
/// är inte dragbara – de spelas med regelhäftets "tvåstegsraket": ett
/// tryck förstorar kortet ([showCardDetail]), som då frågar "Vill du
/// använda kortet?" (se [onUseActionCard]). Undantaget är Spejare
/// (regelhäftets "action-scout"), som bara går att använda i samma
/// stund som en ny by byggs – den frågan visas i stället automatiskt
/// då (se GameNotifier.dropSettlement), så ett tryck på Spejare i
/// handen visar bara det vanliga, rena kortförstoringsläget.
///
/// Handelskaravan och Guldsmed har dessutom ett resurskrav för att gå
/// att spela (se [_actionCardBlockedReason]) – är det inte uppfyllt
/// visas ingen "Använd kortet"-fråga, bara en förklarande text i den
/// förstorade kortvyn (card_detail_dialog.dart:blockedReason).
class HandDock extends StatelessWidget {
  final Player player;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;

  /// Anropas när spelaren bekräftar "Vill du använda kortet?" för ett
  /// handlingskort (utom Spejare, se klassdoc). Notifiern avgör själv
  /// vad "använda" innebär för respektive kort.
  final void Function(GameCard card)? onUseActionCard;

  /// Om det är din tur just nu – varken Brigitta eller övriga
  /// handlingskort (se [canBuild]) går att spela på motståndarens tur,
  /// så ett tryck visar då bara den vanliga, rena kortförstoringen
  /// (ingen "Vill du använda kortet?"-fråga) i stället för att låta
  /// spelaren välja/bekräfta och sedan möta ett "Inte din tur"-fel.
  final bool isMyTurn;

  /// Om tärningen redan är slagen den här omgången – Brigitta får bara
  /// spelas INNAN tärningen slås (regelhäftet: "Play this card before
  /// rolling the dice"), så ett tryck på den visar bara den vanliga,
  /// rena kortförstoringen (ingen "Vill du använda kortet?"-fråga) när
  /// det här är sant, i stället för att låta spelaren välja ett tal och
  /// sedan möta ett felmeddelande.
  final bool diceRolled;

  /// Om bygg-/enhetskort går att dra ut på riket just nu (se
  /// [GameState.canBuildRightNow]) – annars visas de bara, precis som
  /// handlingskort, i stället för att gå att dra och sedan mötas av ett
  /// felmeddelande efter "Betalt". Övriga handlingskort (utom Brigitta,
  /// se [diceRolled]) delar samma villkor: de spelas under action-fasen
  /// (efter tärningsslaget, ingen annan väljare aktiv) precis som ett
  /// bygge, så samma flagga styr om deras "Använd kortet?"-fråga går
  /// att öppna över huvud taget.
  final bool canBuild;

  /// Om [player] just nu har styrkeövertaget (se
  /// [GameState.strengthAdvantagePlayerId]) – Gulderans Rövare kräver
  /// det (se [_actionCardBlockedReason]). Måste skickas in förberäknad
  /// härifrån eftersom den kräver att jämföra BÅDA spelarnas
  /// styrkepoäng, inte bara [player]s egna.
  final bool hasStrengthAdvantage;

  /// Handjustering i slutet av action-fasen (se [HandAdjustmentPhase.
  /// discarding]): om satt går varje handkort (oavsett kategori) att
  /// trycka på för att välja det att slänga i stället för att förstora
  /// det – normal dra-för-att-bygga är avstängd medan det här pågår.
  final GameCard? selectedDiscardCard;
  final void Function(GameCard card)? onSelectForDiscard;

  /// Totalpoäng och brickinnehav (se [ScoreSummary]) – räknas ut i
  /// [GameState], inte i den här rent presentationslagret-widgeten.
  final int totalVictoryPoints;
  final bool hasHeroToken;
  final bool hasTradeToken;

  /// Ditt EGET ansikte-upp-kort (se [Player.faceUpExpansionCard]-doc)
  /// – visas mellan handkorten och [ScoreSummary], i samma format som
  /// ett vanligt handkort (72×72, se [_CardFace._size]). Varje spelare
  /// har sin egen, separata plats (motståndarens sida behöver inte se
  /// den alls) – bygger man kortet blir det `null` här, se
  /// [GameNotifier.buyFaceUpExpansion].
  final GameCard? faceUpExpansionCard;
  final void Function(GameCard card)? onFaceUpDragStarted;
  final VoidCallback? onFaceUpDragEnd;

  const HandDock({
    super.key,
    required this.player,
    this.onDragStarted,
    this.onDragEnd,
    this.onUseActionCard,
    this.isMyTurn = true,
    this.diceRolled = false,
    this.canBuild = true,
    this.hasStrengthAdvantage = false,
    this.selectedDiscardCard,
    this.onSelectForDiscard,
    required this.totalVictoryPoints,
    this.hasHeroToken = false,
    this.hasTradeToken = false,
    this.faceUpExpansionCard,
    this.onFaceUpDragStarted,
    this.onFaceUpDragEnd,
  });

  /// Exponerad så TotalScoreBoard kan placera sig ovanför dockan i
  /// stället för att skarva ihop med dess egen ScoreSummary-ruta i
  /// samma hörn.
  static const double dockHeight = 92;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: dockHeight,
      color: CatanColors.woodFrameDark.withValues(alpha: 0.75),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: player.hand.isEmpty
                    ? const Center(
                        child: Text('Inga handkort',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: player.hand.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        // PopIn nyckelas på kortets id (inte bara
                        // index) så att den bara tonar in/glider upp
                        // ett kort som faktiskt är nytt i handen – ett
                        // kort som redan låg där behåller sitt State
                        // (och spelar alltså inte om animationen) även
                        // om det byter position i listan.
                        itemBuilder: (context, i) => PopIn(
                          key: ValueKey(player.hand[i].id),
                          child: _HandCard(
                            card: player.hand[i],
                            player: player,
                            onDragStarted: onDragStarted,
                            onDragEnd: onDragEnd,
                            onUseActionCard: onUseActionCard,
                            isMyTurn: isMyTurn,
                            diceRolled: diceRolled,
                            canBuild: canBuild,
                            hasStrengthAdvantage: hasStrengthAdvantage,
                            selected: player.hand[i] == selectedDiscardCard,
                            onSelectForDiscard: onSelectForDiscard == null
                                ? null
                                : () => onSelectForDiscard!(player.hand[i]),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              if (faceUpExpansionCard != null) ...[
                FaceUpExpansionPile(
                  cards: [faceUpExpansionCard!],
                  onDragStarted: onFaceUpDragStarted,
                  onDragEnd: onFaceUpDragEnd,
                  canBuild: canBuild,
                  cardSize: _CardFace._size,
                ),
                const SizedBox(width: 12),
              ],
              ScoreSummary(
                player: player,
                totalVictoryPoints: totalVictoryPoints,
                hasHeroToken: hasHeroToken,
                hasTradeToken: hasTradeToken,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandCard extends StatelessWidget {
  final GameCard card;
  final Player player;
  final void Function(GameCard card)? onDragStarted;
  final VoidCallback? onDragEnd;
  final void Function(GameCard card)? onUseActionCard;
  final bool isMyTurn;
  final bool diceRolled;
  final bool canBuild;
  final bool hasStrengthAdvantage;
  final bool selected;
  final VoidCallback? onSelectForDiscard;

  const _HandCard({
    required this.card,
    required this.player,
    this.onDragStarted,
    this.onDragEnd,
    this.onUseActionCard,
    this.isMyTurn = true,
    this.diceRolled = false,
    this.canBuild = true,
    this.hasStrengthAdvantage = false,
    this.selected = false,
    this.onSelectForDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final playable = card.category == CardCategory.expansion ||
        card.category == CardCategory.regionExpansion ||
        card.category == CardCategory.cityExpansion;
    // Spejare undantas: den frågas automatiskt vid by-bygge i stället
    // (se klassdocen på [HandDock]), inte via ett tryck i handen.
    // Brigitta och Reiner härolden går bara att spela på din egen tur,
    // INNAN tärningen slås (regelhäftet) – övriga handlingskort delar i
    // stället samma villkor som byggkort ([canBuild], se HandDock-doc),
    // eftersom de spelas under action-fasen (efter tärningsslaget,
    // ingen annan väljare aktiv) precis som ett bygge. Annars visas
    // bara den vanliga kortförstoringen, utan "använd"-frågan, i
    // stället för att gå att trycka och sedan mötas av ett
    // felmeddelande.
    final isBrigitta = card.baseId == BasicSetCards.brigittaTheWiseWoman.id;
    final isReiner = card.baseId == EraOfGoldCards.reinerTheHerald.id;
    final isUsableAction = card.category == CardCategory.action &&
        card.baseId != BasicSetCards.scout.id &&
        ((isBrigitta || isReiner) ? (isMyTurn && !diceRolled) : canBuild);

    // Under handjusteringen (slänga kort) går varje kort – oavsett
    // kategori – bara att trycka på för att välja det, ingen dra-för-
    // att-bygga: det är inte läge att bygga mitt i handjusteringen.
    if (onSelectForDiscard != null) {
      return _CardFace(
          card: card,
          playable: playable,
          selected: selected,
          onTap: onSelectForDiscard);
    }

    final blockedReason = isUsableAction
        ? _actionCardBlockedReason(card, player,
            hasStrengthAdvantage: hasStrengthAdvantage)
        : null;
    final useActionTap = isUsableAction && onUseActionCard != null
        ? () => showCardDetail(context, card,
            onUseCard:
                blockedReason == null ? () => onUseActionCard!(card) : null,
            blockedReason: blockedReason)
        : null;

    final face = _CardFace(card: card, playable: playable, onTap: useActionTap);

    // Bygg-/enhetskort är bara dragbara när det faktiskt går att bygga
    // just nu (se [GameState.canBuildRightNow]) – annars bara den
    // vanliga kortförstoringen, i stället för att kortet går att dra
    // ut och mötas av ett felmeddelande efter "Betalt".
    if (!playable || !canBuild) return face;

    return LongPressDraggable<GameCard>(
      data: card,
      delay: const Duration(milliseconds: 180),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
            scale: 1.12, child: _CardFace(card: card, playable: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: face),
      onDragStarted: () => onDragStarted?.call(card),
      onDragEnd: (_) => onDragEnd?.call(),
      // En riktig fingertryck varar ofta längre än 180ms, så
      // LongPressDraggable hinner vinna gest-arenan (och starta en
      // "drag") innan ett vanligt tryck (ExpansionCardViews egen
      // GestureDetector) någonsin får chansen – annars skulle
      // dragbara handkort inte gå att trycka på alls. Släpps kortet
      // sedan utan att träffa ett giltigt mål (dvs. draget avbryts),
      // tolkar vi det som ett tryck och visar kortet förstorat.
      onDraggableCanceled: (_, __) {
        onDragEnd?.call();
        showCardDetail(context, card);
      },
      child: face,
    );
  }
}

class _CardFace extends StatelessWidget {
  final GameCard card;
  final bool playable;
  final bool selected;
  final VoidCallback? onTap;

  const _CardFace({
    required this.card,
    required this.playable,
    this.selected = false,
    this.onTap,
  });

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExpansionCardView(card: card, showCost: playable, onTap: onTap),
          // IgnorePointer är avgörande här: en odekorerad ram ovanpå
          // ExpansionCardView i samma Stack fångar annars trycket själv
          // (träffar den tomma DecoratedBox:en, inte kortet under) –
          // det gjorde t.ex. byggnads-/hjältekort (playable==true)
          // helt otryckbara under handjusteringens slängval, som bara
          // skickar med `onTap` hit via _CardFace, inte via
          // LongPressDraggable (som har sin egen, yttre gesthantering
          // och därför inte drabbades).
          if (selected)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent, width: 2.4),
                ),
              ),
            )
          else if (playable)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: const Color(0xFF7CBF6A), width: 1.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
