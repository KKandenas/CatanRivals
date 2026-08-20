import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_game_sync_service.dart';
import 'game_sync_service.dart';

/// Vilken [GameSyncService] spelet faktiskt pratar med. Standard är den
/// riktiga Firebase-implementationen; tester skriver över den här
/// providern med en fejkad in-memory-tjänst (se
/// test/support/fake_game_sync_service.dart) för att slippa nätverk.
final gameSyncServiceProvider = Provider<GameSyncService>((ref) => FirebaseGameSyncService());
