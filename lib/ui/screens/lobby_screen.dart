import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../services/firebase_bootstrap.dart';
import '../../services/session_storage.dart';
import '../../state/game_notifier.dart';
import '../theme/catan_assets.dart';
import '../theme/catan_colors.dart';
import '../widgets/rules_button.dart';
import 'game_board_screen.dart';
import 'rules_screen.dart';

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

  /// Vilket ENSKILT tema som ska vara aktivt i nästa match (se
  /// [GameState.activeExpansions]) – `null` betyder inget tema. Bara ETT
  /// tema åt gången går att välja här (ömsesidigt uteslutande med
  /// [_allExpansions], se dess doc) – därför ett enda nullbart fält i
  /// stället för flera kryssrutor. Bara relevant för "Skapa nytt rum"/
  /// "Spela lokalt" – den som går med i ett befintligt rum ärver hostens
  /// val i stället.
  ExpansionSet? _selectedTheme;

  /// "Duel of the Princes": alla tre temaseten SAMTIDIGT (se
  /// [DuelOfThePrincesSetup]-klassdoc) – ett eget, femte alternativ i
  /// temavals-raden, ömsesidigt uteslutande med [_selectedTheme] (ett
  /// tryck på endera rutgruppen nollställer den andra, se
  /// [_themeOption]s `onSelect`).
  bool _allExpansions = false;

  Set<ExpansionSet> get _selectedExpansions => _allExpansions
      ? {ExpansionSet.eraOfGold, ExpansionSet.eraOfTurmoil, ExpansionSet.eraOfProgress}
      : (_selectedTheme == null ? {} : {_selectedTheme!});

  /// Om appen just nu kollar efter en sparad, pågående match att
  /// återuppta (se [SessionStorage]) – sant tills kollen är klar, så att
  /// lobbyformuläret inte hinner blinka till innan en lyckad
  /// återanslutning navigerar vidare.
  bool _resuming = true;

  @override
  void initState() {
    super.initState();
    // Väntar in att widgetträdet är helt klarbyggt innan providern rörs
    // vid – Riverpod tillåter inte att ett providertillstånd ändras
    // medan trädet fortfarande byggs (skulle annars kasta "Tried to
    // modify a provider while the widget tree was building" så fort en
    // sparad match finns, eftersom [resumeLocalSnapshot] muterar
    // `state` helt synkront utan ett await innan, till skillnad från
    // [resumeRoom] som redan är säker tack vare sina egna
    // nätverksanrop). En vanlig `Future.delayed(Duration.zero)` visade
    // sig INTE räcka (fortfarande inom samma "bygger fortfarande"-
    // fönster) – `addPostFrameCallback` är det Flutter-idiomatiska,
    // garanterat säkra sättet att vänta tills det första bygget (layout
    // + paint) faktiskt är klart.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryResumeSession());
  }

  /// Körs en gång vid start: om en tidigare match finns sparad (senast
  /// en sidladdning avbröt den, se main.dart:s lyssnare) återupptas den
  /// direkt i stället för att visa lobbyformuläret – annars fortsätter
  /// [_resuming] till `false` och den vanliga lobbyn visas som vanligt.
  Future<void> _tryResumeSession() async {
    final session = SessionStorage.read();
    if (session == null) {
      if (mounted) setState(() => _resuming = false);
      return;
    }

    final notifier = ref.read(gameProvider.notifier);
    if (session['kind'] == 'local') {
      final snapshot = session['snapshot'];
      if (snapshot is Map) {
        notifier.resumeLocalSnapshot(Map<String, dynamic>.from(snapshot));
        if (mounted) _goToBoard();
        return;
      }
    } else if (session['kind'] == 'online') {
      // main.dart startar Firebase i bakgrunden utan att vänta in den
      // (se firebase_bootstrap.dart-doc) – just den här återanslutningen
      // sker automatiskt vid kallstart, ofta INNAN webb-SDK:t hunnit bli
      // klart, så den måste vänta in det uttryckligen innan resumeRoom
      // rör Firebase (annars kastar FirebaseDatabase.instance direkt).
      await ensureFirebaseInitialized();
      final error = await notifier.resumeRoom(
        session['roomCode'] as String,
        session['mode'] as String,
        session['myName'] as String,
      );
      if (error == null) {
        if (mounted) _goToBoard();
        return;
      }
      SessionStorage.clear();
      if (mounted) {
        setState(() {
          _error = 'Kunde inte återansluta till din förra match: $error';
        });
      }
    }
    if (mounted) setState(() => _resuming = false);
  }

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
      await ref
          .read(gameProvider.notifier)
          .hostRoom(_nameController.text.trim(), expansions: _selectedExpansions);
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
    ref.read(gameProvider.notifier).playLocally(expansions: _selectedExpansions);
    _goToBoard();
  }

  void _goToBoard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameBoardScreen()),
    );
  }

  /// En tryckbar temaruta i temavals-raden (se [_selectedTheme]/
  /// [_allExpansions]) – visar samma kortbaksbild som draghögarna
  /// faktiskt använder i spelet för de fyra vanliga rutorna (se
  /// [CatanAssets.backBasicSet]/[backEraGold]/[backEraTurmoil]/
  /// [backEraProgress]/[CenterStacksStrip]), och en egen omslagsbild för
  /// "Duel of the Princes"-rutan (se [CatanAssets.coverAllExpansions] –
  /// den har ingen EGEN kortbaksbild i spelet, se dess doc). Ingen egen
  /// text ovanpå eftersom bilderna redan har temanamnet inbakat. Den
  /// valda rutan får en tjockare träfärgad ram (samma träfärg som
  /// resten av lobbyns ram, se [CatanColors.woodFrame]) och full
  /// ljusstyrka; de andra dämpas lite för att tydligt sticka ut mot den
  /// valda.
  Widget _themeOption({
    required bool selected,
    required VoidCallback onSelect,
    required String backgroundImage,
    required Key optionKey,
  }) {
    return Expanded(
      child: GestureDetector(
        key: optionKey,
        onTap: _busy ? null : onSelect,
        child: Container(
          height: 96,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: AssetImage(backgroundImage),
              fit: BoxFit.cover,
              colorFilter: selected
                  ? null
                  : ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.35), BlendMode.darken),
            ),
            border: Border.all(
              color: selected ? CatanColors.woodFrame : Colors.black26,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_resuming) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(CatanAssets.lobbyBackground, fit: BoxFit.cover),
          // Mörk slöja över bakgrunden så vit text/knappar syns tydligt
          // ovanpå bilden, oavsett hur ljus den är där de hamnar.
          Container(color: Colors.black.withValues(alpha: 0.35)),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: RulesButton(onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RulesScreen()))),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CatanColors.parchment.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CatanColors.woodFrame, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
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
                        const SizedBox(height: 12),
                        // Gäller "Skapa nytt rum" och "Spela lokalt" – den
                        // som går med i ett befintligt rum ärver i stället
                        // hostens val (se GameState.activeExpansions).
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Tema',
                              style: Theme.of(context).textTheme.labelLarge),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _themeOption(
                              optionKey: const ValueKey('theme-option-none'),
                              selected: !_allExpansions && _selectedTheme == null,
                              onSelect: () => setState(() {
                                _selectedTheme = null;
                                _allExpansions = false;
                              }),
                              backgroundImage: CatanAssets.backBasicSet,
                            ),
                            _themeOption(
                              optionKey: const ValueKey('theme-option-gold'),
                              selected: !_allExpansions &&
                                  _selectedTheme == ExpansionSet.eraOfGold,
                              onSelect: () => setState(() {
                                _selectedTheme = ExpansionSet.eraOfGold;
                                _allExpansions = false;
                              }),
                              backgroundImage: CatanAssets.backEraGold,
                            ),
                            _themeOption(
                              optionKey:
                                  const ValueKey('theme-option-turmoil'),
                              selected: !_allExpansions &&
                                  _selectedTheme == ExpansionSet.eraOfTurmoil,
                              onSelect: () => setState(() {
                                _selectedTheme = ExpansionSet.eraOfTurmoil;
                                _allExpansions = false;
                              }),
                              backgroundImage: CatanAssets.backEraTurmoil,
                            ),
                            _themeOption(
                              optionKey:
                                  const ValueKey('theme-option-progress'),
                              selected: !_allExpansions &&
                                  _selectedTheme == ExpansionSet.eraOfProgress,
                              onSelect: () => setState(() {
                                _selectedTheme = ExpansionSet.eraOfProgress;
                                _allExpansions = false;
                              }),
                              backgroundImage: CatanAssets.backEraProgress,
                            ),
                            _themeOption(
                              optionKey: const ValueKey('theme-option-all'),
                              selected: _allExpansions,
                              onSelect: () => setState(() {
                                _allExpansions = true;
                                _selectedTheme = null;
                              }),
                              backgroundImage: CatanAssets.coverAllExpansions,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
          ),
        ],
      ),
    );
  }
}
