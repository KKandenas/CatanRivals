import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/ui/theme/catan_assets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar [CatanAssets.isThemeDrawStack]/[CatanAssets.drawStackBackAsset]
/// direkt – EN delad källa till sanning för "vilken hög hör till vilket
/// tema" som [CenterStacksStrip] och [StackChoiceOverlay] båda numera
/// anropar i stället för att hålla varsin egen privat kopia (se
/// metodernas egen doc för bakgrunden: de två kopiorna glapp isär en
/// gång, se stack_choice_overlay_theme_back_test.dart/
/// center_stacks_strip_theme_back_test.dart för widget-nivå-täckning).
void main() {
  group('CatanAssets.isThemeDrawStack', () {
    test('utan tema (4 högar): ingen hög är en temahög', () {
      for (var i = 0; i < 4; i++) {
        expect(CatanAssets.isThemeDrawStack(i, 4), isFalse);
      }
    });

    test('med ett tema (5 högar): bara de två sista är temahögar', () {
      expect(CatanAssets.isThemeDrawStack(0, 5), isFalse);
      expect(CatanAssets.isThemeDrawStack(1, 5), isFalse);
      expect(CatanAssets.isThemeDrawStack(2, 5), isFalse);
      expect(CatanAssets.isThemeDrawStack(3, 5), isTrue);
      expect(CatanAssets.isThemeDrawStack(4, 5), isTrue);
    });

    test(
        'Duel of the Princes (6 högar): de tre sista är varsin egen temahög',
        () {
      expect(CatanAssets.isThemeDrawStack(0, 6), isFalse);
      expect(CatanAssets.isThemeDrawStack(1, 6), isFalse);
      expect(CatanAssets.isThemeDrawStack(2, 6), isFalse);
      expect(CatanAssets.isThemeDrawStack(3, 6), isTrue);
      expect(CatanAssets.isThemeDrawStack(4, 6), isTrue);
      expect(CatanAssets.isThemeDrawStack(5, 6), isTrue);
    });
  });

  group('CatanAssets.drawStackBackAsset', () {
    test('grundspelets högar visar alltid grundspelets baksida', () {
      expect(CatanAssets.drawStackBackAsset(0, 5, {ExpansionSet.eraOfGold}),
          CatanAssets.backBasicSet);
    });

    test('med Gulderan aktivt visar temahögarna Gulderans baksida', () {
      expect(CatanAssets.drawStackBackAsset(3, 5, {ExpansionSet.eraOfGold}),
          CatanAssets.backEraGold);
    });

    test('med Oroligheternas tid aktivt visar temahögarna dess baksida', () {
      expect(
          CatanAssets.drawStackBackAsset(4, 5, {ExpansionSet.eraOfTurmoil}),
          CatanAssets.backEraTurmoil);
    });

    test('med Utvecklingens tid aktivt visar temahögarna dess baksida', () {
      expect(
          CatanAssets.drawStackBackAsset(3, 5, {ExpansionSet.eraOfProgress}),
          CatanAssets.backEraProgress);
    });

    test(
        'Duel of the Princes: fast ordning Gulderan/Oroligheternas tid/Utvecklingens tid (index 3/4/5), inte allihop grundspelets',
        () {
      const active = {
        ExpansionSet.eraOfGold,
        ExpansionSet.eraOfTurmoil,
        ExpansionSet.eraOfProgress,
      };
      expect(CatanAssets.drawStackBackAsset(0, 6, active),
          CatanAssets.backBasicSet);
      expect(
          CatanAssets.drawStackBackAsset(3, 6, active), CatanAssets.backEraGold);
      expect(CatanAssets.drawStackBackAsset(4, 6, active),
          CatanAssets.backEraTurmoil);
      expect(CatanAssets.drawStackBackAsset(5, 6, active),
          CatanAssets.backEraProgress);
    });
  });
}
