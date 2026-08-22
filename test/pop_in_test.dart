import 'package:catan_rivals/ui/widgets/pop_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar in-toningen/glid-upp-animationen som spelas när en [PopIn]
/// först läggs till i trädet (se hand_dock.dart, där nya handkort
/// nyckelas på kortets id) – helt osynlig (opacitet 0) precis vid
/// tillägget, fullt synlig efter att animationen hunnit köra klart.
///
/// Finder scopas till just PopIns egen FadeTransition (inte bara
/// `find.byType(FadeTransition)`) – MaterialApp/Scaffold använder
/// egna FadeTransition-widgetar internt, så en oscopad sökning matchar
/// fler än en och `tester.widget()` kastar "Too many elements".
Finder _popInFade() => find.descendant(
    of: find.byType(PopIn), matching: find.byType(FadeTransition));

void main() {
  testWidgets(
      'är genomskinlig precis när den läggs till, synlig efter att animationen körts klart',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PopIn(child: Text('Kort'))),
    ));

    final opacityAtStart =
        tester.widget<FadeTransition>(_popInFade()).opacity.value;
    expect(opacityAtStart, 0);

    await tester.pumpAndSettle();

    final opacityAtEnd =
        tester.widget<FadeTransition>(_popInFade()).opacity.value;
    expect(opacityAtEnd, 1);
    expect(find.text('Kort'), findsOneWidget);
  });

  testWidgets(
      'samma key (samma kort) spelar inte om animationen vid en vanlig ombyggnad',
      (tester) async {
    Future<void> pump(String text) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: PopIn(key: const ValueKey('c1'), child: Text(text))),
        ));

    await pump('Kort A');
    await tester.pumpAndSettle();
    expect(tester.widget<FadeTransition>(_popInFade()).opacity.value, 1);

    // Samma key, bara annan text (t.ex. samma kort men uppdaterad
    // vy-data) – ska INTE starta om från genomskinligt.
    await pump('Kort A (uppdaterad)');
    await tester.pump();

    expect(tester.widget<FadeTransition>(_popInFade()).opacity.value, 1);
  });

  testWidgets('ny key (nytt kort) spelar upp animationen på nytt',
      (tester) async {
    Future<void> pumpWithKey(String key) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: PopIn(key: ValueKey(key), child: const Text('Kort'))),
        ));

    await pumpWithKey('c1');
    await tester.pumpAndSettle();

    await pumpWithKey('c2');
    final opacityForNewCard =
        tester.widget<FadeTransition>(_popInFade()).opacity.value;

    expect(opacityForNewCard, 0);
  });
}
