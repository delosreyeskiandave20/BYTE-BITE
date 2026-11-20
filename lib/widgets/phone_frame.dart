import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shows the app inside a realistic phone on wide web windows (desktop
/// browsers). The app is laid out exactly as on a 390 x 844 phone (iPhone 14
/// / standard Android size) and the whole phone is then scaled to fit the
/// window with a fixed aspect ratio, so it never gets squashed or cut off.
///
/// On narrow windows (real phones, width < [fullScreenBelowWidth]) and on
/// non-web platforms the app is shown full screen, unframed.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({required this.child, this.enabled, super.key});

  final Widget child;

  /// Overrides when the frame may show. Defaults to web only
  /// ([showOnAllPlatforms] lets tests and desktop previews turn it on).
  final bool? enabled;

  /// Lets widget tests (which do not run as web) show the frame.
  static bool showOnAllPlatforms = false;

  /// The phone's screen in logical pixels.
  static const screenSize = Size(390, 844);

  /// Status bar / dynamic island area and home indicator area.
  static const screenPadding = EdgeInsets.only(top: 47, bottom: 34);

  /// Windows narrower than this are phones: no frame.
  static const fullScreenBelowWidth = 600.0;

  static const _bezel = 12.0;
  static const _outerRadius = 48.0;
  static const _innerRadius = _outerRadius - _bezel;
  static const _margin = 24.0;
  static const _maxScale = 1.25;

  /// The phone including its bezel.
  static final frameSize = Size(
    screenSize.width + _bezel * 2,
    screenSize.height + _bezel * 2,
  );

  @override
  Widget build(BuildContext context) {
    final active = enabled ?? (kIsWeb || showOnAllPlatforms);
    if (!active) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < fullScreenBelowWidth) return child;

        // Fit the whole phone in the window with a margin, never stretched.
        final scale = math.min(
          _maxScale,
          math.min(
            (constraints.maxHeight - _margin * 2) / frameSize.height,
            (constraints.maxWidth - _margin * 2) / frameSize.width,
          ),
        );
        if (scale <= 0) return child;

        final outer = MediaQuery.of(context);
        final phoneMedia = outer.copyWith(
          size: screenSize,
          devicePixelRatio: 3,
          padding: screenPadding,
          viewPadding: screenPadding,
          viewInsets: EdgeInsets.zero,
          systemGestureInsets: EdgeInsets.zero,
          // Browser zoom and font settings must not distort the preview.
          textScaler: TextScaler.noScaling,
        );

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8EAE5), Color(0xFFD9DDD7)],
            ),
          ),
          child: Center(
            child: SizedBox(
              key: const ValueKey('desktop-phone-frame'),
              width: frameSize.width * scale,
              height: frameSize.height * scale,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox.fromSize(
                  size: frameSize,
                  child: _Phone(
                    child: MediaQuery(data: phoneMedia, child: child),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111213),
        borderRadius: BorderRadius.circular(PhoneFrame._outerRadius),
        border: Border.all(color: const Color(0xFF3A3C3E), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400D1110),
            blurRadius: 48,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(PhoneFrame._bezel),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PhoneFrame._innerRadius),
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: const Color(0xFFF7F5F0), child: child),
              ),
              // Dynamic island, drawn over the status-bar area only.
              Positioned(
                top: 11,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      key: const ValueKey('desktop-camera-cutout'),
                      width: 122,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111213),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              // Home indicator, inside the bottom safe area.
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 134,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22201E),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
