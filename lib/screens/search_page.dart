import 'package:flutter/material.dart';

import '../data/price_format.dart';
import '../data/accessories_maintenance_catalog.dart';
import '../data/catalog_images.dart';
import '../data/part_suggestions.dart';
import '../data/parts_catalog.dart';
import '../data/shop_store.dart';
import '../models/catalog_product.dart';
import '../theme/app_theme.dart';
import '../widgets/buy_options_button.dart';
import '../widgets/load_error_banner.dart';
import '../widgets/zoomable_image.dart';
import 'shop_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    this.shopStore,
    this.initialQuery,
    this.onOwnerSignIn,
    this.onOpenShop,
    super.key,
  });

  final ShopStore? shopStore;

  /// Pre-fills the search box, e.g. with a part the AI recognized.
  final String? initialQuery;
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

  static const _popularSearches = [
    'Brake',
    'Oil',
    'Tire',
    'Headlight',
    'Mirror',
    'Air filter',
  ];

  static IconData _filterIcon(String? category) => switch (category) {
    'engine' => Icons.settings_rounded,
    'brakes' => Icons.album_outlined,
    'electrical' => Icons.bolt_rounded,
    'body' => Icons.two_wheeler_rounded,
    _ => Icons.apps_rounded,
  };

  void _setQuery(String value) => setState(() {
    _query = value;
    _expandedProductId = null;
  });

  late final _searchController = TextEditingController(
    text: widget.initialQuery,
  );
  late String _query = widget.initialQuery ?? '';
  String? _selectedCategory;
  String? _expandedProductId;

  static final _allPartSuggestions = buildPartSuggestions();

  List<String> get _queryTokens => relevanceQueryTokens(_query.trim());

  List<CatalogProduct> get _results {
    final tokens = _queryTokens;
    final scored = <(CatalogProduct, int)>[];
    for (final product in catalogProducts) {
      if (isMaintenanceOwnedCatalogProduct(product.name)) continue;
      if (_selectedCategory != null &&
          product.categoryId != _selectedCategory) {
        continue;
      }
      final score = searchRelevance(
        tokens,
        name: product.name,
        details: [
          product.code,
          categoryNames[product.categoryId] ?? '',
          product.description,
        ].join(' '),
      );
      if (score > 0) scored.add((product, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final entry in scored) entry.$1];
  }

  /// Whether a catalog suggestion belongs under the selected filter chip.
  bool _suggestionMatchesFilter(PartSuggestion part) =>
      switch (_selectedCategory) {
        null => true,
        'engine' => part.category == 'Engine',
        'electrical' => part.category == 'Electrical',
        'body' => part.category == 'Body Parts',
        'brakes' => part.name.toLowerCase().contains('brake'),
        _ => false,
      };

  /// Every other part, accessory, maintenance item and design. With no query
  /// that is the whole catalog (for the selected filter), so riders can
  /// browse it; with a query, only names that relate to it, best first, so an
  /// AI match also shows similar options.
  List<PartSuggestion> get _relatedParts {
    final tokens = _queryTokens;
    final libraryNames = {
      for (final product in catalogProducts) product.name.toLowerCase(),
    };
    if (tokens.isEmpty) {
      return [
        for (final part in _allPartSuggestions)
          if (!libraryNames.contains(part.name.toLowerCase()) &&
              _suggestionMatchesFilter(part))
            part,
      ];
    }
    final scored = <(PartSuggestion, int)>[];
    for (final part in _allPartSuggestions) {
      if (libraryNames.contains(part.name.toLowerCase())) continue;
      if (!_suggestionMatchesFilter(part)) continue;
      final score = searchRelevance(
        tokens,
        name: part.name,
        details: part.category,
      );
      if (score > 0) scored.add((part, score));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      return a.$1.name.compareTo(b.$1.name);
    });
    return [for (final entry in scored) entry.$1];
  }

  /// With a query: every library item and catalog part that did NOT match it,
  /// so the matches come first and the rest of the catalog follows below.
  /// Empty without a query, where the whole catalog is already listed.
  (List<CatalogProduct>, List<PartSuggestion>) _remainingCatalog(
    List<CatalogProduct> results,
    List<PartSuggestion> relatedParts,
  ) {
    if (_query.trim().isEmpty) return (const [], const []);
    final matchedIds = {for (final product in results) product.id};
    final matchedNames = {
      for (final part in relatedParts) part.name.toLowerCase(),
    };
    final libraryNames = {
      for (final product in catalogProducts) product.name.toLowerCase(),
    };
    return (
      [
        for (final product in catalogProducts)
          if (!isMaintenanceOwnedCatalogProduct(product.name) &&
              (_selectedCategory == null ||
                  product.categoryId == _selectedCategory) &&
              !matchedIds.contains(product.id))
            product,
      ],
      [
        for (final part in _allPartSuggestions)
          if (!libraryNames.contains(part.name.toLowerCase()) &&
              _suggestionMatchesFilter(part) &&
              !matchedNames.contains(part.name.toLowerCase()))
            part,
      ],
    );
  }

  /// In-stock products from every shop, ranked like the library: listings
  /// matching every word first, then ones sharing a key word in their name.
  /// Rebuilt whenever [ShopStore] notifies, so a product added or edited by an
  /// owner shows up without reopening this screen.
  List<_ShopMatch> get _shopMatches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const <_ShopMatch>[];
    final queryTokens = searchTokens(query);
    if (queryTokens.isEmpty) return const <_ShopMatch>[];
    final relevanceTokens = _queryTokens;

    final matches = <_ShopMatch>[];
    for (final shop in _shopStore.shops) {
      for (final product in shop.products) {
        if (!product.isAvailable) continue;
        final score = shopProductMatchesTokens(shop, product, queryTokens)
            ? 2000
            : searchRelevance(
                relevanceTokens,
                name: '${product.name} ${product.category}',
              );
        if (score > 0) {
          matches.add(_ShopMatch(shop: shop, product: product, score: score));
        }
      }
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
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

  /// Short list of searches related to the current query, e.g. a part the AI
  /// recognized, shown under the search bar in place of popular searches.
  /// Built from the ranked catalog part names listed below, closest first;
  /// sellers' own listing names are left out because they make poor search
  /// terms ("Ceramic brake pad pro").
  List<String> _relatedSearches(
    List<CatalogProduct> results,
    List<PartSuggestion> relatedParts,
  ) {
    const maxSuggestions = 6;
    final query = _query.trim().toLowerCase();
    final seen = <String>{query};
    final suggestions = <String>[];
    void add(String name) {
      final trimmed = name.trim();
      if (trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) return;
      suggestions.add(trimmed);
    }

    for (final product in results) {
      add(product.name);
    }
    for (final part in relatedParts) {
      add(part.name);
    }
    return suggestions.take(maxSuggestions).toList(growable: false);
  }

  void _searchFor(String term) {
    _searchController.text = term;
    _setQuery(term);
  }

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

  /// Photo folder to prefer for a parts library category.
  static String _libraryImageCategory(String categoryId) =>
      switch (categoryId) {
        'design' => 'Designs',
        'maintenance' => 'Accessories',
        _ => 'Engine',
      };

  /// Bundled photos for the parts library and "More parts & accessories".
  PartImageIndex _partImages = PartImageIndex.empty;

  @override
  void initState() {
    super.initState();
    loadPartImageIndex().then((index) {
      if (mounted) setState(() => _partImages = index);
    }, onError: (_) {});
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
          final relatedParts = _relatedParts;
          final hasQuery = _query.trim().isNotEmpty;
          final hasResults =
              results.isNotEmpty ||
              shopMatches.isNotEmpty ||
              relatedParts.isNotEmpty;
          final (otherLibrary, otherParts) = _remainingCatalog(
            results,
            relatedParts,
          );
          final relatedSearches = hasQuery
              ? _relatedSearches(results, relatedParts)
              : const <String>[];

          Widget libraryCard(CatalogProduct product) => _SearchResultCard(
            key: ValueKey('search-library-${product.id}'),
            product: product,
            imageAsset: _partImages.lookup(
              product.name,
              _libraryImageCategory(product.categoryId),
            ),
            shopStore: _shopStore,
            onOwnerSignIn: widget.onOwnerSignIn,
            expanded: _expandedProductId == product.id,
            onTap: () => setState(() {
              _expandedProductId = _expandedProductId == product.id
                  ? null
                  : product.id;
            }),
          );
          Widget partCard(PartSuggestion part) => _RelatedPartCard(
            key: ValueKey('search-related-${part.name}'),
            part: part,
            imageAsset: _partImages.lookup(part.name, part.category),
            shopStore: _shopStore,
            onOwnerSignIn: widget.onOwnerSignIn,
            expanded: _expandedProductId == 'related:${part.name}',
            onTap: () => setState(() {
              final id = 'related:${part.name}';
              _expandedProductId = _expandedProductId == id ? null : id;
            }),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _setQuery,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    fontSize: AppType.cardTitle,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Part name, part number or shop',
                    hintStyle: const TextStyle(
                      color: AppColors.faint,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 17),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              _setQuery('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: _filters.map((filter) {
                    final selected = _selectedCategory == filter.$2;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          _filterIcon(filter.$2),
                          size: 16,
                          color: selected ? Colors.white : AppColors.primary,
                        ),
                        label: Text(filter.$1),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedCategory = filter.$2;
                          _expandedProductId = null;
                        }),
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: selected ? AppColors.primary : AppColors.line,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.inkSoft,
                          fontSize: AppType.caption,
                          fontWeight: FontWeight.w700,
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (!hasQuery) ...[
                const SizedBox(height: 16),
                const Text(
                  'Popular searches',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: AppType.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final term in _popularSearches)
                      _PopularSearch(
                        key: ValueKey('popular-$term'),
                        term: term,
                        onTap: () => _searchFor(term),
                      ),
                  ],
                ),
              ],
              if (relatedSearches.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Related to "${_query.trim()}"',
                  key: const ValueKey('related-searches-title'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: AppType.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final term in relatedSearches)
                      _PopularSearch(
                        key: ValueKey('related-search-$term'),
                        term: term,
                        onTap: () => _searchFor(term),
                      ),
                  ],
                ),
              ],
              if (hasQuery && _shopStore.isLoading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                ),
              ],
              if (hasQuery && _shopStore.lastErrorMessage != null) ...[
                const SizedBox(height: 12),
                LoadErrorBanner(
                  compact: true,
                  message:
                      'Shop listings could not load. '
                      '${_shopStore.lastErrorMessage}',
                  onRetry: _shopStore.retry,
                ),
              ],
              const SizedBox(height: 18),
              if (!hasResults)
                _EmptySearch(query: _query)
              else ...[
                if (shopMatches.isNotEmpty) ...[
                  _SearchSectionHeader(title: 'Shop listings'),
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
                if (results.isNotEmpty) ...[
                  if (shopMatches.isNotEmpty) const SizedBox(height: 18),
                  _SearchSectionHeader(title: 'Parts library'),
                  const SizedBox(height: 10),
                  ...results.map(libraryCard),
                ],
                if (relatedParts.isNotEmpty) ...[
                  // Browsing (no query): the full catalog continues the
                  // Parts library list instead of starting a new section.
                  if (hasQuery) ...[
                    if (shopMatches.isNotEmpty || results.isNotEmpty)
                      const SizedBox(height: 18),
                    _SearchSectionHeader(title: 'More parts & accessories'),
                    const SizedBox(height: 10),
                  ] else if (results.isEmpty) ...[
                    _SearchSectionHeader(title: 'Parts library'),
                    const SizedBox(height: 10),
                  ],
                  ...relatedParts.map(partCard),
                ],
              ],
              // Matches for the query come first; every other part and item
              // follows, so riders can keep browsing past the matches.
              if (otherLibrary.isNotEmpty || otherParts.isNotEmpty) ...[
                const SizedBox(height: 22),
                _SearchSectionHeader(
                  key: const ValueKey('search-all-other-items'),
                  title: 'All other parts & items',
                ),
                const SizedBox(height: 10),
                ...otherLibrary.map(libraryCard),
                ...otherParts.map(partCard),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ShopMatch {
  const _ShopMatch({
    required this.shop,
    required this.product,
    required this.score,
  });

  final Shop shop;
  final ShopProduct product;
  final int score;
}

/// A part, accessory, maintenance item or design from the full catalogs.
/// Tapping it shows where to buy it.
class _RelatedPartCard extends StatelessWidget {
  const _RelatedPartCard({
    required this.part,
    required this.shopStore,
    required this.onOwnerSignIn,
    required this.expanded,
    required this.onTap,
    this.imageAsset,
    super.key,
  });

  final PartSuggestion part;

  /// Bundled photo of the part; the category icon is shown when missing.
  final String? imageAsset;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;
  final bool expanded;
  final VoidCallback onTap;

  static IconData _icon(String category) => switch (category) {
    'Engine' => Icons.settings_rounded,
    'Electrical' => Icons.bolt_rounded,
    'Suspension' => Icons.height_rounded,
    'Wheels and Tires' => Icons.tire_repair_rounded,
    'Body Parts' => Icons.two_wheeler_rounded,
    'Accessories' => Icons.sports_motorsports_outlined,
    'Maintenance' => Icons.build_outlined,
    'Designs' => Icons.palette_outlined,
    _ => Icons.inventory_2_outlined,
  };

  static const _thumbSize = 56.0;

  Widget _thumbnail() {
    final iconBox = Container(
      width: _thumbSize,
      height: _thumbSize,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_icon(part.category), color: AppColors.primary, size: 24),
    );
    final asset = imageAsset;
    if (asset == null) return iconBox;
    return ZoomableImage(
      imageAsset: asset,
      title: part.name,
      child: Container(
        width: _thumbSize,
        height: _thumbSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          asset,
          key: ValueKey('search-related-image-${part.name}'),
          fit: BoxFit.cover,
          cacheWidth: 168,
          semanticLabel: part.name,
          errorBuilder: (context, error, stackTrace) => iconBox,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: expanded ? AppColors.primary : AppColors.line,
          width: expanded ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _thumbnail(),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          part.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _Tag(
                          text: part.category,
                          color: AppColors.primary,
                          background: AppColors.primarySoft,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.inkSoft,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 10),
                BuyOptionsButton(
                  store: shopStore,
                  productQuery: part.name,
                  onOwnerSignIn: onOwnerSignIn,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  const _SearchSectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// A tappable suggestion shown before the rider types anything.
class _PopularSearch extends StatelessWidget {
  const _PopularSearch({required this.term, required this.onTap, super.key});

  final String term;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.noticeSoft,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 15,
                color: AppColors.muted,
              ),
              const SizedBox(width: 5),
              Text(
                term,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: AppType.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
    this.imageAsset,
    super.key,
  });

  final CatalogProduct product;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;
  final bool expanded;
  final VoidCallback onTap;

  /// Bundled photo of the part; the gradient icon is shown when missing.
  final String? imageAsset;

  Widget _thumbnail() {
    final iconBox = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(product.icon, color: Colors.white, size: 24),
    );
    final asset = imageAsset;
    if (asset == null) return iconBox;
    return ZoomableImage(
      imageAsset: asset,
      title: product.name,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          asset,
          key: ValueKey('search-library-image-${product.id}'),
          fit: BoxFit.cover,
          cacheWidth: 168,
          semanticLabel: product.name,
          errorBuilder: (context, error, stackTrace) => iconBox,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      elevation: expanded ? 3 : 0,
      shadowColor: const Color(0x33B8400F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: expanded ? AppColors.primary : AppColors.line,
          width: expanded ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: AppType.cardTitle,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Tag(
                          text: categoryNames[product.categoryId] ?? '',
                          color: AppColors.primary,
                          background: AppColors.primarySoft,
                        ),
                        _Tag(
                          text: product.code,
                          color: AppColors.muted,
                          background: AppColors.noticeSoft,
                          mono: true,
                        ),
                      ],
                    ),
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
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: expanded ? AppColors.primary : AppColors.noticeSoft,
                  shape: BoxShape.circle,
                ),
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: expanded ? Colors.white : AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.color,
    required this.background,
    this.mono = false,
  });

  final String text;
  final Color color;
  final Color background;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          fontFamily: mono ? 'monospace' : null,
          letterSpacing: mono ? 0.3 : 0,
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
                          formatPeso(product.price),
                          style: const TextStyle(
                            color: AppColors.primary,
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
              const Icon(Icons.chevron_right, color: AppColors.primary),
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
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primary,
        size: 24,
      ),
    );

    if (!product.hasImage) return fallback;

    return ZoomableImage.provider(
      image: product.imageProvider,
      title: product.name,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image(
          image: ResizeImage(product.imageProvider, width: 104),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
        ),
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
