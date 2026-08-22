/// Icke-webbvarianten av [SessionStorage] (bara `flutter test`, som kör
/// på Dart-VM:n, i den här appen – se session_storage.dart för varför
/// den här varianten väljs där): en enkel in-minnes-variant i stället
/// för webbläsarens `localStorage`. Låter testerna faktiskt öva på hela
/// spara/läs-flödet (t.ex. lobby_screen_test.dart, som annars aldrig
/// skulle träffa [GameNotifier.resumeLocalSnapshot]-grenen) utan att dra
/// in `dart:html`. Delat statiskt tillstånd inom EN körning av
/// testfilen – testfiler som skriver hit bör rensa med [clear] i en
/// `tearDown` så att de inte påverkar efterföljande tester.
class SessionStorage {
  SessionStorage._();

  static Map<String, dynamic>? _stored;

  static Map<String, dynamic>? read() => _stored;

  static void saveOnlineSession({
    required String mode,
    required String roomCode,
    required String myName,
  }) {
    _stored = {
      'kind': 'online',
      'mode': mode,
      'roomCode': roomCode,
      'myName': myName,
    };
  }

  static void saveLocalSnapshot(Map<String, dynamic> snapshot) {
    _stored = {'kind': 'local', 'snapshot': snapshot};
  }

  static void clear() {
    _stored = null;
  }
}
