import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar den fria regionomflyttningen direkt efter starthands-
/// utdelningen med ett tema aktivt (bekräftad regel: "Fri omflyttning
/// av egna 6 regioner") – se
/// [GameNotifier.selectRegionRearrangementTarget]/
/// [GameNotifier.finishRegionRearrangement]. Samma "första valet
/// lagras, andra valet genomför bytet"-mönster som Omlokaliserings-
/// gruppen i action_cards_test.dart, men aktiverat direkt via state i
/// stället för via ett kort (mekaniken kräver inget).
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  // MockGame.buildYou() (den lokala default-uppställningen som
  // ProviderContainer() startar med) sätter redan
  // hasDrawnStartingHand: true - nollställ den explicit här så att
  // finishRegionRearrangement-testerna nedan kan observera den faktiska
  // övergången, precis som i det riktiga online-flödet.
  void startRearrangement() {
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    notifier.state = state.copyWith(
      you: state.you.copyWith(hasDrawnStartingHand: false),
      startingRegionRearrangementActive: true,
    );
  }

  test('byter plats på 2 egna regioner – resurserna följer med kortet', () {
    startRearrangement();
    final notifier = container.read(gameProvider.notifier);
    final state = container.read(gameProvider);
    // Startuppställningen: Skog (-1, ovanför) och Guldfält (1, ovanför)
    // – se starter_cards.dart.
    state.you.principality.addResourceToRegion(-1, BuildingRow.above, 2);
    final forestCard =
        state.you.principality.regionAt(-1, BuildingRow.above)!.card;
    final goldFieldCard =
        state.you.principality.regionAt(1, BuildingRow.above)!.card;

    expect(
        notifier.selectRegionRearrangementTarget(-1, BuildingRow.above),
        isNull);
    expect(
        container.read(gameProvider).startingRegionRearrangementFirst,
        isNotNull);
    expect(
        notifier.selectRegionRearrangementTarget(1, BuildingRow.above),
        isNull);

    final after = container.read(gameProvider);
    expect(after.startingRegionRearrangementFirst, isNull);
    // Fasen förblir AKTIV – till skillnad från Omlokalisering, som
    // avslutas efter ett enda byte, tillåter regelns "fri omflyttning"
    // godtyckligt många byten tills spelaren själv trycker Klar.
    expect(after.startingRegionRearrangementActive, isTrue);
    expect(after.you.principality.regionAt(-1, BuildingRow.above)!.card.id,
        goldFieldCard.id);
    expect(
        after.you.principality.regionAt(-1, BuildingRow.above)!.storedResources,
        0);
    expect(after.you.principality.regionAt(1, BuildingRow.above)!.card.id,
        forestCard.id);
    expect(
        after.you.principality.regionAt(1, BuildingRow.above)!.storedResources,
        3);
  });

  test('ett tryck till på samma plats avmarkerar valet', () {
    startRearrangement();
    final notifier = container.read(gameProvider.notifier);

    notifier.selectRegionRearrangementTarget(-1, BuildingRow.above);
    expect(
        container.read(gameProvider).startingRegionRearrangementFirst,
        isNotNull);

    final error =
        notifier.selectRegionRearrangementTarget(-1, BuildingRow.above);

    expect(error, isNull);
    expect(container.read(gameProvider).startingRegionRearrangementFirst, isNull);
    expect(container.read(gameProvider).startingRegionRearrangementActive, isTrue);
  });

  test('en tom ruta går inte att välja som första plats', () {
    startRearrangement();
    final notifier = container.read(gameProvider.notifier);

    final error = notifier.selectRegionRearrangementTarget(5, BuildingRow.above);

    expect(error, isNull);
    expect(container.read(gameProvider).startingRegionRearrangementFirst, isNull);
  });

  test('finishRegionRearrangement avslutar fasen och sätter hasDrawnStartingHand',
      () {
    startRearrangement();
    final notifier = container.read(gameProvider.notifier);
    expect(container.read(gameProvider).you.hasDrawnStartingHand, isFalse);

    final error = notifier.finishRegionRearrangement();

    expect(error, isNull);
    final after = container.read(gameProvider);
    expect(after.startingRegionRearrangementActive, isFalse);
    expect(after.startingRegionRearrangementFirst, isNull);
    expect(after.you.hasDrawnStartingHand, isTrue);
  });

  test(
      'finishRegionRearrangement släpper tyst en kvarhängande första-markering',
      () {
    startRearrangement();
    final notifier = container.read(gameProvider.notifier);
    notifier.selectRegionRearrangementTarget(-1, BuildingRow.above);
    expect(
        container.read(gameProvider).startingRegionRearrangementFirst,
        isNotNull);

    final error = notifier.finishRegionRearrangement();

    expect(error, isNull);
    expect(container.read(gameProvider).startingRegionRearrangementFirst, isNull);
  });

  test('no-op när fasen inte är aktiv', () {
    final notifier = container.read(gameProvider.notifier);
    final before = container.read(gameProvider).you.hasDrawnStartingHand;

    expect(
        notifier.selectRegionRearrangementTarget(-1, BuildingRow.above),
        isNull);
    expect(container.read(gameProvider).startingRegionRearrangementFirst, isNull);
    expect(notifier.finishRegionRearrangement(), isNull);
    expect(container.read(gameProvider).you.hasDrawnStartingHand, before,
        reason: 'finishRegionRearrangement ska inte röra flaggan alls '
            'när fasen inte är aktiv');
  });
}
