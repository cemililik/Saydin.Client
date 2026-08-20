import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saydin/core/constants/app_branding.dart';
import 'package:saydin/core/constants/brand_colors.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/legal/domain/entities/legal_document.dart';
import 'package:saydin/features/legal/domain/repositories/legal_repository.dart';
import 'package:saydin/features/legal/presentation/pages/legal_document_page.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingPage extends StatefulWidget {
  /// Sayfa geçiş animasyonu süresi. Test'ler bekleme süresini bu sabitten
  /// türetir: `_ambientMotion` sonsuz döngüde olduğu için `pumpAndSettle`
  /// asla settle etmez ve sabit bir bekleme süresi gerekir.
  static const pageTransitionDuration = Duration(milliseconds: 380);

  final VoidCallback onComplete;
  final bool legalUpdateOnly;

  const OnboardingPage({
    super.key,
    required this.onComplete,
    this.legalUpdateOnly = false,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  static const _pageCount = 3;

  static const _pages = [
    _PageData(
      visual: _OnboardingVisualType.brandMoment,
      accent: BrandColors.teal,
    ),
    _PageData(
      visual: _OnboardingVisualType.toolkit,
      accent: BrandColors.steelAccent,
    ),
    _PageData(visual: _OnboardingVisualType.result, accent: BrandColors.teal),
  ];

  late final PageController _controller;
  late final AnimationController _ambientMotion;
  late final AnimationController _contentEntrance;
  late int _currentPage;

  /// Son CTA veya "Atla" hızlıca birden çok kez tetiklendiğinde legal kayıt
  /// ve `onComplete` yalnız bir kez çalışır.
  bool _isCompleting = false;
  bool _legalSaveFailed = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.legalUpdateOnly ? _pageCount - 1 : 0;
    _controller = PageController(initialPage: _currentPage);
    _ambientMotion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _contentEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ambientMotion.stop();
      _ambientMotion.value = 0.5;
      _contentEntrance.value = 1;
    } else if (!_ambientMotion.isAnimating) {
      _ambientMotion.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _ambientMotion.dispose();
    _contentEntrance.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < _pageCount - 1) {
      await _controller.nextPage(
        duration: OnboardingPage.pageTransitionDuration,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    // Haptic platform kanalı yavaş/yanıtsız olsa bile ana akışı bloklamasın.
    unawaited(HapticFeedback.mediumImpact());
    await _completeWithLegalNotice();
  }

  Future<void> _previousPage() async {
    if (_currentPage == 0) return;
    await _controller.previousPage(
      duration: OnboardingPage.pageTransitionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipOnboarding() => _completeWithLegalNotice();

  /// Aydınlatma metninin sunulması bir sözleşme kabulü veya açık rıza değildir;
  /// yalnız `seen` kaydı yazılır. Yazma başarısızsa hata görünür ve kullanıcı
  /// tekrar deneyebilir.
  Future<void> _completeWithLegalNotice() async {
    if (_isCompleting) return;
    setState(() {
      _isCompleting = true;
      _legalSaveFailed = false;
    });
    try {
      await sl<OnboardingRepository>().recordLegalNotice(
        LegalNoticeRecord.current(
          locale: Localizations.localeOf(context).toLanguageTag(),
          recordedAtUtc: DateTime.now().toUtc(),
          decision: LegalNoticeDecision.seen,
        ),
      );
    } catch (error, stackTrace) {
      await sl<ErrorReporter>().report(
        error,
        stackTrace,
        context: 'legal_notice_save_failed',
      );
      if (!mounted) return;
      setState(() {
        _isCompleting = false;
        _legalSaveFailed = true;
      });
      return;
    }
    if (mounted) widget.onComplete();
  }

  void _openLegalDocument(LegalDocumentType type) {
    final locale = Localizations.localeOf(context).toString();
    final document = sl<LegalRepository>().load(type, locale);
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => LegalDocumentPage(document: document)),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    // Hareket azaltma yalnız ilk build'de değil, her sayfa geçişinde de
    // geçerlidir; aksi hâlde giriş animasyonu her geçişte yeniden oynar.
    if (MediaQuery.disableAnimationsOf(context)) {
      _contentEntrance.value = 1;
      return;
    }
    _contentEntrance
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLastPage = _currentPage == _pageCount - 1;
    final titles = [
      l10n.onboardingPage1Title,
      l10n.onboardingPage2Title,
      l10n.onboardingPage3Title,
    ];
    final bodies = [
      l10n.onboardingPage1Body,
      l10n.onboardingPage2Body,
      l10n.onboardingPage3Body,
    ];
    final currentTitle = widget.legalUpdateOnly && isLastPage
        ? l10n.onboardingLegalUpdateTitle
        : titles[_currentPage];
    final currentBody = widget.legalUpdateOnly && isLastPage
        ? l10n.onboardingLegalUpdateBody
        : bodies[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _OnboardingBackdrop(
              accent: _pages[_currentPage].accent,
              isDark: isDark,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Görsel alan viewport'un %34'ü, 292dp ile sınırlı. Sabit
                // alt taban yok: kısa viewport'ta (yatay mod, küçük telefon)
                // taban CTA'yı gereksiz derinliğe itiyordu. Görseller kendi
                // içinde ölçeğe uyduğu için küçük yükseklikte de taşma olmaz.
                final visualHeight = math.min(
                  constraints.maxHeight * 0.34,
                  292.0,
                );
                return SingleChildScrollView(
                  key: const Key('onboarding-scroll-view'),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            _BrandHeader(
                              isDark: isDark,
                              showBack: _currentPage > 0,
                              isCompleting: _isCompleting,
                              onBack: _previousPage,
                              onSkip: _skipOnboarding,
                            ),
                            _LegalNoticeLinks(
                              onOpenPrivacy: () => _openLegalDocument(
                                LegalDocumentType.privacyPolicy,
                              ),
                              onOpenKvkk: () => _openLegalDocument(
                                LegalDocumentType.kvkkDisclosure,
                              ),
                            ),
                            if (_legalSaveFailed)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  4,
                                ),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    l10n.legalRecordSaveFailed,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontFamily: AppBranding.uiFontFamily,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: visualHeight,
                              child: PageView.builder(
                                key: const Key('onboarding-page-view'),
                                controller: _controller,
                                onPageChanged: _onPageChanged,
                                itemCount: _pageCount,
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    8,
                                    24,
                                    10,
                                  ),
                                  child: _OnboardingVisual(
                                    key: ValueKey('onboarding-visual-$index'),
                                    type:
                                        widget.legalUpdateOnly &&
                                            index == _pageCount - 1
                                        ? _OnboardingVisualType.legalUpdate
                                        : _pages[index].visual,
                                    animation: _ambientMotion,
                                  ),
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _contentEntrance,
                                curve: Curves.easeOut,
                              ),
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0, 0.08),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _contentEntrance,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        currentTitle,
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontFamily:
                                                  AppBranding.uiFontFamily,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -1,
                                              height: 1.08,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 430,
                                        ),
                                        child: Text(
                                          currentBody,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontFamily:
                                                    AppBranding.uiFontFamily,
                                                height: 1.45,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                          child: Column(
                            children: [
                              _PageIndicator(
                                currentPage: _currentPage,
                                pageCount: _pageCount,
                              ),
                              const SizedBox(height: 20),
                              if (isLastPage) ...[
                                _LegalNoticeStatement(
                                  onOpenPrivacy: () => _openLegalDocument(
                                    LegalDocumentType.privacyPolicy,
                                  ),
                                  onOpenKvkk: () => _openLegalDocument(
                                    LegalDocumentType.kvkkDisclosure,
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              _PrimaryAction(
                                enabled: !_isCompleting,
                                label: widget.legalUpdateOnly && isLastPage
                                    ? l10n.onboardingContinue
                                    : isLastPage
                                    ? l10n.onboardingGetStarted
                                    : l10n.onboardingNext,
                                isLastPage: isLastPage,
                                onTap: _nextPage,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.isDark,
    required this.showBack,
    required this.isCompleting,
    required this.onBack,
    required this.onSkip,
  });

  final bool isDark;
  final bool showBack;
  final bool isCompleting;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 52),
          child: showBack
              ? IconButton(
                  key: const Key('onboarding-back'),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null,
        ),
        Expanded(
          child: Center(
            child: Semantics(
              image: true,
              label: AppBranding.displayName,
              child: Image.asset(
                isDark
                    ? AppBranding.horizontalLogoOnDarkAsset
                    : AppBranding.horizontalLogoOnLightAsset,
                key: const Key('onboarding-brand-logo'),
                height: 34,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        // Sabit genişlik büyük erişilebilirlik yazı ölçeklerinde "Atla"
        // etiketini kırpıyordu; slot yalnız minimum genişliği dayatır.
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 68),
          child: TextButton(
            onPressed: isCompleting ? null : onSkip,
            child: Text(
              context.l10n.onboardingSkip,
              style: const TextStyle(
                fontFamily: AppBranding.uiFontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Linkler "Atla" dahil her tamamlama aksiyonundan önce görünür tutulur.
class _LegalNoticeLinks extends StatelessWidget {
  const _LegalNoticeLinks({
    required this.onOpenPrivacy,
    required this.onOpenKvkk,
  });

  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenKvkk;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontFamily: AppBranding.uiFontFamily,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 4,
        children: [
          Semantics(
            link: true,
            child: TextButton(
              key: const Key('onboarding-privacy-link'),
              onPressed: onOpenPrivacy,
              // VisualDensity.compact dokunma hedefini 48dp'den 40dp'ye
              // düşürüp yatay padding'i sıfırlıyordu (KVKK yüzeyi).
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                context.l10n.onboardingPrivacyPolicyLink,
                style: textStyle,
              ),
            ),
          ),
          Semantics(
            link: true,
            child: TextButton(
              key: const Key('onboarding-kvkk-link'),
              onPressed: onOpenKvkk,
              // VisualDensity.compact dokunma hedefini 48dp'den 40dp'ye
              // düşürüp yatay padding'i sıfırlıyordu (KVKK yüzeyi).
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(context.l10n.onboardingKvkkLink, style: textStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const Key('onboarding-page-indicator'),
    liveRegion: true,
    label: context.l10n.onboardingProgress(currentPage + 1, pageCount),
    child: ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final isActive = currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: isActive ? 28 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? BrandColors.tealFor(Theme.of(context).brightness)
                  : Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    ),
  );
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.enabled,
    required this.label,
    required this.isLastPage,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final bool isLastPage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56, minWidth: double.infinity),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [BrandColors.navy, BrandColors.ctaGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.navy.withAlpha(45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('onboarding-primary-action'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: BrandColors.onNavy,
                      fontFamily: AppBranding.uiFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: BrandColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLastPage
                        ? Icons.arrow_forward_rounded
                        : Icons.chevron_right_rounded,
                    color: BrandColors.navy,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _LegalNoticeStatement extends StatelessWidget {
  const _LegalNoticeStatement({
    required this.onOpenPrivacy,
    required this.onOpenKvkk,
  });

  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenKvkk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final placeholderPrivacy = '__P__';
    final placeholderKvkk = '__K__';
    final template = l10n.onboardingLegalNotice(
      placeholderPrivacy,
      placeholderKvkk,
    );
    final spans = <InlineSpan>[];
    var cursor = 0;
    final pattern = RegExp(
      '${RegExp.escape(placeholderPrivacy)}|${RegExp.escape(placeholderKvkk)}',
    );
    for (final match in pattern.allMatches(template)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: template.substring(cursor, match.start)));
      }
      final isPrivacy = match.group(0) == placeholderPrivacy;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Semantics(
            link: true,
            child: InkWell(
              onTap: isPrivacy ? onOpenPrivacy : onOpenKvkk,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  isPrivacy
                      ? l10n.onboardingPrivacyPolicyLink
                      : l10n.onboardingKvkkLink,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontFamily: AppBranding.uiFontFamily,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < template.length) {
      spans.add(TextSpan(text: template.substring(cursor)));
    }

    return Padding(
      key: const Key('onboarding-legal-notice-statement'),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(
        TextSpan(
          children: spans,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: AppBranding.uiFontFamily,
            height: 1.4,
          ),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

enum _OnboardingVisualType { brandMoment, toolkit, result, legalUpdate }

class _PageData {
  const _PageData({required this.visual, required this.accent});

  final _OnboardingVisualType visual;
  final Color accent;
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual({
    super.key,
    required this.type,
    required this.animation,
  });

  final _OnboardingVisualType type;
  final Animation<double> animation;

  /// Görseller tümüyle dekoratiftir; anlamı başlık ve gövde metni taşır.
  /// Ekran okuyucunun etiketsiz görsel düğümlerinde durmaması için alt ağaç
  /// tümüyle semantikten çıkarılır.
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: switch (type) {
      _OnboardingVisualType.brandMoment => _BrandMomentVisual(
        animation: animation,
      ),
      _OnboardingVisualType.toolkit => _ToolkitVisual(animation: animation),
      _OnboardingVisualType.result => _ResultVisual(animation: animation),
      _OnboardingVisualType.legalUpdate => _LegalUpdateVisual(
        animation: animation,
      ),
    },
  );
}

class _BrandMomentVisual extends StatelessWidget {
  const _BrandMomentVisual({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => Center(
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (animation.value - 0.5) * 8),
        child: child,
      ),
      // Sonsuz ambient döngüde translate'in gradient + blur gölge + clip
      // katmanını her karede yeniden rasterize etmemesi için kart kendi
      // repaint katmanına alınır.
      child: RepaintBoundary(child: _card(context)),
    ),
  );

  Widget _card(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: AspectRatio(
      aspectRatio: 1.48,
      child: Container(
        key: const Key('onboarding-brand-visual'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BrandColors.navy, BrandColors.navyCardEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: BrandColors.navy.withAlpha(50),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _TrendPainter()),
              ),
              Positioned(
                left: 22,
                top: 20,
                child: _TimelineChip(
                  icon: Icons.history_rounded,
                  label: context.l10n.onboardingPastLabel,
                ),
              ),
              Positioned(
                right: 22,
                bottom: 20,
                child: _TimelineChip(
                  icon: Icons.today_rounded,
                  label: context.l10n.onboardingTodayLabel,
                  emphasized: true,
                ),
              ),
              Align(
                alignment: const Alignment(0.02, -0.02),
                child: Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BrandColors.offWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: BrandColors.onNavy, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: BrandColors.scrim,
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    AppBranding.fullColorSymbolAsset,
                    key: const Key('onboarding-brand-symbol'),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TimelineChip extends StatelessWidget {
  const _TimelineChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: emphasized ? BrandColors.teal : BrandColors.surfaceOnNavy,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: emphasized ? BrandColors.teal : BrandColors.hairlineOnNavy,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: emphasized ? BrandColors.navy : BrandColors.offWhite,
        ),
        const SizedBox(width: 6),
        // Chip, kartın içine `Positioned` ile yerleşir ve büyük yazı
        // ölçeklerinde etiket kart genişliğini aşabilir; Flexible + ellipsis
        // Row'un taşmasını (RenderFlex overflow) engeller.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasized ? BrandColors.navy : BrandColors.offWhite,
              fontFamily: AppBranding.uiFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = BrandColors.gridOnNavy
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glowPath = Path()
      ..moveTo(size.width * 0.02, size.height * 0.78)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.70,
        size.width * 0.28,
        size.height * 0.48,
        size.width * 0.48,
        size.height * 0.54,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.60,
        size.width * 0.76,
        size.height * 0.25,
        size.width * 0.98,
        size.height * 0.18,
      );
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = BrandColors.teal.withAlpha(45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = BrandColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ToolkitVisual extends StatelessWidget {
  const _ToolkitVisual({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.compare_arrows_rounded, l10n.tabCompare),
      (Icons.pie_chart_outline_rounded, l10n.tabPortfolio),
      (Icons.repeat_rounded, l10n.tabDca),
      (Icons.swap_vert_rounded, l10n.modeReverse),
    ];
    // Sabit childAspectRatio tile yüksekliğini metin ölçeğinden bağımsız
    // sabitliyor ve iki satırlık etiketi kırpıyordu; yükseklik hem yazı
    // ölçeğine hem de eldeki slota göre hesaplanır.
    final labelHeight = MediaQuery.textScalerOf(context).scale(12) * 1.15 * 2;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Tile'ın metin dışı dikey bütçesi (ikon bloğu + iç boşluk).
            const tileChrome = 52.0;
            // Grid'in tile dışı dikey tüketimi: 4+4 padding + 12 satır arası.
            const gridChrome = 20.0;
            final tileExtent = math.max(
              1.0,
              math.min(
                labelHeight + tileChrome,
                (constraints.maxHeight - gridChrome) / 2,
              ),
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                GridView.builder(
                  key: const Key('onboarding-toolkit-visual'),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  // shrinkWrap olmadan viewport tüm slotu kaplar, iki satır
                  // üstte hizalı kalır ve ortadaki marka rozeti grid'in
                  // gutter'ı yerine Stack'in ortasına düşerek alt sıradaki
                  // tile'ların üzerine biner.
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: tileExtent,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final direction = index.isEven ? -1.0 : 1.0;
                      return Transform.translate(
                        offset: Offset(direction * animation.value * 2, 0),
                        child: child,
                      );
                    },
                    child: RepaintBoundary(
                      child: _FeatureTile(
                        icon: items[index].$1,
                        label: items[index].$2,
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    key: const Key('onboarding-toolkit-badge'),
                    width: 62,
                    height: 62,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.navy.withAlpha(28),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AppBranding.fullColorSymbolAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      // Yatay chrome daraltıldı: 360dp cihazda etikete kalan genişlik
      // 77dp'den 98dp'ye çıkar, böylece "Karşılaştır" gibi bölünemeyen
      // tek kelimelik etiketler normal ölçekte kırpılmaz.
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: BrandColors.navy.withAlpha(isDark ? 20 : 14),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: BrandColors.teal.withAlpha(isDark ? 38 : 26),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Icon(
                icon,
                color: BrandColors.tealFor(theme.brightness),
                size: 20,
              ),
            ],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontFamily: AppBranding.uiFontFamily,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultVisual extends StatelessWidget {
  const _ResultVisual({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => Center(
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, child) =>
          Transform.scale(scale: 0.99 + (animation.value * 0.01), child: child),
      child: RepaintBoundary(child: _card(context)),
    ),
  );

  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = BrandColors.tealFor(theme.brightness);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: AspectRatio(
        aspectRatio: 1.55,
        child: Container(
          key: const Key('onboarding-result-visual'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: BrandColors.navy.withAlpha(isDark ? 22 : 18),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    AppBranding.fullColorSymbolAsset,
                    width: 38,
                    height: 38,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                  const Spacer(),
                  const _RoundActionIcon(icon: Icons.bookmark_outline_rounded),
                  const SizedBox(width: 8),
                  const _RoundActionIcon(icon: Icons.ios_share_rounded),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      // child'sız CustomPaint kendini `constraints.smallest`
                      // ile boyutlandırır; Row gevşek yükseklik verdiği için
                      // kutu Size(genişlik, 0) olup grafik düz çizgiye
                      // çöküyordu.
                      child: CustomPaint(
                        key: const Key('onboarding-result-chart'),
                        size: Size.infinite,
                        painter: _MiniChartPainter(
                          lineColor: accent,
                          gridColor: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Container(
                      key: const Key('onboarding-result-gain-badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.teal.withAlpha(isDark ? 34 : 24),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      // Kazancı yalnız ikon taşır: lokalize edilmemiş "+%"
                      // metni hem l10n sözleşmesini deliyor hem de metin
                      // ölçeğiyle büyüyüp sabit oranlı kartı taşırıyordu.
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: accent,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundActionIcon extends StatelessWidget {
  const _RoundActionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
  );
}

class _MiniChartPainter extends CustomPainter {
  const _MiniChartPainter({required this.lineColor, required this.gridColor});

  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withAlpha(100)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.75,
        size.width * 0.28,
        size.height * 0.48,
        size.width * 0.46,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.65,
        size.width * 0.75,
        size.height * 0.24,
        size.width,
        size.height * 0.18,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.gridColor != gridColor;
}

class _LegalUpdateVisual extends StatelessWidget {
  const _LegalUpdateVisual({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => Center(
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (animation.value - 0.5) * 6),
        child: child,
      ),
      // Sabit 210dp daire dar slotta elipse dönüşüyordu; scaleDown daireyi
      // yuvarlak tutarak küçültür.
      child: RepaintBoundary(
        child: FittedBox(fit: BoxFit.scaleDown, child: _badge(context)),
      ),
    ),
  );

  Widget _badge(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('onboarding-legal-update-visual'),
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        color: BrandColors.teal.withAlpha(
          theme.brightness == Brightness.dark ? 30 : 20,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: BrandColors.teal.withAlpha(80)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            color: theme.colorScheme.onSurface,
            size: 82,
          ),
          const Positioned(
            right: 44,
            bottom: 46,
            child: CircleAvatar(
              radius: 21,
              backgroundColor: BrandColors.teal,
              child: Icon(Icons.check_rounded, color: BrandColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop({required this.accent, required this.isDark});

  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.75, -0.85),
          radius: 1.25,
          colors: [accent.withAlpha(isDark ? 34 : 22), surface],
          stops: const [0, 0.72],
        ),
      ),
    );
  }
}
