import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/motoscan_wordmark.dart';

/// Full-screen front page shown when the app launches.
///
/// The photo is softly blurred behind a dark gradient so the centred logo
/// stands out. The content scrolls instead of clipping when the user
/// increases text size.
class WelcomePage extends StatelessWidget {
  const WelcomePage({required this.onGetStarted, super.key});

  /// Called when the rider taps "Get started".
  final VoidCallback onGetStarted;

  static const _backdrop = Color(0xFF151B1A);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The photo is dark, so status bar icons must be light.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _backdrop,
        body: Stack(
          children: [
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Image.asset(
                  'assets/motoscan-new-front-page.png',
                  key: const ValueKey('welcome-hero-image'),
                  cacheWidth: 1200,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.1, 0),
                ),
              ),
            ),
            // Darkens the whole photo, most strongly at the bottom where the
            // button sits.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99151B1A),
                      Color(0x66151B1A),
                      Color(0xCC151B1A),
                      Color(0xF7151B1A),
                    ],
                    stops: [0, 0.4, 0.72, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxxl,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Equal space above and below keeps the logo
                          // roughly in the middle of the screen.
                          const SizedBox(height: AppSpacing.xxl),
                          const _CenterLogo(),
                          const SizedBox(height: AppSpacing.xxxl),
                          _WelcomeActions(onGetStarted: onGetStarted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The MotoScan logo in the middle of the screen with a soft orange glow,
/// plus a short tagline.
class _CenterLogo extends StatelessWidget {
  const _CenterLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.28),
                blurRadius: 80,
                spreadRadius: 10,
              ),
            ],
          ),
          // Shrinks rather than overflowing on narrow phones.
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: MotoScanWordmark(
              key: ValueKey('motoscan-logo'),
              size: 44,
              onDark: true,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _rule(),
            const SizedBox(width: AppSpacing.sm),
            const Flexible(
              child: Text(
                'MOTORCYCLE PARTS FINDER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFC9A3),
                  fontSize: AppType.micro,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _rule(),
          ],
        ),
      ],
    );
  }

  Widget _rule() => Container(
    width: 22,
    height: 1.5,
    decoration: BoxDecoration(
      color: AppColors.orange.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Find parts that fit your motorcycle, check sizes and shop '
          'from local stores.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xD9FFFFFF),
            fontSize: AppType.body,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _FeatureChip(icon: Icons.build_circle_outlined, label: 'Parts'),
            _FeatureChip(icon: Icons.tire_repair, label: 'Sizes'),
            _FeatureChip(icon: Icons.storefront_outlined, label: 'Shops'),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('welcome-get-started'),
              onPressed: onGetStarted,
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              iconAlignment: IconAlignment.end,
              label: const Text('Get started'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(
                  fontSize: AppType.cardTitle + 1,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Frosted-glass chip naming one thing the app does.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.orange),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppType.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
