import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      home: const Scaffold(
        body: Center(
          child: Text('Catan Duellen – grundstruktur klar. UI byggs i nästa steg.'),
        ),
      ),
    );
  }
}
