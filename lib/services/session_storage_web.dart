import 'dart:convert';

import 'package:web/web.dart' as web;

/// Webbimplementationen (se session_storage.dart): en enda nyckel i
/// `window.localStorage` med ett litet JSON-kuvert.
///
/// `{"kind": "local", "snapshot": {...}}` – helt lokalt spel (inget
/// rum), se [GameNotifier.buildLocalSnapshotJson]/`resumeLocalSnapshot`.
///
/// `{"kind": "online", "mode": "host"|"guest", "roomCode": "...",
/// "myName": "..."}` – anslutet till ett Firebase-rum. Bara det som
/// krävs för att återansluta sparas (inget spelinnehåll) – resten hämtas
/// på nytt från Firebase vid återanslutning (se
/// [GameNotifier.resumeRoom]), eftersom den datan redan finns synkad
/// där och kan ha ändrats av motståndaren under tiden.
class SessionStorage {
  SessionStorage._();

  static const _key = 'catan_rivals_session';

  static Map<String, dynamic>? read() {
    final raw = web.window.localStorage.getItem(_key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      // Korrupt/inkompatibel (t.ex. från en äldre appversion) – bättre
      // att börja om på startskärmen än att krascha vid varje laddning.
      web.window.localStorage.removeItem(_key);
      return null;
    }
  }

  static void saveOnlineSession({
    required String mode,
    required String roomCode,
    required String myName,
  }) {
    web.window.localStorage.setItem(
      _key,
      jsonEncode({
        'kind': 'online',
        'mode': mode,
        'roomCode': roomCode,
        'myName': myName,
      }),
    );
  }

  static void saveLocalSnapshot(Map<String, dynamic> snapshot) {
    web.window.localStorage.setItem(
        _key, jsonEncode({'kind': 'local', 'snapshot': snapshot}));
  }

  static void clear() {
    web.window.localStorage.removeItem(_key);
  }
}
