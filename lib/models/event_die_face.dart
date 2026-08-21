/// De fem symbolerna på händelsetärningen, som slås samtidigt med
/// produktionstärningen (regelhäftet, referenskortet för
/// händelsetärningen): en sexsidig tärning där [eventCard] ("?") tar
/// upp två av sidorna, de andra fyra en var.
///
/// Bara själva tärningsslaget och regeltexten byggs här – vad som
/// faktiskt händer (handel, fest, skörd, brigadanfall, händelsekort)
/// sköts av spelarna själva utifrån [ruleText], precis som byggkostnader
/// visas men inte dras av automatiskt.
enum EventDieFace {
  brigandAttack,
  trade,
  celebration,
  plentifulHarvest,
  eventCard;

  /// De sex sidorna i ordning – vilket index som hör till vilken sida
  /// spelar ingen roll (tärningen visar bara symbolen, inga prickar),
  /// bara att [eventCard] finns med två gånger.
  static const List<EventDieFace> _sixSides = [
    brigandAttack,
    trade,
    celebration,
    plentifulHarvest,
    eventCard,
    eventCard,
  ];

  /// [rollIndex] – 0–5 (t.ex. `Random().nextInt(6)`).
  static EventDieFace fromRoll(int rollIndex) => _sixSides[rollIndex];

  String get swedishName => switch (this) {
        EventDieFace.brigandAttack => 'Brigadanfall',
        EventDieFace.trade => 'Handel',
        EventDieFace.celebration => 'Fest',
        EventDieFace.plentifulHarvest => 'Riklig skörd',
        EventDieFace.eventCard => 'Händelsekort',
      };

  /// Regeltexten ordagrant från referenskortet, på engelska precis som
  /// kortens egen `effectText` (se [GameCard]) – appen visar bara
  /// texten, spelarna genomför den själva.
  String get ruleText => switch (this) {
        EventDieFace.brigandAttack =>
          'A player who has more than 7 resources loses all their gold and wool supplies.',
        EventDieFace.trade =>
          'If one of the players has the trade advantage, they receive 1 resource of their choice from their opponent.',
        EventDieFace.celebration =>
          'If one of the players has the most skill points, they alone receive 1 resource of their choice. Otherwise, each player receives 1 resource of their choice.',
        EventDieFace.plentifulHarvest =>
          'Each player receives 1 resource of their choice.',
        EventDieFace.eventCard =>
          'The player who rolled the dice draws the topmost event card and reads the event aloud. All players affected by the event resolve the event (it can be none, one, or both players).',
      };

  /// Om det här utfallet ska hanteras INNAN spelarna tar sina vanliga
  /// tärningsresurser – enda undantaget är brigadanfallet, allt annat
  /// hanteras EFTER (se referenskortet).
  bool get resolveBeforeResources => this == EventDieFace.brigandAttack;
}
