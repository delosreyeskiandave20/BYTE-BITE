import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/motoscan_wordmark.dart';

/// Full-screen front page shown when the app launches.
///
/// The copy sits on a dark gradient over the photo and scrolls instead of
/// clipping when the user increases text size.
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
              child: Image.asset(
                'assets/motoscan-new-front-page.png',
                key: const ValueKey('welcome-hero-image'),
                cacheWidth: 1200,
                fit: BoxFit.cover,
                alignment: const Alignment(0.1, 0),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xF2151B1A),
                      Color(0xB3151B1A),
                      Color(0x00151B1A),
                    ],
                    stops: [0, 0.42, 0.75],
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
                          const _Wordmark(),
                          const SizedBox(height: AppSpacing.xxxl),
                          _WelcomeCopy(onGetStarted: onGetStarted),
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

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    // Frosted pill so the mark stays legible over any part of the photo, with
    // the same two-tone "Moto/Scan" name as the Home app bar.
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 18, 9),
        decoration: BoxDecoration(
          color: const Color(0x80000000),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        // Shrinks rather than overflowing on narrow phones.
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: MotoScanWordmark(
            key: ValueKey('motoscan-logo'),
            size: 24,
            onDark: true,
          ),
        ),
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x33F07A2F),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x80F07A2F)),
          ),
          child: const Text(
            'MOTORCYCLE PARTS FINDER',
            style: TextStyle(
              color: Color(0xFFFFB98A),
              fontSize: AppType.micro,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _FeatureChip(icon: Icons.build_circle_outlined, label: 'Parts'),
            _FeatureChip(icon: Icons.tire_repair, label: 'Sizes'),
            _FeatureChip(icon: Icons.storefront_outlined, label: 'Shops'),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
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
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.orange),
          const SizedBox(width: 5),
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
    );
  }
}
