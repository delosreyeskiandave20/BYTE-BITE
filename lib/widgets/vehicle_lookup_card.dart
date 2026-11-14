import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact Home card that sends riders to the motorcycle picker.
///
/// The welcome page already shows the full brand photo, so Home uses a small
/// cropped strip of it and leads with the action instead of a slogan.
class VehicleLookupCard extends StatelessWidget {
  const VehicleLookupCard({required this.onViewMotorcycles, super.key});

  final VoidCallback onViewMotorcycles;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewMotorcycles,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 150,
              child: ShaderMask(
                // Fade the photo into the card so the text side stays solid.
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0, 0.55],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/motoscan-new-front-page.png',
                  cacheWidth: 400,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.2, 0.3),
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                110,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find parts for your motorcycle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppType.section,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Pick your brand and model to see the parts it uses.',
                    style: TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: AppType.caption + 1,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: onViewMotorcycles,
                    icon: const Icon(Icons.two_wheeler, size: 18),
                    label: const Text('View motorcycles'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(0, 44),
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
}
