import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/online_stores.dart';
import '../data/price_format.dart';
import '../theme/app_theme.dart';

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
        actions: [
          TextButton.icon(
            onPressed: () => openOnlineStoreLink(context, store.storeUri),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text('Open on ${store.marketplace}'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              '${store.items.length} items · prices as of $onlineStoresCheckedOn',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: AppType.caption,
              ),
            );
          }
          final item = items[index - 1];
          return Container(
            key: ValueKey('online-item-${item.name}'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: onlineItemMatches(item, tokens) && tokens.isNotEmpty
                    ? AppColors.primary
                    : AppColors.line,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: AppType.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatPeso(item.price),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: AppType.body,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () =>
                      openOnlineStoreLink(context, store.itemUri(item)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Buy'),
                ),
              ],
            ),
          );
        },
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      _MarketplaceBadge(entry.store.marketplace),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.store.name,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: AppType.cardTitle,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tokens.isEmpty
                                  ? '${entry.store.marketplace} · '
                                        '${entry.store.items.length} items'
                                  : '${entry.store.marketplace} · '
                                        '${entry.matches} matching '
                                        '${entry.matches == 1 ? 'item' : 'items'}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: AppType.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.primary),
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

class _MarketplaceBadge extends StatelessWidget {
  const _MarketplaceBadge(this.marketplace);

  final String marketplace;

  @override
  Widget build(BuildContext context) {
    final lazada = marketplace == 'Lazada';
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lazada ? const Color(0xFFE8EAFB) : const Color(0xFFFDEBE5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        lazada ? 'L' : 'S',
        style: TextStyle(
          color: lazada ? const Color(0xFF0F146D) : const Color(0xFFEE4D2D),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
