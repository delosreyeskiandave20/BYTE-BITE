import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/online_stores.dart';
import '../data/price_format.dart';
import '../theme/app_theme.dart';
import '../widgets/marketplace_logo.dart';

/// Opens [uri] in the marketplace app or browser, reporting a failure.
Future<void> openOnlineStoreLink(BuildContext context, Uri uri) async {
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open the store.')));
  }
}

/// One Shopee or Lazada store and the items it lists. Buying happens on the
/// marketplace itself.
class OnlineStorePage extends StatelessWidget {
  const OnlineStorePage({required this.store, this.highlight, super.key});

  final OnlineStore store;

  /// Items matching this search are listed first.
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final tokens = onlineStoreTokens(highlight ?? '');
    final items = [
      ...store.items.where((item) => onlineItemMatches(item, tokens)),
      ...store.items.where((item) => !onlineItemMatches(item, tokens)),
    ];
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(store.name),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: items.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 16 : 10),
        itemBuilder: (context, index) {
          if (index == 0) return _StoreHeader(store: store);
          final item = items[index - 1];
          return _OnlineItemCard(
            key: ValueKey('online-item-${item.name}'),
            item: item,
            highlighted: tokens.isNotEmpty && onlineItemMatches(item, tokens),
            onBuy: () => openOnlineStoreLink(context, store.itemUri(item)),
          );
        },
      ),
    );
  }
}

/// Brand-tinted card at the top of a store page.
class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store});

  final OnlineStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: OnlineStoresSection._brandSoft(store.marketplace),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: MarketplaceLogo(store.marketplace, height: 16),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: AppType.section,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${store.items.length} items · prices as of '
                      '$onlineStoresCheckedOn',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: AppType.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openOnlineStoreLink(context, store.storeUri),
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: const Text('Visit store'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prices may have changed. You pay on the marketplace.',
            style: TextStyle(color: AppColors.muted, fontSize: AppType.micro),
          ),
        ],
      ),
    );
  }
}

class _OnlineItemCard extends StatelessWidget {
  const _OnlineItemCard({
    required this.item,
    required this.highlighted,
    required this.onBuy,
    super.key,
  });

  final OnlineStoreItem item;
  final bool highlighted;
  final VoidCallback onBuy;

  /// A part-type icon guessed from the item name.
  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('brake')) return Icons.album_outlined;
    if (n.contains('filter')) return Icons.air_rounded;
    if (n.contains('bearing') || n.contains('ball race')) {
      return Icons.settings_rounded;
    }
    if (n.contains('light') || n.contains('lamp') || n.contains('led')) {
      return Icons.light_mode_outlined;
    }
    if (n.contains('oil')) return Icons.water_drop_outlined;
    if (n.contains('tire') || n.contains('tyre') || n.contains('wheel')) {
      return Icons.tire_repair_rounded;
    }
    if (n.contains('battery')) return Icons.battery_charging_full_rounded;
    if (n.contains('belt') || n.contains('chain')) return Icons.link_rounded;
    if (n.contains('mirror')) return Icons.visibility_outlined;
    return Icons.build_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: highlighted ? AppColors.primary : AppColors.line,
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(item.name), color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (highlighted) ...[
                  const Text(
                    'MATCHES YOUR SEARCH',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: AppType.body,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPeso(item.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: AppType.cardTitle + 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: onBuy,
            icon: const Icon(Icons.shopping_cart_outlined, size: 16),
            label: const Text('Buy'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: AppType.caption + 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lower-case search words, ignoring very short ones.
List<String> onlineStoreTokens(String query) => query
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9/.-]+'))
    .where((word) => word.length > 1)
    .toList(growable: false);

bool onlineItemMatches(OnlineStoreItem item, List<String> tokens) {
  if (tokens.isEmpty) return false;
  final name = item.name.toLowerCase();
  return tokens.every(name.contains);
}

/// Shop-tab section listing the Shopee and Lazada stores. With a search, it
/// shows only stores carrying a matching item, and how many match.
class OnlineStoresSection extends StatelessWidget {
  const OnlineStoresSection({required this.searchQuery, super.key});

  final String searchQuery;

  /// A light tint of the marketplace's brand colour behind its logo.
  static Color _brandSoft(String marketplace) =>
      marketplace.toLowerCase().contains('shopee')
      ? const Color(0xFFFFEEE8)
      : const Color(0xFFEEF0FA);

  static double? _lowestPrice(OnlineStore store) {
    final prices = [
      for (final item in store.items)
        if (item.price > 0) item.price,
    ];
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = onlineStoreTokens(searchQuery);
    final stores = [
      for (final store in onlineStores)
        (
          store: store,
          matches: store.items
              .where((item) => onlineItemMatches(item, tokens))
              .length,
        ),
    ].where((entry) => tokens.isEmpty || entry.matches > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tokens.isEmpty
              ? 'Shopee & Lazada stores'
              : 'Shopee & Lazada stores with "${searchQuery.trim()}"',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          stores.isEmpty
              ? 'None of these stores list that item.'
              : 'Tap a store to see its items. You buy on the marketplace.',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        for (final entry in stores)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              key: ValueKey('online-store-${entry.store.slug}'),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OnlineStorePage(
                      store: entry.store,
                      highlight: searchQuery,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _brandSoft(entry.store.marketplace),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: MarketplaceLogo(
                          entry.store.marketplace,
                          height: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: AppType.cardTitle + 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 13,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    tokens.isEmpty
                                        ? '${entry.store.items.length} items'
                                        : '${entry.matches} matching '
                                              '${entry.matches == 1 ? 'item' : 'items'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: AppType.caption,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_lowestPrice(entry.store) case final low?) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'from ${formatPeso(low).replaceAll('.00', '')}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: AppType.micro,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
