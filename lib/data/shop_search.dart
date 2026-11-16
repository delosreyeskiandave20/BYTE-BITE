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

/// Query tokens for ranked search: generic words dropped and a plural `s`
/// trimmed, so "Brake pads" also finds "Brake pad set".
List<String> relevanceQueryTokens(String query) =>
    searchTokens(query)
        .where((word) => !_ignoredSearchWords.contains(word))
        .map(
          (word) =>
              word.length > 3 && word.endsWith('s') && !word.endsWith('ss')
              ? word.substring(0, word.length - 1)
              : word,
        )
        .toList(growable: false);

/// How well an item matches [queryTokens]; 0 means it should not be shown.
///
/// Items where every token is found anywhere in [name] or [details] rank
/// highest. Otherwise an item still matches, lower down, when its [name]
/// contains at least one meaningful token (3+ letters), so a specific AI
/// answer like "Front brake caliper" also lists other brake and caliper parts.
int searchRelevance(
  List<String> queryTokens, {
  required String name,
  String details = '',
}) {
  if (queryTokens.isEmpty) return 1;
  final allWords = searchTokens('$name $details');
  if (queryTokens.every(
    (token) => allWords.any((word) => word.startsWith(token)),
  )) {
    return 1000 + queryTokens.length;
  }
  // Partial match: each key word found in the name adds points. Position
  // words like "rear" or "front" count for less than the part itself, so for
  // "Rear shock absorber" a "Shock absorber spring" ranks above "Rear tire".
  final nameWords = searchTokens(name);
  var score = 0;
  for (final token in queryTokens) {
    if (token.length < 3) continue;
    if (!nameWords.any((word) => word.startsWith(token))) continue;
    score += _weakSearchWords.contains(token) ? 1 : 3;
  }
  return score;
}

/// Words that describe where a part sits rather than what it is.
const _weakSearchWords = {
  'rear',
  'front',
  'left',
  'right',
  'upper',
  'lower',
  'inner',
  'outer',
  'set',
  'kit',
};

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
