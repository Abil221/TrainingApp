import 'package:flutter/material.dart';

/// Отображает изображение тренировки: поддерживает как локальные assets
/// (пути вида 'assets/...'), так и сетевые URL (http/https — из Supabase Storage).
class WorkoutImage extends StatelessWidget {
  final String? src;
  final double width;
  final double height;
  final BoxFit fit;
  final IconData fallbackIcon;

  const WorkoutImage({
    super.key,
    required this.src,
    this.width = double.infinity,
    this.height = 164,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
  });

  static bool isNetworkUrl(String? src) {
    if (src == null || src.isEmpty) return false;
    return src.startsWith('http://') || src.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final path = src ?? '';

    if (isNetworkUrl(path)) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _placeholder(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
              color: const Color(0xFFFF6B35),
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (path.isNotEmpty) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _placeholder({required Widget child}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1A2538),
      child: Center(child: child),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF374151)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(fallbackIcon, size: height * 0.26, color: Colors.white38),
    );
  }
}
