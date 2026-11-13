import 'package:flutter/material.dart';

import '../data/shop_store.dart';
import '../data/accessories_maintenance_catalog.dart';
import '../data/parts_catalog.dart';
import '../models/catalog_product.dart';
import '../theme/app_theme.dart';
import '../widgets/buy_options_button.dart';
import 'motorcycle_parts_catalog_page.dart';

class PartsCatalogPage extends StatefulWidget {
  const PartsCatalogPage({
    required this.categoryId,
    this.shopStore,
    this.onOwnerSignIn,
    super.key,
  });

  final String categoryId;
  final ShopStore? shopStore;
  final VoidCallback? onOwnerSignIn;

  @override
  State<PartsCatalogPage> createState() => _PartsCatalogPageState();
}

class _PartsCatalogPageState extends State<PartsCatalogPage> {
  late final _shopStore = widget.shopStore ?? ShopStore.shared;
  String? _expandedProductId;

  List<CatalogProduct> get _categoryProducts => catalogProducts
      .where(
        (product) =>
            product.categoryId == widget.categoryId &&
            !isMaintenanceOwnedCatalogProduct(product.name),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final categoryName = categoryNames[widget.categoryId] ?? 'Parts';
    final products = _categoryProducts;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to part groups',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('$categoryName products'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            '${products.length} catalog ${products.length == 1 ? 'entry' : 'entries'}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const _EmptyCategory()
          else
            ...products.map(
              (product) => _ProductCard(
                product: product,
                shopStore: _shopStore,
                onOwnerSignIn: widget.onOwnerSignIn,
                expanded: _expandedProductId == product.id,
                onToggle: () => setState(() {
                  _expandedProductId = _expandedProductId == product.id
                      ? null
                      : product.id;
                }),
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Motorcycle parts categories',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Browse the supplied parts list by category.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 9),
          Card(
            color: AppColors.surface,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: AppColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (index, category)
                    in _motorcyclePartCategories.indexed)
                  Column(
                    children: [
                      ListTile(
                        key: ValueKey('motorcycle-parts-category-$category'),
                        leading: const Icon(
                          Icons.build_outlined,
                          color: AppColors.teal,
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.teal,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MotorcyclePartsCatalogPage(
                              initialCategory: category,
                              shopStore: _shopStore,
                              onOwnerSignIn: widget.onOwnerSignIn,
                            ),
                          ),
                        ),
                      ),
                      if (index < _motorcyclePartCategories.length - 1)
                        const Divider(height: 1, indent: 54),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Catalog entries are starter records. Check product specifications and availability with the seller.',
            style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  static const _motorcyclePartCategories = [
    'Engine',
    'Electrical',
    'Suspension',
    'Wheels & Tires',
    'Body',
  ];
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.shopStore,
    required this.onOwnerSignIn,
    required this.expanded,
    required this.onToggle,
  });

  final CatalogProduct product;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onToggle,
            leading: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(product.icon, color: AppColors.teal),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              product.code,
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
            trailing: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.teal,
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DetailLabel('DESCRIPTION'),
                  const SizedBox(height: 5),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BuyOptionsButton(
                    store: shopStore,
                    productQuery: product.sellerQuery,
                    onOwnerSignIn: onOwnerSignIn,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 30, color: AppColors.faint),
          SizedBox(height: 10),
          Text(
            'No catalog entries in this group yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
