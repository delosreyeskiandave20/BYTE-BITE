import 'marketplace.dart';

/// Longest store link accepted; keep in sync with firestore.rules.
const maxMarketplaceUrlLength = 200;

/// A seller's own Shopee or Lazada store, read from the link they pasted.
class MarketplaceLink {
  const MarketplaceLink({required this.marketplace, required this.slug});

  /// [Marketplaces.shopee] or [Marketplaces.lazada].
  final String marketplace;

  /// The store's name in its web address, e.g. `sh0pnstyle`.
  final String slug;

  /// The clean store link saved to the shop.
  String get url => switch (marketplace) {
    Marketplaces.lazada => 'https://www.lazada.com.ph/shop/$slug/',
    _ => 'https://shopee.ph/$slug',
  };
}

/// Shopee paths that are pages, not store names.
const _shopeeReserved = {
  'shop',
  'search',
  'product',
  'cart',
  'mall',
  'buyer',
  'user',
  'm',
  'daily_discover',
  'flash_sale',
};

final _slugPattern = RegExp(r'^[A-Za-z0-9._-]{2,80}$');

/// Reads a Shopee or Lazada store link, or returns null when [input] is not
/// one. Accepts links with or without `https://`, `www.` and tracking
/// parameters.
MarketplaceLink? parseMarketplaceLink(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  if (host == 'lazada.com.ph') {
    // https://www.lazada.com.ph/shop/<slug>/
    if (segments.length >= 2 && segments.first == 'shop') {
      final slug = segments[1];
      if (_slugPattern.hasMatch(slug)) {
        return MarketplaceLink(marketplace: Marketplaces.lazada, slug: slug);
      }
    }
    return null;
  }

  if (host == 'shopee.ph') {
    // https://shopee.ph/<slug>
    if (segments.length == 1) {
      final slug = segments.first;
      if (!_shopeeReserved.contains(slug.toLowerCase()) &&
          !slug.contains('-i.') &&
          _slugPattern.hasMatch(slug)) {
        return MarketplaceLink(marketplace: Marketplaces.shopee, slug: slug);
      }
    }
    return null;
  }
  return null;
}

/// Form validator for the optional store link field.
String? validateMarketplaceLink(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (text.length > maxMarketplaceUrlLength) return 'This link is too long.';
  if (parseMarketplaceLink(text) != null) return null;
  final lower = text.toLowerCase();
  if (lower.contains('shopee.ph/shop/') || lower.contains('-i.')) {
    return 'Use your shop page link, e.g. shopee.ph/yourshop';
  }
  if (lower.contains('lazada')) {
    return 'Use your shop page link, e.g. lazada.com.ph/shop/yourshop';
  }
  return 'Paste a Shopee or Lazada store link.';
}
