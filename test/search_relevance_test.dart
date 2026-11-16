import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/catalog_images.dart';
import 'package:flutter_application_1/data/parts_catalog.dart';

import 'package:flutter_application_1/data/shop_search.dart';

void main() {
  test('closer names rank higher for an AI match', () {
    final tokens = relevanceQueryTokens('Rear shock absorber');
    int score(String name) => searchRelevance(tokens, name: name);

    final exact = score('Rear Shock Absorber');
    final noPosition = score('Shock absorber spring');
    final shockOnly = score('Rear shock bushing');
    final rearOnly = score('Rear tire');
    final unrelated = score('Front fender');

    expect(exact, greaterThan(noPosition));
    expect(noPosition, greaterThan(shockOnly));
    expect(shockOnly, greaterThan(rearOnly));
    expect(rearOnly, greaterThan(0), reason: 'rear-only items still show');
    expect(unrelated, 0);
  });

  test('plural queries match singular names', () {
    final tokens = relevanceQueryTokens('Brake pads');
    expect(
      searchRelevance(tokens, name: 'Ceramic brake pad'),
      greaterThan(999),
    );
  });

  test('every parts library item has a photo', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final index = await loadPartImageIndex(rootBundle);
    for (final product in catalogProducts) {
      expect(
        index.lookup(product.name, ''),
        isNotNull,
        reason: '${product.name} has no photo',
      );
    }
  });
}
