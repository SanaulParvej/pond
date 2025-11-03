import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../widgets/logo_widget.dart';

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
              // use shared LogoWidget (white circle with colored icon)
              // splash uses a white circular logo with the primary-colored pool icon
              LogoWidget(size: 92, circleColor: Colors.white, iconColor: primary, elevated: true),
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
