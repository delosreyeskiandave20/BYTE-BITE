import 'package:flutter/material.dart';

import 'accessories_maintenance_catalog.dart';
import '../models/part_category.dart';

final homeCategories = [
  PartCategory(
    id: 'engine',
    name: 'Engine',
    subtitle: 'Power & performance',
    count: '38 parts',
    imageAsset: 'assets/parts/engine-showcase.png',
    icon: Icons.settings,
    color: Color(0xFFD7642A),
  ),
  PartCategory(
    id: 'electrical',
    name: 'Electrical',
    subtitle: 'Wiring & charge',
    count: '31 parts',
    imageAsset: 'assets/parts/electrical-showcase.png',
    icon: Icons.bolt,
    color: Color(0xFFA46A1F),
  ),
  PartCategory(
    id: 'suspension',
    name: 'Suspension',
    subtitle: 'Smooth the ride',
    count: '19 parts',
    imageAsset: 'assets/parts/suspension-showcase.png',
    icon: Icons.unfold_more,
    color: Color(0xFF5A6370),
  ),
  PartCategory(
    id: 'wheels',
    name: 'Wheels & tires',
    subtitle: 'Grip & roll',
    count: '16 parts',
    imageAsset: 'assets/parts/wheels-showcase.png',
    icon: Icons.tire_repair,
    color: Color(0xFF85596D),
  ),
  PartCategory(
    id: 'body',
    name: 'Body parts',
    subtitle: 'Panels & protection',
    count: '27 parts',
    imageAsset: 'assets/parts/body-showcase.png',
    icon: Icons.directions_car,
    color: Color(0xFF4B6791),
  ),
  PartCategory(
    id: 'accessories',
    name: 'Accessories',
    subtitle: 'Upgrade your ride',
    count: '$accessoryItemCount items',
    imageAsset: 'assets/parts/accessories-showcase.png',
    icon: Icons.extension,
    color: Color(0xFF277C78),
  ),
  PartCategory(
    id: 'maintenance',
    name: 'Maintenance',
    subtitle: 'Keep it road-ready',
    count: '$maintenanceItemCount items',
    imageAsset: 'assets/parts/maintenance-showcase.png',
    icon: Icons.build,
    color: Color(0xFF7A6043),
  ),
];
