import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/search_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_owner_auth.dart';

List<String> _relatedChipTerms(WidgetTester tester) => [
  for (final element
      in find
          .byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'related-search-',
                ),
          )
          .evaluate())
    (element.widget.key! as ValueKey<String>).value.substring(
      'related-search-'.length,
    ),
];

void main() {
  testWidgets('a scanned part shows related searches instead of popular ones', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SearchPage(shopStore: store, initialQuery: 'Air filter'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Popular searches'), findsNothing);
    expect(find.text('Related to "Air filter"'), findsOneWidget);

    final terms = _relatedChipTerms(tester);
    // ignore: avoid_print
    print('Related to Air filter: $terms');
    expect(terms, isNotEmpty);
    expect(terms.length, lessThanOrEqualTo(6));
    for (final term in terms) {
      expect(
        term.toLowerCase(),
        contains('filter'),
        reason: '"$term" is not related to an air filter',
      );
    }

    // Tapping a suggestion searches for it.
    final first = terms.first;
    await tester.tap(find.byKey(ValueKey('related-search-$first')));
    await tester.pumpAndSettle();
    expect(find.text('Related to "$first"'), findsOneWidget);
  });

  testWidgets('battery items come first, then every other part below', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SearchPage(shopStore: store, initialQuery: 'Battery'),
      ),
    );
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(find.byType(ListView).first);
    final children =
        (list.childrenDelegate as SliverChildListDelegate).children;
    String? keyOf(Widget widget) => widget.key is ValueKey<String>
        ? (widget.key! as ValueKey<String>).value
        : null;
    final keys = [for (final child in children) keyOf(child)];
    final divider = keys.indexOf('search-all-other-items');
    expect(divider, greaterThan(0), reason: 'other items follow the matches');

    // Every card above the divider is a battery item; none below it is.
    String cardName(String key) => key
        .replaceFirst('search-related-', '')
        .replaceFirst('search-library-', '');
    final cards = [
      for (final (index, key) in keys.indexed)
        if (key != null &&
            (key.startsWith('search-related-') ||
                key.startsWith('search-library-')))
          (index, key),
    ];
    final above = [
      for (final (index, key) in cards)
        if (index < divider) key,
    ];
    final below = [
      for (final (index, key) in cards)
        if (index > divider) key,
    ];
    expect(above, isNotEmpty);
    expect(below, isNotEmpty);
    for (final key in above.where((k) => k.startsWith('search-related-'))) {
      expect(cardName(key).toLowerCase(), contains('batter'));
    }
    for (final key in below.where((k) => k.startsWith('search-related-'))) {
      expect(cardName(key).toLowerCase(), isNot(contains('batter')));
    }
  });

  testWidgets('an empty search still shows popular searches', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(home: SearchPage(shopStore: store)));
    await tester.pumpAndSettle();

    expect(find.text('Popular searches'), findsOneWidget);
    expect(find.byKey(const ValueKey('related-searches-title')), findsNothing);
  });
}
