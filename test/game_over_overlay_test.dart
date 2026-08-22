import 'package:catan_rivals/ui/widgets/game_over_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar slutskärmen (se [GameState.winnerId]/game_over_overlay.dart):
/// rätt vinnartext beroende på vem som vann, båda spelarnas
/// slutställning, och att "Ny match" bara visas när
/// [GameOverOverlay.onNewLocalMatch] finns (lokalt läge).
void main() {
  Widget buildOverlay({
    required bool youWon,
    VoidCallback? onNewLocalMatch,
    required VoidCallback onToMainMenu,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            GameOverOverlay(
              youWon: youWon,
              youName: 'Du',
              youPoints: youWon ? 7 : 4,
              opponentName: 'Motståndaren',
              opponentPoints: youWon ? 4 : 7,
              onNewLocalMatch: onNewLocalMatch,
              onToMainMenu: onToMainMenu,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('du vinner: visar "Du vinner!" och båda poängen', (tester) async {
    await tester.pumpWidget(buildOverlay(youWon: true, onToMainMenu: () {}));

    expect(find.text('Du vinner!'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('motståndaren vinner: visar motståndarens namn i rubriken',
      (tester) async {
    await tester.pumpWidget(buildOverlay(youWon: false, onToMainMenu: () {}));

    expect(find.text('Motståndaren vinner!'), findsOneWidget);
    expect(find.text('Du vinner!'), findsNothing);
  });

  testWidgets('onNewLocalMatch null (onlineläge): ingen "Ny match"-knapp',
      (tester) async {
    await tester.pumpWidget(buildOverlay(youWon: true, onToMainMenu: () {}));

    expect(find.text('Ny match'), findsNothing);
    expect(find.text('Till huvudmenyn'), findsOneWidget);
  });

  testWidgets('onNewLocalMatch satt (lokalt läge): knappen syns och anropar callbacken',
      (tester) async {
    var newMatchTapped = false;
    await tester.pumpWidget(buildOverlay(
      youWon: true,
      onNewLocalMatch: () => newMatchTapped = true,
      onToMainMenu: () {},
    ));

    expect(find.text('Ny match'), findsOneWidget);
    await tester.tap(find.text('Ny match'));
    expect(newMatchTapped, isTrue);
  });

  testWidgets('"Till huvudmenyn" anropar sin callback', (tester) async {
    var toMainMenuTapped = false;
    await tester.pumpWidget(
        buildOverlay(youWon: true, onToMainMenu: () => toMainMenuTapped = true));

    await tester.tap(find.text('Till huvudmenyn'));
    expect(toMainMenuTapped, isTrue);
  });
}
