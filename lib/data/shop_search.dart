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
/// highest. Otherwise an item still matches, lower down, only when its [name]
/// shares the query's main part word (the last key word, e.g. "caliper" in
/// "Front brake caliper") or at least two key words. So "Air filter" also
/// lists "Oil filter" but not "Air horn", and "Rear shock absorber" does not
/// list "Rear tire".
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
  final keyTokens = [
    for (final token in queryTokens)
      if (token.length >= 3 && !_weakSearchWords.contains(token)) token,
  ];
  if (keyTokens.isEmpty) return 0;
  final nameWords = searchTokens(name);
  bool inName(String token) => nameWords.any((word) => word.startsWith(token));

  final matchedKeys = keyTokens.where(inName).length;
  final headMatched = inName(keyTokens.last);
  if (!headMatched && matchedKeys < 2) return 0;

  // Each key word found adds points, the main part word most; position words
  // like "rear" add a little, so "Rear shock absorber" ranks "Shock absorber
  // spring" above "Rear absorber bracket".
  var score = matchedKeys * 3 + (headMatched ? 3 : 0);
  for (final token in queryTokens) {
    if (_weakSearchWords.contains(token) && inName(token)) score += 1;
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
