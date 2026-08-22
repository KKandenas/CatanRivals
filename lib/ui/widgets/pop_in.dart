import 'package:flutter/material.dart';

/// Tonar in och glider upp sitt barn en gång, när widgeten FÖRST läggs
/// till i trädet (drivet av `initState`, alltså styrt av `key` – inte
/// av vanliga rebuilds) – ren mikroanimation för kort som precis
/// dragits till handen (se [key: ValueKey(card.id)] i HandDock) så att
/// nya kort känns som att de "landar" i stället för att bara dyka upp.
class PopIn extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PopIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
  });

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
