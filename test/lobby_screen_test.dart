import 'package:catan_rivals/models/models.dart';
import 'package:catan_rivals/services/session_storage.dart';
import 'package:catan_rivals/state/game_notifier.dart';
import 'package:catan_rivals/ui/screens/game_board_screen.dart';
import 'package:catan_rivals/ui/screens/lobby_screen.dart';
import 'package:catan_rivals/ui/screens/rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar startskärmens nya regel-knapp ("?" uppe till vänster, se
/// rules_button.dart) och sidladdnings-återupptagningen (se
/// lobby_screen.dart:s [SessionStorage]-koll i initState, som körs via
/// [WidgetsBinding.addPostFrameCallback] – se kommentaren där för en
/// speltestad bugg: en bar `Future.delayed(Duration.zero)` räckte INTE
/// för att undvika Riverpods "Tried to modify a provider while the
/// widget tree was building", bara `addPostFrameCallback` gjorde det).
void main() {
  tearDown(SessionStorage.clear);

  Future<void> pumpLobby(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LobbyScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('visar lobbyformuläret direkt när ingen sparad match finns',
      (tester) async {
    await pumpLobby(tester);

    expect(find.text('Skapa nytt rum'), findsOneWidget);
    expect(find.text('Spela lokalt (utan synk)'), findsOneWidget);
  });

  testWidgets('temarutan för Gulderan skickas med till playLocally',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLobby(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(LobbyScreen)));

    await tester.tap(find.byKey(const ValueKey('theme-option-gold')));
    await tester.pump();
    await tester.tap(find.text('Spela lokalt (utan synk)'));
    await tester.pumpAndSettle();

    expect(container.read(gameProvider).activeExpansions,
        {ExpansionSet.eraOfGold});
    expect(container.read(gameProvider).victoryPointTarget, 12);
  });

  testWidgets('temarutan för Oroligheternas tid skickas med till playLocally',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLobby(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(LobbyScreen)));

    await tester.tap(find.byKey(const ValueKey('theme-option-turmoil')));
    await tester.pump();
    await tester.tap(find.text('Spela lokalt (utan synk)'));
    await tester.pumpAndSettle();

    expect(container.read(gameProvider).activeExpansions,
        {ExpansionSet.eraOfTurmoil});
    expect(container.read(gameProvider).victoryPointTarget, 12);
  });

  testWidgets('temarutan för Utvecklingens tid skickas med till playLocally',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLobby(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(LobbyScreen)));

    await tester.tap(find.byKey(const ValueKey('theme-option-progress')));
    await tester.pump();
    await tester.tap(find.text('Spela lokalt (utan synk)'));
    await tester.pumpAndSettle();

    expect(container.read(gameProvider).activeExpansions,
        {ExpansionSet.eraOfProgress});
    expect(container.read(gameProvider).victoryPointTarget, 12);
  });

  testWidgets(
      'temarutan för Duel of the Princes (alla expansioner) skickar med alla tre till playLocally',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLobby(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(LobbyScreen)));

    await tester.tap(find.byKey(const ValueKey('theme-option-all')));
    await tester.pump();
    await tester.tap(find.text('Spela lokalt (utan synk)'));
    await tester.pumpAndSettle();

    expect(
        container.read(gameProvider).activeExpansions,
        {
          ExpansionSet.eraOfGold,
          ExpansionSet.eraOfTurmoil,
          ExpansionSet.eraOfProgress
        });
    expect(container.read(gameProvider).victoryPointTarget, 13);
  });

  testWidgets(
      'alla expansioner-rutan och ett enskilt tema är ömsesidigt uteslutande, i båda riktningarna',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLobby(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(LobbyScreen)));

    // Gulderan, sedan alla expansioner: bara det senaste valet ska gälla.
    await tester.tap(find.byKey(const ValueKey('theme-option-gold')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('theme-option-all')));
    await tester.pump();
    // ... och tvärtom: alla expansioner, sedan Gulderan igen.
    await tester.tap(find.byKey(const ValueKey('theme-option-gold')));
    await tester.pump();
    await tester.tap(find.text('Spela lokalt (utan synk)'));
    await tester.pumpAndSettle();

    expect(container.read(gameProvider).activeExpansions,
        {ExpansionSet.eraOfGold});
  });

  testWidgets(
      'temarutorna är ömsesidigt uteslutande – väljer man ett nytt tema avmarkeras det förra',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLobby(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(LobbyScreen)));

    await tester.tap(find.byKey(const ValueKey('theme-option-gold')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('theme-option-turmoil')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('theme-option-progress')));
    await tester.pump();
    await tester.tap(find.text('Spela lokalt (utan synk)'));
    await tester.pumpAndSettle();

    expect(container.read(gameProvider).activeExpansions,
        {ExpansionSet.eraOfProgress});
  });

  testWidgets('"?"-knappen öppnar regelsidan', (tester) async {
    await pumpLobby(tester);

    expect(find.byType(RulesScreen), findsNothing);
    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();

    expect(find.byType(RulesScreen), findsOneWidget);
  });

  testWidgets(
      'en sparad lokal match återupptas direkt (utan att krascha mot Riverpods bygg-spärr)',
      (tester) async {
    // Samma yta som GameBoardScreens övriga tester (t.ex.
    // build_confirm_test.dart) – standardytan (800x600) är för liten
    // för hela brädet och ger ett ovidkommande overflow-fel.
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Bygg ett giltigt ögonblick precis som main.dart:s lyssnare skulle
    // ha sparat det, via en helt fristående GameNotifier.
    final scratch = ProviderContainer();
    scratch.read(gameProvider.notifier).playLocally();
    final snapshot = scratch.read(gameProvider.notifier).buildLocalSnapshotJson();
    scratch.dispose();
    SessionStorage.saveLocalSnapshot(snapshot);

    await pumpLobby(tester);

    // Lobbyformuläret ska aldrig hinna synas – man landar direkt på
    // brädet, precis som efter en sidladdning mitt i en match.
    expect(find.text('Skapa nytt rum'), findsNothing);
    expect(find.byType(GameBoardScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
