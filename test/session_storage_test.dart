import 'package:catan_rivals/services/session_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testar [SessionStorage]s spara/läs/rensa-kontrakt – på Dart-VM:n
/// (flutter test) är det här den in-minnes-stubben (se
/// session_storage_stub.dart), men samma kontrakt gäller den riktiga
/// `localStorage`-varianten på webben (session_storage_web.dart), som
/// inte går att testköra utanför en webbläsare.
void main() {
  tearDown(SessionStorage.clear);

  test('null innan något sparats', () {
    expect(SessionStorage.read(), isNull);
  });

  test('saveOnlineSession sparas och läses tillbaka', () {
    SessionStorage.saveOnlineSession(
        mode: 'host', roomCode: 'ABCD', myName: 'Astrid');

    final session = SessionStorage.read();
    expect(session, {
      'kind': 'online',
      'mode': 'host',
      'roomCode': 'ABCD',
      'myName': 'Astrid',
    });
  });

  test('saveLocalSnapshot sparas och läses tillbaka', () {
    SessionStorage.saveLocalSnapshot({'foo': 'bar'});

    final session = SessionStorage.read();
    expect(session, {
      'kind': 'local',
      'snapshot': {'foo': 'bar'},
    });
  });

  test('clear rensar', () {
    SessionStorage.saveOnlineSession(
        mode: 'guest', roomCode: 'ABCD', myName: 'Björn');
    SessionStorage.clear();

    expect(SessionStorage.read(), isNull);
  });

  test('en ny saveXxx skriver över en tidigare sparad session', () {
    SessionStorage.saveOnlineSession(
        mode: 'host', roomCode: 'ABCD', myName: 'Astrid');
    SessionStorage.saveLocalSnapshot({'foo': 'bar'});

    expect(SessionStorage.read()!['kind'], 'local');
  });
}
