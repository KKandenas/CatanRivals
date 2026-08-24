import 'package:catan_rivals/data/basic_set_cards.dart';
import 'package:catan_rivals/ui/widgets/build_confirm_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar BuildConfirmCard direkt (inte hela bräd-/drag-flödet, se
/// build_confirm_test.dart för det) – specifikt den nya
/// "Ersätter X"-texten som visas när ett bygge på en redan bebyggd
/// plats faktiskt byter ut ett annat kort (se
/// GameNotifier.dropExpansion/PrincipalityGrid.onRequestBuildConfirm).
void main() {
  Future<void> pumpCard(WidgetTester tester,
      {required replacedCard, VoidCallback? onConfirm, VoidCallback? onCancel}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BuildConfirmCard(
          card: BasicSetCards.storehouse,
          replacedCard: replacedCard,
          onConfirm: onConfirm ?? () {},
          onCancel: onCancel ?? () {},
        ),
      ),
    ));
  }

  testWidgets('utan replacedCard visas ingen "Ersätter"-text', (tester) async {
    await pumpCard(tester, replacedCard: null);

    expect(find.textContaining('Ersätter'), findsNothing);
  });

  testWidgets(
      'med replacedCard visas en varning om att det gamla kortet läggs i slänghögen',
      (tester) async {
    await pumpCard(tester, replacedCard: BasicSetCards.road);

    expect(
        find.text('Ersätter ${BasicSetCards.road.name}, som läggs i slänghögen.'),
        findsOneWidget);
  });
}
