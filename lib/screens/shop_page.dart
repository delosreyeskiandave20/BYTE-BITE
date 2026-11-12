import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({
    required this.store,
    this.onOwnerSignIn,
    this.initialProductQuery,
    this.initialShopName,
    super.key,
  });

  final ShopStore store;
  final VoidCallback? onOwnerSignIn;
  final String? initialProductQuery;
  final String? initialShopName;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String _selectedCategory = 'All';
  late final TextEditingController _searchController;
  late String _searchQuery;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialProductQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _openMarketplace(String marketplace) async {
    final uri = switch (marketplace) {
      'Shopee' => Uri.https('shopee.ph', '/search', {
        'keyword': 'motorcycle parts',
      }),
      'Lazada' => Uri.https('www.lazada.com.ph', '/catalog/', {
        'q': 'motorcycle parts',
      }),
      _ => throw ArgumentError.value(marketplace, 'marketplace'),
    };
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $marketplace.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text(
          'MotoScan Shop',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900),
        ),
        actions: widget.onOwnerSignIn == null
            ? null
            : [
                IconButton(
                  tooltip: 'Manage your shop',
                  onPressed: widget.onOwnerSignIn,
                  icon: const Icon(Icons.person_outline),
                ),
              ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            if (widget.store.isLoading && widget.store.shops.isEmpty) {
              return const _ShopStatus(
                key: ValueKey('shop-loading'),
                icon: Icons.storefront_outlined,
                message: 'Loading shops…',
                showProgress: true,
              );
            }

            final error = widget.store.lastErrorMessage;
            if (error != null && widget.store.shops.isEmpty) {
              return _ShopStatus(
                key: const ValueKey('shop-error'),
                icon: Icons.cloud_off_outlined,
                title: 'Could not load shops',
                message: error,
                actionLabel: 'Retry',
                onAction: widget.store.retry,
              );
            }

            return RefreshIndicator(
              color: AppColors.teal,
              onRefresh: () {
                widget.store.retry();
                return Future<void>.value();
              },
              child: _ShopContent(
                key: const ValueKey('shop-content'),
                store: widget.store,
                query: widget.initialProductQuery,
                initialShopName: widget.initialShopName,
                selectedCategory: _selectedCategory,
                searchQuery: _searchQuery,
                searchController: _searchController,
                onSearchChanged: (value) =>
                    setState(() => _searchQuery = value),
                onClearSearch: _clearSearch,
                onCategorySelected: (category) =>
                    setState(() => _selectedCategory = category),
                onOpenMarketplace: _openMarketplace,
                error: error,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShopContent extends StatelessWidget {
  const _ShopContent({
    required this.store,
    required this.query,
    required this.initialShopName,
    required this.selectedCategory,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCategorySelected,
    required this.onOpenMarketplace,
    this.error,
    super.key,
  });

  final ShopStore store;
  final String? query;
  final String? initialShopName;
  final String selectedCategory;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onOpenMarketplace;
  final String? error;

  static List<String> _tokens(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);

  static bool _matches(Shop shop, ShopProduct product, List<String> tokens) {
    final words = _tokens(
      [
        product.name,
        product.category,
        product.description,
        shop.name,
        shop.location,
      ].join(' '),
    );
    return tokens.every((token) => words.any((word) => word.startsWith(token)));
  }

  @override
  Widget build(BuildContext context) {
    final filterTokens = _tokens(searchQuery.trim());
    final shops = store.shops
        .where(
          (shop) => initialShopName == null || shop.name == initialShopName,
        )
        .map((shop) {
          final base = query == null
              ? shop.products
              : availableProductsForQuery(shop, query!);
          final filtered = filterTokens.isEmpty
              ? base
              : base
                    .where((product) => _matches(shop, product, filterTokens))
                    .toList(growable: false);
          // In-stock products lead each shop; unavailable items stay visible so
          // shoppers can still see what the shop carries.
          final ordered = [
            ...filtered.where((product) => product.isAvailable),
            ...filtered.where((product) => !product.isAvailable),
          ];
          return (shop: shop, products: ordered);
        })
        .where(
          (entry) =>
              entry.products.isNotEmpty ||
              (query == null && filterTokens.isEmpty),
        )
        .toList(growable: false);
    final categories = <String>{
      'All',
      for (final entry in shops)
        for (final product in entry.products) product.category,
    };
    final visibleCategories = categories.contains(selectedCategory)
        ? categories
        : {'All', ...categories.where((item) => item != 'All')};
    final productCount = shops.fold<int>(
      0,
      (count, entry) => count + entry.products.length,
    );
    final activeQuery = searchQuery.trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (error != null) ...[
          _ShopErrorBanner(message: error!, onRetry: store.retry),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search shops, parts, or locations',
            prefixIcon: const Icon(Icons.search, color: AppColors.teal),
            suffixIcon: searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear shop search',
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.lineStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.lineStrong),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (query == null) ...[
          Row(
            children: [
              Expanded(
                child: _MarketplaceCard(
                  name: 'Shopee',
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => onOpenMarketplace('Shopee'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MarketplaceCard(
                  name: 'Lazada',
                  icon: Icons.local_mall_outlined,
                  onTap: () => onOpenMarketplace('Lazada'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
        _SectionHeading(
          title: activeQuery.isEmpty
              ? 'Available shops'
              : 'Available shops for $activeQuery',
          subtitle: shops.isEmpty
              ? 'No live listings yet'
              : '${shops.length} ${shops.length == 1 ? 'shop' : 'shops'} · '
                    '$productCount ${productCount == 1 ? 'product' : 'products'}',
        ),
        const SizedBox(height: 10),
        if (shops.isEmpty)
          FadeSlideIn(
            key: const ValueKey('shop-empty'),
            child: _EmptyShops(
              query: activeQuery,
              onClear: onClearSearch,
              message: query == null
                  ? null
                  : 'No matching in-stock shop listings were found.',
            ),
          )
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: visibleCategories.map((category) {
                final selected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => onCategorySelected(category),
                    selectedColor: AppColors.tealSoft,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: selected ? AppColors.teal : AppColors.line,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.teal : AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          ...shops.map((entry) {
            final products = selectedCategory == 'All'
                ? entry.products
                : entry.products
                      .where((product) => product.category == selectedCategory)
                      .toList();
            if (selectedCategory != 'All' && products.isEmpty) {
              return const SizedBox.shrink();
            }
            return FadeSlideIn(
              key: ValueKey('shop-card-${entry.shop.id}'),
              child: _ShopCard(shop: entry.shop, products: products),
            );
          }),
        ],
      ],
    );
  }
}

class _ShopErrorBanner extends StatelessWidget {
  const _ShopErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.danger,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Live shop data is unavailable: $message',
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ShopStatus extends StatelessWidget {
  const _ShopStatus({
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.teal, size: 34),
                const SizedBox(height: 12),
                if (title != null) ...[
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (showProgress) ...[
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  const _MarketplaceCard({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.teal, size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Marketplace',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 15, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop, required this.products});

  final Shop shop;
  final List<ShopProduct> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shop.location,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (shop.description.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              shop.description,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const Divider(height: 22),
          if (products.isEmpty)
            const Text(
              'No products listed yet.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ...products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductThumbnail(product: product),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          product.category,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.description.isEmpty
                              ? 'Product details not added yet.'
                              : product.description,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.price > 0
                            ? '₱${product.price.toStringAsFixed(2)}'
                            : 'Price not set',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.isAvailable
                            ? '${product.quantity} in stock'
                            : 'Unavailable',
                        style: TextStyle(
                          color: product.isAvailable
                              ? AppColors.teal
                              : AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    if (!product.hasImage) {
      return const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.teal,
        size: 19,
      );
    }
    return Semantics(
      label: 'Photo of ${product.name}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          product.imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 48,
            height: 48,
            color: AppColors.tealSoft,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.teal,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyShops extends StatelessWidget {
  const _EmptyShops({this.message, this.query = '', this.onClear});

  final String? message;
  final String query;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message ??
                (query.isEmpty
                    ? 'No shops yet. Shop owners can create a listing with the store icon above.'
                    : 'No shop listings match “$query”. Try a part name, shop, or location.'),
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          if (query.isNotEmpty && onClear != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 17),
              label: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }
}
