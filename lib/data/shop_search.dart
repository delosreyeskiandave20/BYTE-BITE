import '../models/shop.dart';

/// Matches runs of lowercase letters and digits between separators.
final _nonAlphaNumeric = RegExp(r'[^a-z0-9]+');

/// Words that are too generic to identify a product on their own.
const _ignoredSearchWords = {
  'motorcycle',
  'motoscan',
  'universal',
  'replacement',
  'with',
  'and',
  'for',
};

/// Splits [value] into lowercase alphanumeric search tokens.
List<String> searchTokens(String value) => value
    .toLowerCase()
    .split(_nonAlphaNumeric)
    .where((word) => word.isNotEmpty)
    .toList(growable: false);

/// Whether every query token is the prefix of a word in [searchableText].
bool matchesAllSearchTokens(String searchableText, List<String> queryTokens) {
  if (queryTokens.isEmpty) return true;
  final words = searchTokens(searchableText);
  return queryTokens.every(
    (token) => words.any((word) => word.startsWith(token)),
  );
}

/// Whether [product] matches every query token across its shop details.
bool shopProductMatchesTokens(
  Shop shop,
  ShopProduct product,
  List<String> queryTokens,
) {
  final searchableText = [
    product.name,
    product.category,
    product.description,
    shop.name,
    shop.location,
  ].join(' ');
  return matchesAllSearchTokens(searchableText, queryTokens);
}

/// In-stock products whose name matches [query].
List<ShopProduct> availableProductsForQuery(Shop shop, String query) {
  return shop.products
      .where(
        (product) =>
            product.isAvailable && matchesShopProductQuery(product.name, query),
      )
      .toList(growable: false);
}

/// Matches a product name against a query using significant words only.
bool matchesShopProductQuery(String productName, String query) {
  final queryWords = _significantSearchWords(query);
  final productWords = _significantSearchWords(productName);
  if (productWords.isEmpty) return false;
  final matchingWords = productWords.intersection(queryWords).length;
  // A single word is enough for a short name; longer names need two matches.
  final requiredMatches = productWords.length < 2 ? productWords.length : 2;
  return matchingWords >= requiredMatches;
}

Set<String> _significantSearchWords(String value) =>
    searchTokens(value)
        .where((word) => word.length > 1 && !_ignoredSearchWords.contains(word))
        .toSet();
