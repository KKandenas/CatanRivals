import 'package:catan_rivals/ui/widgets/center_stacks_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar den nya visuella feedbacken för att motståndaren ska se
/// vilka handlingar man gör (regelhäftet ger ingen digital motsvarighet,
/// se designdiskussionen i game_board_screen.dart): draghögarna
/// blinkar till i olika färger beroende på om antalet kort i högen
/// ökade (släng, rött) eller minskade (dra, grönt), och en gyllene
/// etikett visas när motståndaren kikar i en hög (se
/// [CenterStacksStrip.peekingStackIndex]) – bara VILKEN hög, aldrig
/// vilka kort.
void main() {
  const baseCounts = {
    'roads': 5,
    'settlements': 3,
    'cities': 2,
    'regions': 8,
    'draw1': 5,
    'draw2': 5,
    'draw3': 5,
    'draw4': 5,
    'event': 9,
  };

  Widget buildStrip({
    required Map<String, int> stackCounts,
    int? peekingStackIndex,
    bool isYourTurn = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CenterStacksStrip(
          stackCounts: stackCounts,
          diceRolled: true,
          isYourTurn: isYourTurn,
          peekingStackIndex: peekingStackIndex,
        ),
      ),
    );
  }

  // Bara flash-overlayens egen DecoratedBox (rambredd 3) räknas – de
  // dragbara högarna (väg/by/stad) har redan en egen, STÅENDE grön ram
  // (rambredd 2, se _StackPileState.build) så länge de går att dra, och
  // den ska inte förväxlas med den kortvariga släng-/dra-blinkningen.
  bool hasFlashBorderColor(WidgetTester tester, Color color) {
    return tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).any((w) {
      final decoration = w.decoration;
      if (decoration is! BoxDecoration) return false;
      final border = decoration.border;
      if (border is! Border) return false;
      return border.top.color == color && border.top.width == 3;
    });
  }

  testWidgets('en hög vars antal ökar (släng) blinkar rött', (tester) async {
    await tester.pumpWidget(buildStrip(stackCounts: baseCounts));
    await tester.pump();
    expect(hasFlashBorderColor(tester, Colors.redAccent), isFalse);

    final increased = Map<String, int>.from(baseCounts)..['draw1'] = 6;
    await tester.pumpWidget(buildStrip(stackCounts: increased));
    // Halvvägs in i intoningsfasen (12% av 1400ms ≈ 168ms) – synlig men
    // inte klar.
    await tester.pump(const Duration(milliseconds: 100));

    expect(hasFlashBorderColor(tester, Colors.redAccent), isTrue);
    expect(hasFlashBorderColor(tester, const Color(0xFF7CBF6A)), isFalse);
  });

  testWidgets('en hög vars antal minskar (dra) blinkar grönt', (tester) async {
    await tester.pumpWidget(buildStrip(stackCounts: baseCounts));
    await tester.pump();

    final decreased = Map<String, int>.from(baseCounts)..['draw2'] = 4;
    await tester.pumpWidget(buildStrip(stackCounts: decreased));
    await tester.pump(const Duration(milliseconds: 100));

    expect(hasFlashBorderColor(tester, const Color(0xFF7CBF6A)), isTrue);
    expect(hasFlashBorderColor(tester, Colors.redAccent), isFalse);
  });

  testWidgets(
      'peekingStackIndex visar en etikett med rätt högnummer (1-indexerat) och ingen etikett när null',
      (tester) async {
    await tester.pumpWidget(buildStrip(stackCounts: baseCounts));
    await tester.pump();
    expect(find.textContaining('Kikar i hög'), findsNothing);

    await tester.pumpWidget(
        buildStrip(stackCounts: baseCounts, peekingStackIndex: 2));
    await tester.pump();

    expect(find.text('Kikar i hög 3'), findsOneWidget);
  });

  testWidgets('peekingStackIndex syns inte när det är din egen tur (du kikar redan i overlay)',
      (tester) async {
    await tester.pumpWidget(buildStrip(
        stackCounts: baseCounts, peekingStackIndex: 1, isYourTurn: true));
    await tester.pump();

    expect(find.textContaining('Kikar i hög'), findsNothing);
  });
}
