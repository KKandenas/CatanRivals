import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/game_board_screen.dart';

void main() {
  runApp(const ProviderScope(child: CatanRivalsApp()));
}

class CatanRivalsApp extends StatelessWidget {
  const CatanRivalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catan Duellen',
      theme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true),
      home: const GameBoardScreen(),
    );
  }
}
