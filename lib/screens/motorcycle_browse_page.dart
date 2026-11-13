import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/vehicle_variant_carousel.dart';

class MotorcycleBrowsePage extends StatelessWidget {
  const MotorcycleBrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to home',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Motorcycle gallery'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: const [VehicleVariantCarousel()],
            ),
          ),
        ),
      ),
    );
  }
}
