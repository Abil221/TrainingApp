import 'package:flutter/material.dart';

class AppScreenBackground extends StatelessWidget {
  final Widget child;

  const AppScreenBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: appScreenGradient(context),
      ),
      child: child,
    );
  }
}

LinearGradient appScreenGradient(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return LinearGradient(
    colors: isDark
        ? const [
            Color(0xFF08101D),
            Color(0xFF111827),
            Color(0xFF1B2435),
          ]
        : const [
            Color(0xFFFFF7F0),
            Color(0xFFF5F7FB),
            Color(0xFFFFEDE3),
          ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

BoxDecoration appPanelDecoration(
  BuildContext context, {
  Color accent = const Color(0xFFFF6B35),
  double radius = 24,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF162033),
              accent.withValues(alpha: 0.16),
            ]
          : [
              Colors.white.withValues(alpha: 0.92),
              accent.withValues(alpha: 0.08),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(
      color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
    ),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}
