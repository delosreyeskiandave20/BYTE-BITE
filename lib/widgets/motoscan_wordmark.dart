import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The "MotoScan" logo: bold italic lettering with speed streaks in front,
/// an orange gradient on "Scan" and a glowing scan beam under it.
///
/// Use [onDark] over photos or dark backgrounds ("Moto" in white) and the
/// default on light backgrounds ("Moto" in ink).
class MotoScanWordmark extends StatelessWidget {
  const MotoScanWordmark({this.size = 24, this.onDark = false, super.key});

  /// Font size of the lettering; everything else scales with it.
  final double size;
  final bool onDark;

  static const _scanGradient = LinearGradient(
    colors: [Color(0xFFFFB067), AppColors.orange, AppColors.primary],
    stops: [0, 0.45, 1],
  );

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.04 * size,
    );
    return Semantics(
      label: 'MotoScan',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SpeedStreaks(size: size, onDark: onDark),
          SizedBox(width: size * 0.12),
          Text(
            'MOTO',
            style: style.copyWith(color: onDark ? Colors.white : AppColors.ink),
          ),
          IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Leaves room for the beam so the row stays centred.
                SizedBox(height: size * 0.16),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: _scanGradient.createShader,
                  // Room on the right so the italic "N" isn't clipped.
                  child: Padding(
                    padding: EdgeInsets.only(right: size * 0.14),
                    child: Text(
                      'SCAN',
                      style: style.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: size * 0.08),
                // The scan beam.
                Container(
                  height: size * 0.08,
                  margin: EdgeInsets.only(right: size * 0.2),
                  decoration: BoxDecoration(
                    gradient: _scanGradient,
                    borderRadius: BorderRadius.circular(size),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.7),
                        blurRadius: size * 0.35,
                      ),
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

/// Three tapering motion lines, like the bike is moving fast.
class _SpeedStreaks extends StatelessWidget {
  const _SpeedStreaks({required this.size, required this.onDark});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : AppColors.ink;
    Widget streak(double widthFactor, double alpha) => Container(
      width: size * widthFactor,
      height: size * 0.09,
      margin: EdgeInsets.symmetric(vertical: size * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            AppColors.orange.withValues(alpha: alpha),
          ],
        ),
      ),
    );
    // Slanted to match the italic lettering.
    return Transform(
      transform: Matrix4.skewX(-0.2),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [streak(0.55, 0.6), streak(0.85, 1), streak(0.4, 0.45)],
      ),
    );
  }
}
