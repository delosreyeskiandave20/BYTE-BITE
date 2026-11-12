import 'package:flutter/material.dart';

import '../data/accessories_maintenance_catalog.dart';
import '../data/parts_catalog.dart';
import '../data/shop_store.dart';
import '../models/catalog_product.dart';
import '../theme/app_theme.dart';
import '../widgets/buy_options_button.dart';
import 'shop_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    this.shopStore,
    this.onOwnerSignIn,
    this.onOpenShop,
    super.key,
  });

  final ShopStore? shopStore;
  final VoidCallback? onOwnerSignIn;

  /// Switches the app shell to the Shop tab. Used by "View all in Shop".
  final VoidCallback? onOpenShop;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final _shopStore = widget.shopStore ?? ShopStore.shared;
  static const _maxShopMatches = 20;
  static const _filters = [
    ('All parts', null),
    ('Engine', 'engine'),
    ('Brakes', 'brakes'),
    ('Electrical', 'electrical'),
    ('Body', 'body'),
  ];

  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  String? _expandedProductId;

  List<CatalogProduct> get _results {
    final query = _query.trim().toLowerCase();
    return catalogProducts.where((product) {
      if (isMaintenanceOwnedCatalogProduct(product.name)) return false;
      final matchesCategory =
          _selectedCategory == null || product.categoryId == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          [
            product.name,
            product.code,
            categoryNames[product.categoryId] ?? '',
            product.description,
          ].join(' ').toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// In-stock products from every shop, matched with the same token-prefix
  /// rules as the library. Rebuilt whenever [ShopStore] notifies, so a product
  /// added or edited by an owner shows up without reopening this screen.
  List<_ShopMatch> get _shopMatches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const <_ShopMatch>[];
    final queryTokens = _searchTokens(query);
    if (queryTokens.isEmpty) return const <_ShopMatch>[];

    final matches = <_ShopMatch>[];
    for (final shop in _shopStore.shops) {
      for (final product in shop.products) {
        if (!product.isAvailable) continue;
        final productTokens = _searchTokens(
          [
            product.name,
            product.category,
            product.description,
            shop.name,
            shop.location,
          ].join(' '),
        );
        final matchesQuery = queryTokens.every(
          (token) => productTokens.any((word) => word.startsWith(token)),
        );
        if (matchesQuery) {
          matches.add(_ShopMatch(shop: shop, product: product));
        }
      }
    }

    matches.sort((a, b) {
      final aName = a.product.name.toLowerCase();
      final bName = b.product.name.toLowerCase();
      final aStarts = aName.startsWith(query) ? 0 : 1;
      final bStarts = bName.startsWith(query) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      final price = a.product.price.compareTo(b.product.price);
      if (price != 0) return price;
      return aName.compareTo(bName);
    });

    return matches.take(_maxShopMatches).toList(growable: false);
  }

  static List<String> _searchTokens(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);

  void _openShop(_ShopMatch match) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopPage(
          store: _shopStore,
          onOwnerSignIn: widget.onOwnerSignIn,
          initialProductQuery: match.product.name,
          initialShopName: match.shop.name,
        ),
      ),
    );
  }

  void _openShopTab() {
    final openShop = widget.onOpenShop;
    if (openShop != null) {
      openShop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Search parts')),
      body: ListenableBuilder(
        listenable: _shopStore,
        builder: (context, _) {
          final results = _results;
          final shopMatches = _shopMatches;
          final hasQuery = _query.trim().isNotEmpty;
          final hasResults = results.isNotEmpty || shopMatches.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const Text(
                'MOTOSCAN / LIBRARY',
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Search parts',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: AppType.display,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search the parts library, or live shop listings by part name, '
                'category, shop, or part number.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {
                  _query = value;
                  _expandedProductId = null;
                }),
                decoration: InputDecoration(
                  hintText: 'Try "brake", "MS-BRK", or a shop name',
                  prefixIcon: const Icon(Icons.search, color: AppColors.teal),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                              _expandedProductId = null;
                            });
                          },
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
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final selected = _selectedCategory == filter.$2;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.$1),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedCategory = filter.$2;
                          _expandedProductId = null;
                        }),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.tealBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.teal, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Parts library entries are sample data. Shop listings '
                        'come from local sellers — confirm details before buying.',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasQuery && _shopStore.isLoading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppColors.teal,
                  backgroundColor: AppColors.tealSoft,
                ),
              ],
              if (hasQuery && _shopStore.lastErrorMessage != null) ...[
                const SizedBox(height: 12),
                _ShopSearchNotice(
                  message: _shopStore.lastErrorMessage!,
                  onRetry: _shopStore.retry,
                ),
              ],
              const SizedBox(height: 18),
              if (!hasResults)
                _EmptySearch(query: _query)
              else ...[
                if (results.isNotEmpty) ...[
                  _SearchSectionHeader(
                    title: 'Parts library',
                    trailing: '${results.length} matches',
                  ),
                  const SizedBox(height: 10),
                  ...results.map(
                    (product) => _SearchResultCard(
                      product: product,
                      shopStore: _shopStore,
                      onOwnerSignIn: widget.onOwnerSignIn,
                      expanded: _expandedProductId == product.id,
                      onTap: () => setState(() {
                        _expandedProductId = _expandedProductId == product.id
                            ? null
                            : product.id;
                      }),
                    ),
                  ),
                ],
                if (shopMatches.isNotEmpty) ...[
                  if (results.isNotEmpty) const SizedBox(height: 18),
                  _SearchSectionHeader(
                    title: 'Shop listings',
                    trailing: '${shopMatches.length} in stock',
                  ),
                  const SizedBox(height: 10),
                  ...shopMatches.map(
                    (match) => _ShopListingCard(
                      key: ValueKey(
                        'search-shop-${match.shop.id}-${match.product.id}',
                      ),
                      match: match,
                      onTap: () => _openShop(match),
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: _openShopTab,
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('View all in Shop'),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ShopMatch {
  const _ShopMatch({required this.shop, required this.product});

  final Shop shop;
  final ShopProduct product;
}

class _SearchSectionHeader extends StatelessWidget {
  const _SearchSectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            trailing,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopSearchNotice extends StatelessWidget {
  const _ShopSearchNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Shop listings could not load. $message',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.product,
    required this.shopStore,
    required this.onOwnerSignIn,
    required this.expanded,
    required this.onTap,
  });

  final CatalogProduct product;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: expanded ? AppColors.teal : AppColors.line,
          width: expanded ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(product.icon, color: AppColors.teal),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${categoryNames[product.categoryId]} · ${product.code}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: expanded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                product.description,
                                style: const TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 11,
                                  height: 1.45,
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 8),
                      BuyOptionsButton(
                        store: shopStore,
                        productQuery: product.sellerQuery,
                        onOwnerSignIn: onOwnerSignIn,
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: const Icon(Icons.expand_more, color: AppColors.teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopListingCard extends StatelessWidget {
  const _ShopListingCard({required this.match, required this.onTap, super.key});

  final _ShopMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = match.product;
    final shop = match.shop;
    final lowStock = product.quantity <= 5;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShopProductThumb(product: product),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shop.location.isEmpty
                          ? shop.name
                          : '${shop.name} · ${shop.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: AppType.caption,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '₱${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _StockChip(
                          label: lowStock
                              ? '${product.quantity} left'
                              : 'In stock',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.teal),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopProductThumb extends StatelessWidget {
  const _ShopProductThumb({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.teal,
        size: 24,
      ),
    );

    if (!product.hasImage) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        product.imageUrl,
        width: 52,
        height: 52,
        cacheWidth: 104,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 30, color: AppColors.faint),
          const SizedBox(height: 10),
          Text(
            trimmed.isEmpty
                ? 'Start typing to search'
                : 'No matching records yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            trimmed.isEmpty
                ? 'Search the parts library or live shop listings.'
                : 'Try a broader part name, a shop name, or another category. '
                      'Only in-stock shop items are listed.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: AppType.caption,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
