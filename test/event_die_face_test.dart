import 'package:catan_rivals/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventDieFace', () {
    test('sex sidor, där eventCard ("?") finns med två gånger', () {
      final sides = List.generate(6, EventDieFace.fromRoll);
      final eventCardCount =
          sides.where((f) => f == EventDieFace.eventCard).length;
      expect(eventCardCount, 2);

      final unique = sides.toSet();
      expect(unique, EventDieFace.values.toSet(),
          reason: 'alla fem symboler ska finnas med minst en gång');
    });

    test('bara brigadanfallet hanteras innan resurserna tas', () {
      for (final face in EventDieFace.values) {
        expect(face.resolveBeforeResources, face == EventDieFace.brigandAttack);
      }
    });

    test('varje sida har ett svenskt namn och en regeltext', () {
      for (final face in EventDieFace.values) {
        expect(face.swedishName, isNotEmpty);
        expect(face.ruleText, isNotEmpty);
      }
    });
  });
}
