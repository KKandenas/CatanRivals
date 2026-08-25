import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/firebase_bootstrap.dart';
import 'services/session_storage.dart';
import 'state/game_notifier.dart';
import 'state/game_state.dart';
import 'ui/screens/lobby_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Startas i bakgrunden UTAN att vänta in den (se
  // firebase_bootstrap.dart-doc) – runApp() nedan ska köras direkt så
  // att t.ex. "spela lokalt" alltid går att nå omedelbart, i stället
  // för att hela appen hänger blank tills det ofta trögladdade
  // Firebase-webb-SDK:t svarar.
  unawaited(ensureFirebaseInitialized());
  runApp(const ProviderScope(child: CatanRivalsApp()));
}

class CatanRivalsApp extends ConsumerWidget {
  const CatanRivalsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sparar undan "vilket spel pågår" varje gång det ändras, så att en
    // sidladdning kan återuppta samma match i stället för att kasta ut
    // spelaren på startskärmen (se lobby_screen.dart, som läser tillbaka
    // den vid start). Ligger här (appens rot), INTE inuti GameNotifier
    // själv, så att testfiler som bara skapar en bar ProviderContainer
    // (utan den här widgeten) aldrig rör webbläsarens lagring – se
    // SessionStorage för varför det ändå är säkert även om de gjorde
    // det (no-op-stubb på Dart-VM:n).
    ref.listen<GameState>(gameProvider, (previous, next) {
      if (next.mode == SessionMode.local) {
        SessionStorage.saveLocalSnapshot(
            ref.read(gameProvider.notifier).buildLocalSnapshotJson());
      } else if (next.roomCode != null) {
        SessionStorage.saveOnlineSession(
          mode: next.mode.name,
          roomCode: next.roomCode!,
          myName: next.you.name,
        );
      }
    });

    return MaterialApp(
      title: 'Catan Duellen',
      theme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true),
      home: const LobbyScreen(),
    );
  }
}
