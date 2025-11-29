import 'dart:ui';

import 'package:flutter/material.dart';

class GlassyBackground extends StatelessWidget {
  final Widget child;
  const GlassyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background with blue accent
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [
                      Color(0xFF000000), // pure black
                      Color(0xFF0A1929), // dark blue-black
                      Color(0xFF1E3A5F), // deep blue
                      Color(0xFF0D1B2A), // dark blue-black
                    ]
                  : const [
                      Color(0xFFF5F5F5), // light gray background
                      Color(0xFFEEEEEE), // slightly darker gray
                      Color(0xFFE8E8E8), // medium gray
                      Color(0xFFF0F0F0), // light gray
                    ],
              stops: const [0.0, 0.35, 0.70, 1.0],
            ),
          ),
        ),
        // No glow effects for clean professional look
        // App content on top
        child,
      ],
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
    final radius = borderRadius ?? BorderRadius.circular(24);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use tintColor for accent cards (mint green), otherwise default cards
    final bool isAccentCard = tintColor != null;
    
    Color cardColor;
    if (isAccentCard) {
      cardColor = isDark 
        ? const Color(0xFF1E3A5F) // deep blue for dark mode accent
        : const Color(0xFF2C2C2C); // dark gray for accent cards (like Smart Light card)
    } else {
      cardColor = isDark
        ? const Color(0xFF1A1A1A) // very dark gray card
        : const Color(0xFFFFFFFF); // pure white cards
    }
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: cardColor,
        border: isAccentCard ? null : Border.all(
          color: isDark 
            ? const Color(0xFF2563EB).withOpacity(0.3) // blue border for dark
            : const Color(0xFFE0E0E0), // subtle gray border
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
