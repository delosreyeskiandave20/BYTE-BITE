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
    final headOnly = score('Rear absorber bracket');
    final shockOnly = score('Rear shock bushing');
    final rearOnly = score('Rear tire');
    final unrelated = score('Front fender');

    expect(exact, greaterThan(noPosition));
    expect(noPosition, greaterThan(headOnly));
    expect(headOnly, greaterThan(0), reason: 'same main part word still shows');
    expect(shockOnly, 0, reason: 'a side word alone is not related enough');
    expect(rearOnly, 0, reason: 'position words alone are not related');
    expect(unrelated, 0);
  });

  test('a scanned air filter suggests filters, not other air parts', () {
    final tokens = relevanceQueryTokens('Air filter');
    int score(String name) => searchRelevance(tokens, name: name);

    expect(score('Air filter element'), greaterThan(999));
    expect(score('Oil filter'), greaterThan(0));
    expect(score('Air horn'), 0);
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
