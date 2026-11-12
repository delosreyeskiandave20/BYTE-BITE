import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/shop_store.dart';
import '../screens/shop_page.dart';
import '../theme/app_theme.dart';

class BuyOptionsButton extends StatelessWidget {
  const BuyOptionsButton({
    required this.store,
    required this.productQuery,
    this.onOwnerSignIn,
    super.key,
  });

  final ShopStore store;
  final String productQuery;
  final VoidCallback? onOwnerSignIn;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: ValueKey('buy-$productQuery'),
      onPressed: () => _showOptions(context),
      icon: const Icon(Icons.shopping_bag_outlined, size: 17),
      label: const Text('Buy'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    final shops = store.shops
        .where(
          (shop) => availableProductsForQuery(shop, productQuery).isNotEmpty,
        )
        .toList(growable: false);
    final selectedShop = await showDialog<Shop>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _BuyOptionsDialog(shops: shops, productQuery: productQuery),
    );
    if (selectedShop == null || !context.mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ShopPage(
          store: store,
          onOwnerSignIn: onOwnerSignIn,
          initialProductQuery: productQuery,
          initialShopName: selectedShop.name,
        ),
      ),
    );
  }
}

class _BuyOptionsDialog extends StatefulWidget {
  const _BuyOptionsDialog({required this.shops, required this.productQuery});

  final List<Shop> shops;
  final String productQuery;

  @override
  State<_BuyOptionsDialog> createState() => _BuyOptionsDialogState();
}

class _BuyOptionsDialogState extends State<_BuyOptionsDialog> {
  bool _canPop = false;

  void _close<T extends Object?>([T? result]) {
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop<T>(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dialogHeight = min(
      min(360.0, MediaQuery.sizeOf(context).height * 0.55),
      130.0 + widget.shops.length * 150.0,
    );
    return PopScope(
      canPop: _canPop,
      child: AlertDialog(
        title: Text('Where to buy ${widget.productQuery}'),
        content: SizedBox(
          width: 420,
          height: widget.shops.isEmpty ? 180 : dialogHeight,
          child: widget.shops.isEmpty
              ? _marketplaceChoices(context)
              : ListView(
                  children: [
                    const Text(
                      'Available at these local shops:',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    ...widget.shops.map((shop) {
                      final products = availableProductsForQuery(
                        shop,
                        widget.productQuery,
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (shop.location.isNotEmpty)
                                Text(
                                  shop.location,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ...products.map(
                                (product) => Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${product.name} · '
                                    '₱${product.price.toStringAsFixed(2)} · '
                                    '${product.quantity} in stock',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _close(shop),
                                  child: const Text('View shop'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        ),
        actions: [TextButton(onPressed: _close, child: const Text('Close'))],
      ),
    );
  }

  Widget _marketplaceChoices(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('No local shop has this item in stock.'),
        const SizedBox(height: 12),
        _MarketplaceButton(
          name: 'Shopee',
          onPressed: () => _openMarketplace(context, 'Shopee'),
        ),
        const SizedBox(height: 8),
        _MarketplaceButton(
          name: 'Lazada',
          onPressed: () => _openMarketplace(context, 'Lazada'),
        ),
      ],
    );
  }

  Future<void> _openMarketplace(
    BuildContext context,
    String marketplace,
  ) async {
    final uri = switch (marketplace) {
      'Shopee' => Uri.https('shopee.ph', '/search', {
        'keyword': widget.productQuery,
      }),
      'Lazada' => Uri.https('www.lazada.com.ph', '/catalog/', {
        'q': widget.productQuery,
      }),
      _ => throw ArgumentError.value(marketplace, 'marketplace'),
    };
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $marketplace search.')),
      );
    } else if (context.mounted) {
      _close();
    }
  }
}

class _MarketplaceButton extends StatelessWidget {
  const _MarketplaceButton({required this.name, required this.onPressed});

  final String name;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(name),
      ),
    );
  }
}
