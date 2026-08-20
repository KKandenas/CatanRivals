import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'ui/screens/lobby_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Om Firebase inte går att nå (t.ex. ingen nätverksåtkomst) ska appen
    // ändå starta – "spela lokalt" fungerar utan nätverk, och
    // skapa/gå med-rum-knapparna visar då bara ett felmeddelande.
    debugPrint('Firebase.initializeApp misslyckades: $e');
  }
  runApp(const ProviderScope(child: CatanRivalsApp()));
}

class CatanRivalsApp extends StatelessWidget {
  const CatanRivalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catan Duellen',
      theme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true),
      home: const LobbyScreen(),
    );
  }
}
