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

  /// Regeltexten från referenskortet – appen visar bara texten,
  /// spelarna genomför den själva.
  String get ruleText => switch (this) {
        EventDieFace.brigandAttack =>
          'En spelare som har fler än 7 resurser förlorar alla sina lager av guld och ull.',
        EventDieFace.trade =>
          'Om en av spelarna har handelsövertaget får den spelaren 1 valfri resurs från motståndaren.',
        EventDieFace.celebration =>
          'Om en av spelarna har flest kunskapspoäng får bara den spelaren 1 valfri resurs. Annars får båda spelarna 1 valfri resurs var.',
        EventDieFace.plentifulHarvest =>
          'Varje spelare får 1 valfri resurs.',
        EventDieFace.eventCard =>
          'Spelaren som slog tärningen drar det översta händelsekortet och läser upp händelsen högt. Alla spelare som påverkas av händelsen genomför den (det kan gälla ingen, en eller båda spelarna).',
      };

  /// Om det här utfallet ska hanteras INNAN spelarna tar sina vanliga
  /// tärningsresurser – enda undantaget är brigadanfallet, allt annat
  /// hanteras EFTER (se referenskortet).
  bool get resolveBeforeResources => this == EventDieFace.brigandAttack;
}
