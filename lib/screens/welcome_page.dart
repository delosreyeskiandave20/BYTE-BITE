import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

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
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.two_wheeler_rounded,
            color: AppColors.ink,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Shrinks rather than overflowing on narrow phones with large text.
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'MotoScan',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppType.section,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
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
        Semantics(
          header: true,
          child: const Text(
            'The right parts for your ride.',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppType.display + 4,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Browse parts and accessories for your motorcycle, then find '
          'local shops that have them in stock.',
          style: TextStyle(
            color: Color(0xE6FFFFFF),
            fontSize: AppType.body + 1,
            height: 1.45,
          ),
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
