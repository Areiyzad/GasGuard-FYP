import 'dart:ui';

import 'package:flutter/material.dart';

class GlassyBackground extends StatelessWidget {
  final Widget child;
  const GlassyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Adaptive layered blue gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [
                      Color(0xFF041025), // darker apex
                      Color(0xFF062037), // deep slate blue
                      Color(0xFF072B4F), // ocean midnight
                      Color(0xFF052038), // base shadow
                    ]
                  : const [
                      Color(0xFF0A1E46), // deep navy top
                      Color(0xFF0D2F73), // mid cobalt
                      Color(0xFF0F3C8F), // rich royal
                      Color(0xFF0B2C63), // base blend
                    ],
              stops: const [0.0, 0.35, 0.70, 1.0],
            ),
          ),
        ),
        // Subtle radial highlights for depth
        Positioned(
          top: -80,
          left: -60,
          child: _GlowCircle(color: const Color(0xFFFFFFFF).withOpacity(0.25), size: 220),
        ),
        Positioned(
          bottom: -100,
          right: -80,
          child: _GlowCircle(color: const Color(0xFFFFFFFF).withOpacity(0.18), size: 280),
        ),
        // App content on top
        child,
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class GlassyContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity; // Base fill opacity
  final EdgeInsetsGeometry? padding;
  final Color? tintColor; // Optional hue tint
  final bool subtleBorder; // Allow disabling strong border

  const GlassyContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 20,
    this.opacity = 0.12,
    this.padding,
    this.tintColor,
    this.subtleBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    // Base white glass; if tint provided, blend toward tint
    final base1 = (tintColor ?? Colors.white).withOpacity(opacity + 0.10);
    final base2 = (tintColor ?? Colors.white).withOpacity(opacity + 0.02);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withOpacity(subtleBorder ? 0.12 : 0.22),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base1, base2],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 40,
                spreadRadius: -6,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
