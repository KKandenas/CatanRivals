import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';

/// Litet val av vilken av de fyra (eller fler, se [stackCount]) drag-
/// högarna ett kort ska läggas underst i – delas av Upplopps/attack-
/// kortens enhetsborttagning, Fejds bygg-borttagning och Brödrafejds
/// handkortsval (se [GameNotifier.resolveRiotsUnitRemoval]/
/// [resolveAttackCardUnitRemoval]/[resolveFeudBuildingRemoval]/
/// [pickFraternalFeudsCard]), som alla slutar med precis det valet
/// efter att själva kortet redan är utpekat. Varje ruta visar samma
/// kortbaksida som draghögen faktiskt har i spelet (se
/// [CenterStacksStrip._backAssetFor]) – annars ser det ut som att ALLA
/// högar hör till grundspelet, även temasetets egna (rapporterad bugg:
/// alla kort ska kunna läggas tillbaka till rätt hög beroende på
/// baksida – samma bugg dök upp igen i Duel of the Princes-läget, se
/// [_backAssetFor]s 6-högsfall, eftersom den bara var fixad i
/// [CenterStacksStrip], inte här).
class StackChoiceOverlay extends StatelessWidget {
  final String title;

  /// Hur många draghögar som ska visas att välja mellan – 4 utan tema,
  /// 5 med ett tema aktivt (se [GameState.initialDrawStackSizes].length).
  final int stackCount;

  /// Vilket tema som är aktivt (se [GameState.activeExpansions]) –
  /// avgör vilken kortbaksbild de två sista rutorna visar när
  /// [stackCount] är 5 (Gulderan/Oroligheternas tid har olika
  /// baksidor). Bara ETT tema är någonsin aktivt åt gången (se
  /// [LobbyScreen]).
  final Set<ExpansionSet> activeExpansions;

  final void Function(int stackIndex) onChooseStack;
  final VoidCallback? onCancel;

  const StackChoiceOverlay({
    super.key,
    required this.title,
    this.stackCount = 4,
    this.activeExpansions = const {},
    required this.onChooseStack,
    this.onCancel,
  });

  /// Samma indelning som [GameNotifier._isThemeStackIndex]: de två sista
  /// rutorna (bara när [stackCount] är 5) hör till temasetets egna hög –
  /// eller, i Duel of the Princes-läget ([stackCount] 6, se
  /// [DuelOfThePrincesSetup]-klassdoc), de tre sista (index 3/4/5), en
  /// per temaset.
  bool _isThemeStack(int index) {
    if (stackCount == 6) return index >= 3;
    return stackCount == 5 && index >= stackCount - 2;
  }

  String _backAssetFor(int index) {
    if (!_isThemeStack(index)) return CatanAssets.backBasicSet;
    if (stackCount == 6) {
      // Duel of the Princes: fast ordning Gulderan/Oroligheternas tid/
      // Utvecklingens tid (index 3/4/5, se DuelOfThePrincesSetup-doc).
      if (index == 3) return CatanAssets.backEraGold;
      if (index == 4) return CatanAssets.backEraTurmoil;
      return CatanAssets.backEraProgress;
    }
    if (activeExpansions.contains(ExpansionSet.eraOfTurmoil)) {
      return CatanAssets.backEraTurmoil;
    }
    if (activeExpansions.contains(ExpansionSet.eraOfProgress)) {
      return CatanAssets.backEraProgress;
    }
    return CatanAssets.backEraGold;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: CatanColors.parchment,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CatanColors.ink),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < stackCount; i++)
                      GestureDetector(
                        onTap: () => onChooseStack(i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: stackCount > 4 ? 48 : 56,
                            height: stackCount > 4 ? 48 : 56,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(_backAssetFor(i),
                                    fit: BoxFit.cover),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFF7CBF6A),
                                        width: 1.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (onCancel != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: CatanColors.ink,
                        side: const BorderSide(color: CatanColors.woodFrame)),
                    onPressed: onCancel,
                    child: const Text('Avbryt'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
