import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VehicleLookupCard extends StatelessWidget {
  const VehicleLookupCard({required this.onViewMotorcycles, super.key});

  final VoidCallback onViewMotorcycles;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final minHeight = viewportWidth < 340
        ? 360.0
        : viewportWidth < 420
        ? 292.0
        : 238.0;

    // The hero is content-driven above a minimum height, so the overlay copy
    // reflows instead of clipping when the user increases text size.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/motoscan-new-front-page.png',
                cacheWidth: 1200,
                fit: BoxFit.cover,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xE6151B1A),
                      Color(0x9C151B1A),
                      Color(0x04151B1A),
                    ],
                    stops: [0, 0.58, 1],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Color(0x66151B1A), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(17),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR MOTORCYCLE PARTS GUIDE',
                      style: TextStyle(
                        color: Color(0xFFA8DDD4),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.15,
                      ),
                    ),
                    const SizedBox(height: 44),
                    const Text(
                      'Ride ready.\nPart certain.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 0.98,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find components, compare options, and get back on the road.',
                      style: TextStyle(
                        color: Color(0xFFE5EEEA),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: onViewMotorcycles,
                        icon: const Icon(Icons.two_wheeler, size: 17),
                        label: const Text('View motorcycles'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
