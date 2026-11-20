import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/item_parts.dart';
import '../data/item_specs.dart';
import '../data/marketplace.dart';
import '../data/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/marketplace_logo.dart';
import '../widgets/motoscan_wordmark.dart';
import '../data/my_motorcycle.dart';
import '../widgets/shop_item_card.dart';
import 'online_store_page.dart';
import 'chat_pages.dart';
import 'shop_browse_pages.dart';
import 'shop_item_page.dart';

/// Pseudo-category that shows every product in a shop.
const _allCategories = 'All';

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
  static const _marketplaceQuery = 'motorcycle parts';

  String _selectedCategory = _allCategories;
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

  /// Opens [shop] on its own full-screen page with all of its items.
  void _visitShop(Shop shop) => openShopBrowsePage(context, widget.store, shop);

  void _openShopList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopListPage(store: widget.store),
      ),
    );
  }

  Future<void> _openMarketplace(String marketplace) async {
    final uri = Marketplaces.searchUri(marketplace, _marketplaceQuery);
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
        title: Semantics(
          label: 'MotoScan Shop',
          header: true,
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MotoScanWordmark(size: 21),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SHOP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('open-my-messages'),
            tooltip: 'My messages',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ChatInboxPage(openItem: chatItemOpenerFor(widget.store)),
              ),
            ),
            icon: const ChatUnreadIcon(),
          ),
          if (widget.onOwnerSignIn != null)
            IconButton(
              tooltip: 'Manage your shop',
              onPressed: widget.onOwnerSignIn,
              icon: const Icon(Icons.person_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.store, myMotorcycle]),
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
              color: AppColors.primary,
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
                onVisitShop: _visitShop,
                onOpenShopList: _openShopList,
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
    required this.onVisitShop,
    required this.onOpenShopList,
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

  /// Opens one shop on its own page.
  final ValueChanged<Shop> onVisitShop;
  final VoidCallback onOpenShopList;
  final String? error;

  @override
  Widget build(BuildContext context) {
    // Opened for a part ("12-V battery"): its related listings are already
    // picked below, so the same text in the search box must not filter them
    // again word by word. Typing something else filters as usual.
    final searchingThePart =
        query != null && searchQuery.trim() == query!.trim();
    final filterTokens = searchingThePart
        ? const <String>[]
        : searchTokens(searchQuery.trim());
    final mine = myMotorcycle.model;
    final onlyFits = myMotorcycle.onlyFits;
    final shops = store.shops
        .where(
          (shop) =>
              // Approved Shopee/Lazada sellers are listed with the online
              // stores below instead.
              shop.liveMarketplaceLink == null &&
              (initialShopName == null || shop.name == initialShopName),
        )
        .map((shop) {
          final base = query == null
              ? shop.products
              : availableProductsForQuery(shop, query!);
          final filtered = base
              .where(
                (product) =>
                    (filterTokens.isEmpty ||
                        shopProductMatchesTokens(
                          shop,
                          product,
                          filterTokens,
                        )) &&
                    // Universal items always count as a match.
                    (!onlyFits || product.fits(mine!)),
              )
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
              (query == null && filterTokens.isEmpty && !onlyFits),
        )
        .toList(growable: false);
    // On a single shop's own page there is nothing else to visit.
    final canVisit = initialShopName == null;
    final categories = <String>{
      _allCategories,
      for (final entry in shops)
        for (final product in entry.products) product.category,
    };
    final visibleCategories = categories.contains(selectedCategory)
        ? categories
        : {
            _allCategories,
            ...categories.where((item) => item != _allCategories),
          };
    final productCount = shops.fold<int>(
      0,
      (count, entry) => count + entry.products.length,
    );
    final activeQuery = searchQuery.trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search shops, parts, or locations',
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
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
        const SizedBox(height: 12),
        const _MyMotorcycleBar(),
        const SizedBox(height: 20),
        _SectionHeading(
          title: !canVisit
              ? (activeQuery.isEmpty
                    ? 'All parts in this shop'
                    : 'Parts in this shop for $activeQuery')
              : activeQuery.isEmpty
              ? 'Available shops'
              : 'Available shops for $activeQuery',
          subtitle: shops.isEmpty
              ? 'No live listings yet'
              : '${shops.length} ${shops.length == 1 ? 'shop' : 'shops'} · '
                    '$productCount ${productCount == 1 ? 'product' : 'products'}',
        ),
        const SizedBox(height: 10),
        if (canVisit && shops.length > 1) ...[
          _ShopPicker(
            shops: [for (final entry in shops) entry.shop],
            onVisitShop: onVisitShop,
            onSeeAll: onOpenShopList,
          ),
          const SizedBox(height: 10),
        ],
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
                    selectedColor: AppColors.primarySoft,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.line,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.muted,
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
            final products = selectedCategory == _allCategories
                ? entry.products
                : entry.products
                      .where((product) => product.category == selectedCategory)
                      .toList();
            if (selectedCategory != _allCategories && products.isEmpty) {
              return const SizedBox.shrink();
            }
            return FadeSlideIn(
              key: ValueKey('shop-card-${entry.shop.id}'),
              child: _ShopCard(
                shop: entry.shop,
                products: products,
                myMotorcycle: mine,
                onVisit: canVisit ? () => onVisitShop(entry.shop) : null,
              ),
            );
          }),
        ],
        // Local shops are the point of MotoScan, so online marketplaces come
        // after them as a fallback. A single shop's own page skips them.
        if (canVisit) ...[
          const SizedBox(height: 22),
          OnlineStoresSection(
            searchQuery: activeQuery,
            sellerStores: [
              for (final shop in store.shops) ?onlineStoreForShop(shop),
            ],
          ),
        ],
        if (canVisit && query == null) ...[
          const SizedBox(height: 22),
          const _SectionHeading(
            title: 'Shop online',
            subtitle: 'Not near a shop? Search these marketplaces.',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MarketplaceLogoButton(
                  marketplace: Marketplaces.shopee,
                  onPressed: () => onOpenMarketplace(Marketplaces.shopee),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MarketplaceLogoButton(
                  marketplace: Marketplaces.lazada,
                  onPressed: () => onOpenMarketplace(Marketplaces.lazada),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "My Motorcycle": the buyer picks their motorcycle once, then can show
/// only the parts that fit it.
class _MyMotorcycleBar extends StatelessWidget {
  const _MyMotorcycleBar();

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _MyMotorcyclePicker(),
    );
    if (picked == null) return;
    await myMotorcycle.choose(picked.isEmpty ? null : picked);
  }

  // The bar is a const widget, so a rebuild of the page above does not
  // rebuild it; it listens to [myMotorcycle] itself so the switch and the
  // chosen model update as soon as they change.
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: myMotorcycle, builder: _buildBar);

  Widget _buildBar(BuildContext context, Widget? _) {
    final model = myMotorcycle.model;
    return Material(
      key: const ValueKey('my-motorcycle-bar'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.two_wheeler, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    model == null
                        ? 'Set your motorcycle to find parts that fit'
                        : 'My motorcycle: ${motorcycleModel(model)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  key: const ValueKey('my-motorcycle-pick'),
                  onPressed: () => _pick(context),
                  child: Text(model == null ? 'Choose' : 'Change'),
                ),
              ],
            ),
            if (model != null)
              SwitchListTile(
                key: const ValueKey('my-motorcycle-only-fits'),
                dense: true,
                contentPadding: const EdgeInsets.only(left: 2, right: 8),
                value: myMotorcycle.onlyFits,
                title: Text(
                  'Show only parts that fit my ${motorcycleModel(model)}',
                ),
                onChanged: myMotorcycle.setOnlyFits,
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing the master-table motorcycles by brand. Pops the
/// chosen name, or '' to clear the choice.
class _MyMotorcyclePicker extends StatefulWidget {
  const _MyMotorcyclePicker();

  @override
  State<_MyMotorcyclePicker> createState() => _MyMotorcyclePickerState();
}

class _MyMotorcyclePickerState extends State<_MyMotorcyclePicker> {
  late final Future<List<ItemSpecRow>> _rows = loadItemSpecs();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'Which motorcycle do you ride?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const ValueKey('my-motorcycle-search'),
              decoration: const InputDecoration(
                hintText: 'Search motorcycle…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (text) => setState(() => _query = text),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ItemSpecRow>>(
              future: _rows,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load the motorcycle list.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final needle = _query.trim().toLowerCase();
                final current = myMotorcycle.model;
                return ListView(
                  children: [
                    if (current != null)
                      ListTile(
                        key: const ValueKey('my-motorcycle-clear'),
                        leading: const Icon(Icons.clear),
                        title: const Text('Clear my motorcycle'),
                        onTap: () => Navigator.of(context).pop(''),
                      ),
                    for (final brand in motorcyclesByBrand(
                      snapshot.data!,
                    ).entries)
                      if (brand.value.any(
                        (model) => model.toLowerCase().contains(needle),
                      )) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                          child: Text(
                            brand.key.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: AppType.caption,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        for (final model in brand.value)
                          if (model.toLowerCase().contains(needle))
                            ListTile(
                              key: ValueKey('my-motorcycle-$model'),
                              dense: true,
                              title: Text(model),
                              trailing: model == current
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(model),
                            ),
                      ],
                  ],
                );
              },
            ),
          ),
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
                Icon(icon, color: AppColors.primary, size: 34),
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

/// "Visit a shop": a quick row of shops; tapping one opens its own page.
class _ShopPicker extends StatelessWidget {
  const _ShopPicker({
    required this.shops,
    required this.onVisitShop,
    required this.onSeeAll,
  });

  final List<Shop> shops;
  final ValueChanged<Shop> onVisitShop;

  /// Opens the list of every shop.
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Visit a shop',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('shop-see-all'),
              onPressed: onSeeAll,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('See all shops'),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final shop in shops)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    key: ValueKey('visit-shop-${shop.id}'),
                    avatar: const Icon(
                      Icons.storefront_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(shop.name),
                    onPressed: () => onVisitShop(shop),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.line),
                    labelStyle: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.products,
    this.myMotorcycle,
    this.onVisit,
  });

  final Shop shop;
  final List<ShopProduct> products;
  final String? myMotorcycle;

  /// Opens this shop on its own page. Null hides the button.
  final VoidCallback? onVisit;

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
          // The whole header opens the shop; a small arrow marks it, so the
          // shop name keeps nearly the full width.
          InkWell(
            key: ValueKey('visit-header-${shop.id}'),
            onTap: onVisit,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                _ShopAvatar(shop: shop),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              shop.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onVisit != null) ...[
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    key: ValueKey('visit-button-${shop.id}'),
                    tooltip: 'Visit shop',
                    onPressed: onVisit,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  ),
                ],
              ],
            ),
          ),
          if (shop.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              shop.description,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const Divider(height: 24, color: AppColors.line),
          if (products.isEmpty)
            const Text(
              'No products listed yet.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          Builder(
            builder: (context) {
              Widget grid(List<ShopProduct> items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, product) in items.indexed)
                    Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
                      child: ShopItemCard(
                        product: product,
                        myMotorcycle: myMotorcycle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ShopItemPage(
                              shop: shop,
                              product: product,
                              myMotorcycle: myMotorcycle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
              final available = [
                for (final product in products)
                  if (product.isAvailable) product,
              ];
              final unavailable = [
                for (final product in products)
                  if (!product.isAvailable) product,
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // In-stock items come first; sold-out items follow below.
                  if (available.isNotEmpty) grid(available),
                  if (unavailable.isNotEmpty) ...[
                    if (available.isNotEmpty) const SizedBox(height: 10),
                    grid(unavailable),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The shop's picture when the owner added one, so buyers recognise the
/// shop; otherwise the storefront icon. Grey while the picture loads.
class _ShopAvatar extends StatelessWidget {
  const _ShopAvatar({required this.shop});

  final Shop shop;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    const icon = ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Icon(Icons.storefront_outlined, color: AppColors.primary),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: _size,
        height: _size,
        child: !shop.hasBanner
            ? icon
            : Image.network(
                shop.bannerUrl.trim(),
                key: ValueKey('shop-avatar-${shop.id}'),
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, sync) =>
                    sync || frame != null
                    ? child
                    : const ColoredBox(color: Color(0xFFE6E4E0)),
                errorBuilder: (context, error, stack) => icon,
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
