import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'ui/screens/lobby_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // .timeout() är kritiskt här: om Firebase-webb-SDK:t (som laddas
    // dynamiskt från gstatic.com) hänger sig – t.ex. vid ett
    // nätverksavbrott mitt i inläsningen – löser den underliggande
    // JS-promisen sig aldrig, och utan timeout skulle await:en aldrig
    // returnera. Då skulle runApp() nedan aldrig köras och sidan
    // fastna helt blank/oresponsiv, utan att vårt catch-block ens
    // hinner köras.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    // Om Firebase inte går att nå ska appen ändå starta – "spela
    // lokalt" fungerar utan nätverk, och skapa/gå med-rum-knapparna
    // visar då bara ett felmeddelande.
    debugPrint('Firebase.initializeApp misslyckades eller tog för lång tid: $e');
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
