import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Startar Firebase-webb-SDK:t (laddas dynamiskt från gstatic.com) i
/// bakgrunden, UTAN att blockera [runApp] i main.dart – annars visas
/// ingenting alls, inte ens lobbyns "spela lokalt"-knapp, förrän det
/// ofta trögladdade SDK:t svarar. Extra märkbart för en hemskärmssparad
/// PWA, som ofta kallstartar på skakigt nätverk (precis efter att ha
/// väckts från bakgrunden) – utan den här bakgrunds-starten hängde HELA
/// appen med en blank/svart skärm i värsta fall åtta sekunder innan
/// något överhuvudtaget ritades upp.
///
/// Futuren cachas (kallas bara en gång) så att flera anropare kan vänta
/// in samma pågående initiering. `.timeout()` är kritiskt: om SDK:t
/// hänger sig (t.ex. ett nätverksavbrott mitt i inläsningen) löser den
/// underliggande JS-promisen sig aldrig, och utan timeout skulle den
/// här Futuren aldrig returnera.
///
/// [LobbyScreen]s automatiska återanslutning till en sparad ONLINE-
/// match vid kallstart (se _tryResumeSession) väntar in den här innan
/// den rör Firebase – övriga vägar in (t.ex. "Skapa nytt rum") hinner i
/// praktiken alltid vänta tillräckligt länge naturligt (spelaren skriver
/// sitt namn först).
Future<void>? _initFuture;

Future<void> ensureFirebaseInitialized() {
  return _initFuture ??= _doInitialize();
}

Future<void> _doInitialize() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    // Om Firebase inte går att nå ska appen ändå fungera – "spela
    // lokalt" fungerar utan nätverk, och skapa/gå med-rum-knapparna
    // visar då bara ett felmeddelande.
    debugPrint('Firebase.initializeApp misslyckades eller tog för lång tid: $e');
  }
}
