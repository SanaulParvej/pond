import 'package:flutter/material.dart';

/// Reusable app logo widget. Attempts to load `assets/logo.png` and falls
/// back to the pool icon if the asset can't be loaded. Uses Image.errorBuilder
/// to avoid bubbling asset load errors to the framework.
class LogoWidget extends StatelessWidget {
  final double size;
  final Color? circleColor;
  final Color? iconColor;
  final bool elevated;

  const LogoWidget({
    super.key,
    this.size = 56,
    this.circleColor,
    this.iconColor,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = this.size;
    final cColor = circleColor ?? Theme.of(context).colorScheme.secondary;
    final iColor = iconColor ?? Colors.white;
    final shadow = elevated
        ? [
            BoxShadow(
              color: Colors.black.withAlpha((0.12 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ]
        : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cColor,
        shape: BoxShape.circle,
        boxShadow: shadow,
      ),
      // Render an in-app vector icon (not the provided image). The user requested
      // that the uploaded image be used only as the app/launcher icon, so the
      // in-app branding uses a simple Material icon which scales cleanly.
      child: Center(
        child: Icon(Icons.pool, size: size * 0.6, color: iColor),
      ),
    );
  }
}
