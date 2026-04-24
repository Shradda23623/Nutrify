import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _cardCtrl;
  late Animation<double> _cardFade;
  late Animation<double> _cardSlide;

  static const _pages = [
    _PageData(
      icon: Icons.local_fire_department_rounded,
      emoji: '🔥',
      title: 'Track Your Calories',
      subtitle:
          'Scan barcodes or search from 300+ Indian and global foods. Know exactly what you eat.',
      accentColor: Color(0xFFFF6B6B),
      gradientTopColor: Color(0xFF2D1B1B),
      stats: [
        _Stat('300+', 'Foods'),
        _Stat('8', 'Nutrients'),
        _Stat('100%', 'Accurate'),
      ],
    ),
    _PageData(
      icon: Icons.water_drop_rounded,
      emoji: '💧',
      title: 'Stay Hydrated',
      subtitle:
          'Set a daily water goal and log each glass with a tap. Smart reminders keep you on track.',
      accentColor: Color(0xFF4D96FF),
      gradientTopColor: Color(0xFF0D1E3D),
      stats: [
        _Stat('8', 'Glasses/day'),
        _Stat('Smart', 'Reminders'),
        _Stat('Daily', 'Streaks'),
      ],
    ),
    _PageData(
      icon: Icons.directions_walk_rounded,
      emoji: '👟',
      title: 'Count Your Steps',
      subtitle:
          'Use your phone sensor or wearable to auto-track daily steps and active calories burned.',
      accentColor: Color(0xFF6BCB77),
      gradientTopColor: Color(0xFF0D2215),
      stats: [
        _Stat('Auto', 'Tracking'),
        _Stat('Calories', 'Burned'),
        _Stat('Goals', 'Custom'),
      ],
    ),
    _PageData(
      icon: Icons.insights_rounded,
      emoji: '📊',
      title: 'Insights & BMI',
      subtitle:
          'Get your BMI, TDEE and weekly progress charts. Understand your body and own your journey.',
      accentColor: Color(0xFFFFD93D),
      gradientTopColor: Color(0xFF2D2600),
      stats: [
        _Stat('BMI', 'Calculator'),
        _Stat('TDEE', 'Estimator'),
        _Stat('Weekly', 'Reports'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut),
    );
    _cardSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut),
    );
    _cardCtrl.forward();
  }

  void _onPageChanged(int i) {
    setState(() => _currentPage = i);
    _cardCtrl.forward(from: 0.0);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _goHome();
    }
  }

  void _goHome() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Stack(
          children: [
            // Animated background gradient per page
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [page.gradientTopColor, const Color(0xFF0D0D1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Top accent glow
            Positioned(
              top: -120,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      page.accentColor.withOpacity(0.12),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.10)),
                          ),
                          child: Text(
                            '${_currentPage + 1} / ${_pages.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _goHome,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, i) => _buildPage(_pages[i]),
                    ),
                  ),

                  // Bottom nav
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                    child: Column(
                      children: [
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: _pages.length,
                          effect: ExpandingDotsEffect(
                            dotColor: Colors.white.withOpacity(0.20),
                            activeDotColor: page.accentColor,
                            dotHeight: 8,
                            dotWidth: 8,
                            expansionFactor: 3,
                            spacing: 6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        GestureDetector(
                          onTap: _next,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  page.accentColor,
                                  page.accentColor.withOpacity(0.75),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: page.accentColor.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.black,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_PageData page) {
    return AnimatedBuilder(
      animation: _cardCtrl,
      builder: (context, _) {
        return Opacity(
          opacity: _cardFade.value,
          child: Transform.translate(
            offset: Offset(0, _cardSlide.value),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji card
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: page.accentColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: page.accentColor.withOpacity(0.20),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: page.accentColor.withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: 8,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          page.emoji,
                          style: const TextStyle(fontSize: 62),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Feature badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: page.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: page.accentColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: page.accentColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Feature ${_pages.indexOf(page) + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: page.accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Title
                  Text(
                    page.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    page.subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.55),
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Stats row
                  Row(
                    children: List.generate(page.stats.length, (i) {
                      final s = page.stats[i];
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: i < page.stats.length - 1 ? 10 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                s.value,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: page.accentColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                s.label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Data ────────────────────────────────────────────────────────────────────
class _PageData {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color gradientTopColor;
  final List<_Stat> stats;

  const _PageData({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.gradientTopColor,
    required this.stats,
  });
}

class _Stat {
  final String value;
  final String label;
  const _Stat(this.value, this.label);
}
