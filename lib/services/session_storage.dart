/// Sparar/läser undan "vilket spel pågår" i webbläsarens lokala lagring
/// (`localStorage`), så att en sidladdning (F5, iPad-Safari som byter
/// flik och laddar om) kan återuppta exakt samma match i stället för
/// att kasta ut spelaren på startskärmen (se [GameNotifier.resumeRoom]/
/// [GameNotifier.resumeLocalSnapshot], anropat från lobby_screen.dart).
///
/// Bara EN sparad session åt gången (senaste vinner) – appen stödjer
/// bara en pågående match per flik/enhet ändå.
///
/// Webbimplementationen (`dart:html`s `window.localStorage`) väljs bara
/// vid webbkompilering (`dart.library.html`) – vid `flutter test` (som
/// kör på Dart-VM:n, inte i en webbläsare) används i stället en no-op-
/// stubb, så att importen inte kräver `dart:html` (som inte finns på
/// VM:n) i alla testfiler som (indirekt, via GameNotifier) importerar
/// den här filen.
library;

export 'session_storage_stub.dart'
    if (dart.library.html) 'session_storage_web.dart';
