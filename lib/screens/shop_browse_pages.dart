import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/price_format.dart';
import '../data/shop_store.dart';
import '../theme/app_theme.dart';
import 'shop_item_page.dart';

/// Viewer-only shop browsing: a list of every shop, and a full-screen page per
/// shop with that shop's items. Nothing here can add, edit or delete data.

/// Grey box shown while a picture loads, or when there is no picture.
class _GreyPlaceholder extends StatelessWidget {
  const _GreyPlaceholder({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE6E4E0),
      child: icon == null
          ? const SizedBox.expand()
          : Center(child: Icon(icon, color: const Color(0xFFB4B0AA), size: 34)),
    );
  }
}

/// A picture that shows [_GreyPlaceholder] until it has loaded, and again with
/// [fallbackIcon] if it fails.
class _ShopPicture extends StatelessWidget {
  const _ShopPicture({required this.image, required this.fallbackIcon});

  final ImageProvider? image;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    if (image == null) return _GreyPlaceholder(icon: fallbackIcon);
    return Image(
      image: image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const _GreyPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) =>
          _GreyPlaceholder(icon: fallbackIcon),
    );
  }
}

ImageProvider? _bannerOf(Shop shop) =>
    shop.hasBanner ? NetworkImage(shop.bannerUrl.trim()) : null;

void openShopBrowsePage(BuildContext context, ShopStore store, Shop shop) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ShopDetailPage(store: store, shopId: shop.id),
    ),
  );
}

/// Every public shop with its picture, name and address.
class ShopListPage extends StatelessWidget {
  const ShopListPage({required this.store, super.key});

  final ShopStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text('Shops'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final shops = store.shops;
          if (store.isLoading && shops.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.lastErrorMessage != null && shops.isEmpty) {
            return _Message(
              key: const ValueKey('shop-list-error'),
              icon: Icons.cloud_off_outlined,
              text: "Can't load shops",
              onRetry: store.retry,
            );
          }
          if (shops.isEmpty) {
            return const _Message(
              key: ValueKey('shop-list-empty'),
              icon: Icons.storefront_outlined,
              text: 'No shops yet',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: shops.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return _ShopListTile(
                key: ValueKey('shop-list-${shop.id}'),
                shop: shop,
                onTap: () => openShopBrowsePage(context, store, shop),
              );
            },
          );
        },
      ),
    );
  }
}

class _ShopListTile extends StatelessWidget {
  const _ShopListTile({required this.shop, required this.onTap, super.key});

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: _ShopPicture(
                    image: _bannerOf(shop),
                    fallbackIcon: Icons.storefront_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            shop.location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
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

/// One shop in full screen: a large banner header that shrinks into a top bar,
/// then a two-column grid of ONLY this shop's items. The items come from the
/// store's live listener on this shop's own `products` sub-collection, so
/// additions and edits show up without reopening the page.
class ShopDetailPage extends StatefulWidget {
  const ShopDetailPage({required this.store, required this.shopId, super.key});

  final ShopStore store;
  final String shopId;

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> {
  @override
  void initState() {
    super.initState();
    // Full screen: status and navigation bars hidden; a swipe from the edge
    // shows them briefly.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final shop = widget.store.shops
              .where((shop) => shop.id == widget.shopId)
              .firstOrNull;
          final failed = widget.store.lastErrorMessage != null;
          if (shop == null) {
            return Stack(
              children: [
                if (widget.store.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  _Message(
                    key: const ValueKey('shop-detail-error'),
                    icon: Icons.cloud_off_outlined,
                    text: failed
                        ? "Can't load items"
                        : 'This shop is no '
                              'longer available',
                    onRetry: failed ? widget.store.retry : null,
                  ),
                const SafeArea(child: BackButton()),
              ],
            );
          }
          // Only this shop's own items, in stock first.
          final items = [
            ...shop.products.where((item) => item.isAvailable),
            ...shop.products.where((item) => !item.isAvailable),
          ];
          return CustomScrollView(
            key: const ValueKey('shop-detail-scroll'),
            slivers: [
              _ShopHeader(shop: shop),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Message(
                    key: const ValueKey('shop-detail-empty'),
                    icon: failed
                        ? Icons.cloud_off_outlined
                        : Icons.inventory_2_outlined,
                    text: failed
                        ? "Can't load items"
                        : 'No items in this shop yet',
                    onRetry: failed ? widget.store.retry : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.66,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ItemCard(
                        key: ValueKey('shop-item-${item.id}'),
                        item: item,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ShopItemPage(shop: shop, product: item),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Large banner with the shop name and address that collapses into a small
/// top bar with the name and a back arrow.
class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shop});

  final Shop shop;

  static const _expandedHeight = 260.0;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      key: const ValueKey('shop-detail-header'),
      pinned: true,
      expandedHeight: _expandedHeight,
      backgroundColor: AppColors.ink,
      foregroundColor: Colors.white,
      leading: const BackButton(key: ValueKey('shop-detail-back')),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.paddingOf(context).top;
          final collapsedHeight = kToolbarHeight + topPadding;
          // 1 when fully expanded, 0 when collapsed to the top bar.
          final t =
              ((constraints.maxHeight - collapsedHeight) /
                      (_expandedHeight - kToolbarHeight))
                  .clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: t,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ShopPicture(
                      image: _bannerOf(shop),
                      fallbackIcon: Icons.storefront_outlined,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Color(0xCC000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shop.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shop.location,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Small top bar title once the header has shrunk.
              Positioned(
                left: 56,
                right: 16,
                top: topPadding,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: 1 - t,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      shop.name,
                      key: const ValueKey('shop-detail-bar-title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap, super.key});

  final ShopProduct item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inStock = item.isAvailable;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ShopPicture(
                  image: item.hasImage ? item.imageProvider : null,
                  fallbackIcon: Icons.image_outlined,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatPeso(item.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inStock ? 'In stock: ${item.quantity}' : 'Out of stock',
                      style: TextStyle(
                        color: inStock
                            ? const Color(0xFF1E7A3C)
                            : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.onRetry,
    super.key,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.muted, size: 38),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
