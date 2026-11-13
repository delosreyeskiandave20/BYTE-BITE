/// External marketplaces used when no local shop stocks an item.
abstract final class Marketplaces {
  static const shopee = 'Shopee';
  static const lazada = 'Lazada';

  /// Search URL for [marketplace] and [query].
  static Uri searchUri(String marketplace, String query) {
    return switch (marketplace) {
      shopee => Uri.https('shopee.ph', '/search', {'keyword': query}),
      lazada => Uri.https('www.lazada.com.ph', '/catalog/', {'q': query}),
      _ => throw ArgumentError.value(marketplace, 'marketplace'),
    };
  }
}
