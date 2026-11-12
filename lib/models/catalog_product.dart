import 'package:flutter/material.dart';

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.code,
    required this.icon,
    required this.sellerQuery,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String code;
  final IconData icon;
  final String sellerQuery;
}
