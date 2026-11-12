import 'package:flutter/material.dart';

class PartCategory {
  const PartCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.count,
    required this.imageAsset,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final String subtitle;
  final String count;
  final String imageAsset;
  final IconData icon;
  final Color color;
}
