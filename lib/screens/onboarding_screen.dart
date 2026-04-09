import 'package:flutter/material.dart';

import '../app_settings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: 'Тренируйся в своём ритме',
      subtitle:
          'Собрали в одном месте домашние тренировки, зал, избранное и быстрый поиск без лишнего шума.',
      icon: Icons.bolt_rounded,
      colors: [Color(0xFF111827), Color(0xFF283548)],
      accent: Color(0xFFFF6B35),
    ),
    _OnboardingPageData(
      title: 'Выбирай формат',
      subtitle:
          'Переходи в раздел `Дома` для быстрых сессий или в `Зал` для Split и Fullbody программ.',
      icon: Icons.fitness_center,
      colors: [Color(0xFFFF6B35), Color(0xFFE63946)],
      accent: Color(0xFFFFFFFF),
    ),
    _OnboardingPageData(
      title: 'Следи за прогрессом',
      subtitle:
          'Сохраняй любимые тренировки, запускай таймер и возвращайся к своим сессиям без потери темпа.',
      icon: Icons.show_chart_rounded,
      colors: [Color(0xFF0F766E), Color(0xFF155E75)],
      accent: Color(0xFFFFC857),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) {
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    await AppSettings().completeOnboarding();

    if (!mounted) {
      return;
    }

    setState(() {
      _isFinishing = false;
    });
  }

  Future<void> _nextPage() async {
    if (_currentPage == _pages.length - 1) {
      await _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'WELCOME',
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isFinishing ? null : _finishOnboarding,
                    child: const Text('Пропустить'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        gradient: LinearGradient(
                          colors: page.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: page.colors.first.withValues(alpha: 0.24),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child:
                                Icon(page.icon, size: 36, color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            page.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            page.subtitle,
                            style: const TextStyle(
                              color: Color(0xFFF8FAFC),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: page.accent),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Чистый спортивный интерфейс без лишней визуальной перегрузки.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final selected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: selected ? 28 : 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFF6B35)
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 176,
                    child: ElevatedButton.icon(
                      onPressed: _isFinishing ? null : _nextPage,
                      icon: Icon(
                        _isFinishing
                            ? Icons.hourglass_top_rounded
                            : _currentPage == _pages.length - 1
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _isFinishing
                            ? 'Открываем...'
                            : _currentPage == _pages.length - 1
                                ? 'Начать'
                                : 'Дальше',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Color accent;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.accent,
  });
}
