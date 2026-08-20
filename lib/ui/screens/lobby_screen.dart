import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_notifier.dart';
import 'game_board_screen.dart';

/// Startskärmen: skapa ett rum, gå med i ett rum via kod, eller spela
/// lokalt på samma iPad (ingen synk). Visas innan [GameBoardScreen].
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _nameController = TextEditingController(text: 'Spelare');
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _hostRoom() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(gameProvider.notifier).hostRoom(_nameController.text.trim());
      if (mounted) _goToBoard();
    } catch (e) {
      setState(() => _error = 'Kunde inte skapa rum: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Ange en rumskod');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final error = await ref.read(gameProvider.notifier).joinRoom(code, _nameController.text.trim());
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      if (mounted) _goToBoard();
    } catch (e) {
      setState(() => _error = 'Kunde inte gå med i rummet: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _playLocally() {
    ref.read(gameProvider.notifier).playLocally();
    _goToBoard();
  }

  void _goToBoard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameBoardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Catan Duellen', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Ditt namn', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _hostRoom,
                    child: const Text('Skapa nytt rum'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'Rumskod', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: _busy ? null : _joinRoom,
                        child: const Text('Gå med'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _busy ? null : _playLocally,
                    child: const Text('Spela lokalt (utan synk)'),
                  ),
                  if (_busy) const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  if (_error != null) Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
