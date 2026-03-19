import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;
  static const _pageCount = 6;

  late final AnimationController _iconPulse;
  late final AnimationController _contentEntrance;

  @override
  void initState() {
    super.initState();
    _iconPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _contentEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconPulse.dispose();
    _contentEntrance.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      HapticFeedback.mediumImpact();
      widget.onComplete();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _contentEntrance.reset();
    _contentEntrance.forward();
  }

  static const _pageData = [
    _PageData(
      mainIcon: Icons.trending_up_rounded,
      floatingIcons: [
        Icons.attach_money_rounded,
        Icons.currency_bitcoin_rounded,
        Icons.diamond_outlined,
      ],
      gradientColors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    ),
    _PageData(
      mainIcon: Icons.compare_arrows_rounded,
      floatingIcons: [
        Icons.bar_chart_rounded,
        Icons.pie_chart_rounded,
        Icons.analytics_rounded,
      ],
      gradientColors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
    ),
    _PageData(
      mainIcon: Icons.account_balance_wallet_rounded,
      floatingIcons: [
        Icons.pie_chart_rounded,
        Icons.auto_graph_rounded,
        Icons.savings_rounded,
      ],
      gradientColors: [Color(0xFFE65100), Color(0xFFBF360C)],
    ),
    _PageData(
      mainIcon: Icons.repeat_rounded,
      floatingIcons: [
        Icons.calendar_month_rounded,
        Icons.savings_rounded,
        Icons.show_chart_rounded,
      ],
      gradientColors: [Color(0xFFEF6C00), Color(0xFFE65100)],
    ),
    _PageData(
      mainIcon: Icons.swap_vert_rounded,
      floatingIcons: [
        Icons.flag_rounded,
        Icons.calculate_rounded,
        Icons.history_rounded,
      ],
      gradientColors: [Color(0xFFC62828), Color(0xFF8E0000)],
    ),
    _PageData(
      mainIcon: Icons.rocket_launch_rounded,
      floatingIcons: [
        Icons.bookmark_rounded,
        Icons.share_rounded,
        Icons.favorite_rounded,
      ],
      gradientColors: [Color(0xFF00897B), Color(0xFF004D40)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLastPage = _currentPage == _pageCount - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titles = [
      l10n.onboardingPage1Title,
      l10n.onboardingPage2Title,
      l10n.onboardingPage3Title,
      l10n.onboardingPage4Title,
      l10n.onboardingPage5Title,
      l10n.onboardingPage6Title,
    ];
    final bodies = [
      l10n.onboardingPage1Body,
      l10n.onboardingPage2Body,
      l10n.onboardingPage3Body,
      l10n.onboardingPage4Body,
      l10n.onboardingPage5Body,
      l10n.onboardingPage6Body,
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Arka plan gradient — sayfa değişimine göre geçiş
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        _pageData[_currentPage].gradientColors[0].withAlpha(40),
                        _pageData[_currentPage].gradientColors[1].withAlpha(25),
                        Theme.of(context).scaffoldBackgroundColor,
                      ]
                    : [
                        _pageData[_currentPage].gradientColors[0].withAlpha(20),
                        _pageData[_currentPage].gradientColors[1].withAlpha(10),
                        Colors.white,
                      ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Üst bar — logo + atla
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                  child: Row(
                    children: [
                      Text(
                        'Saydın',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onComplete,
                        child: Text(
                          l10n.onboardingSkip,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withAlpha(180),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // İkon alanı
                Expanded(
                  flex: 5,
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: _onPageChanged,
                    itemCount: _pageCount,
                    itemBuilder: (context, index) {
                      return _IconComposition(
                        data: _pageData[index],
                        pulseAnimation: _iconPulse,
                      );
                    },
                  ),
                ),

                // İçerik alanı — başlık + açıklama
                Expanded(
                  flex: 4,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _contentEntrance,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _contentEntrance,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                          children: [
                            Text(
                              titles[_currentPage],
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              bodies[_currentPage],
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    height: 1.6,
                                    fontSize: 16,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Alt kontroller — gösterge + buton
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    children: [
                      // Sayfa göstergeleri
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pageCount, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _pageData[_currentPage].gradientColors[0]
                                  : Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant.withAlpha(100),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Ana buton
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: _pageData[_currentPage].gradientColors,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _pageData[_currentPage].gradientColors[0]
                                    .withAlpha(80),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _nextPage,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Row(
                                    key: ValueKey(isLastPage),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isLastPage
                                            ? l10n.onboardingGetStarted
                                            : l10n.onboardingNext,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isLastPage
                                            ? Icons.arrow_forward_rounded
                                            : Icons.chevron_right_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sayfa verisi ──────────────────────────────────────────────────────────────

class _PageData {
  final IconData mainIcon;
  final List<IconData> floatingIcons;
  final List<Color> gradientColors;

  const _PageData({
    required this.mainIcon,
    required this.floatingIcons,
    required this.gradientColors,
  });
}

// ── İkon kompozisyonu — ortada ana ikon + çevresinde yüzen küçük ikonlar ─────

class _IconComposition extends StatelessWidget {
  final _PageData data;
  final AnimationController pulseAnimation;

  const _IconComposition({required this.data, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dış halka — nabız efekti
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                final scale = 1.0 + pulseAnimation.value * 0.08;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: data.gradientColors[0].withAlpha(30),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),

            // İç daire — gradient arka plan
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.gradientColors[0].withAlpha(30),
                    data.gradientColors[1].withAlpha(15),
                  ],
                ),
              ),
              child: Icon(
                data.mainIcon,
                size: 64,
                color: data.gradientColors[0],
              ),
            ),

            // Yüzen ikonlar
            for (var i = 0; i < data.floatingIcons.length; i++)
              _FloatingIcon(
                icon: data.floatingIcons[i],
                color: data.gradientColors[0],
                angle:
                    (i * 2 * math.pi / data.floatingIcons.length) - math.pi / 2,
                radius: 105,
                pulseAnimation: pulseAnimation,
                index: i,
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double angle;
  final double radius;
  final AnimationController pulseAnimation;
  final int index;

  const _FloatingIcon({
    required this.icon,
    required this.color,
    required this.angle,
    required this.radius,
    required this.pulseAnimation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        // Her ikon farklı fazda salınır
        final phase = (pulseAnimation.value + index * 0.33) % 1.0;
        final bounce = math.sin(phase * math.pi) * 6;
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius + bounce;

        return Transform.translate(offset: Offset(x, y), child: child);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
