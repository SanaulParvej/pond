import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';
// Use the pond image directly for the splash logo

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
    // start timer after first frame to ensure Navigator has a valid context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      });
    });
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primary, primary.withAlpha((0.9 * 255).round()), accent.withAlpha((0.9 * 255).round())], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _anim,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Show the chosen pond image inside a white circular badge so
              // the splash matches the pond tiles.
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: ClipOval(
                  child: Image.asset(
                    'assets/bm9c_py8p_191023.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Center(child: Icon(Icons.pool, size: 44, color: primary)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Pond Management', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, shadows: [BoxShadow(color: Colors.black.withAlpha((0.2 * 255).round()), blurRadius: 6)])),
              const SizedBox(height: 8),
              Text('Track feed & medicine usage', style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).round()), fontSize: 14)),
            ]),
          ),
        ),
      ),
    );
  }
}
