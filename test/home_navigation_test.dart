import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/screens/home_page.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  if (logicalSize == const Size(800, 600)) {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  await tester.pumpWidget(const MotoScanApp());
  await tester.pumpAndSettle();
}

/// The scrollable that drives the Home feed (outermost scrollable in the tab).
Finder _homeScrollable() => find
    .descendant(
      of: find.byType(MotoScanHomePage),
      matching: find.byType(Scrollable),
    )
    .first;

double _homeScrollOffset(WidgetTester tester) =>
    tester.state<ScrollableState>(_homeScrollable()).position.pixels;

void main() {
  testWidgets('home does not show an in-body search entry', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Search parts, brands, and shops'), findsNothing);
    expect(find.byTooltip('Search parts'), findsOneWidget);
  });

  testWidgets('system back returns to Home from another tab', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Browse parts').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    expect(find.text('Available shops').hitTestable(), findsOneWidget);
    expect(find.text('Browse parts').hitTestable(), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Browse parts').hitTestable(), findsOneWidget);
    expect(find.text('Available shops').hitTestable(), findsNothing);
  });

  testWidgets('reselecting Home scrolls the feed back to the top', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(_homeScrollOffset(tester), 0);
    await tester.drag(_homeScrollable(), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(_homeScrollOffset(tester), greaterThan(0));

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(_homeScrollOffset(tester), 0);
    expect(find.text('Browse parts').hitTestable(), findsOneWidget);
  });

  testWidgets('app-bar shortcut opens search', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byTooltip('Search parts'));
    await tester.pumpAndSettle();
    expect(find.text('Parts library'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Parts library'), findsNothing);
    expect(find.byTooltip('Search parts'), findsOneWidget);
  });
}
