import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

Future<void> _pumpAtScale(WidgetTester tester, double scale) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(const MotoScanApp());
  await tester.pumpAndSettle();
}

void _expectNoOverflow(WidgetTester tester, String screen) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'layout overflow on $screen');
}

void main() {
  for (final scale in <double>[1.3, 2.0]) {
    testWidgets('core screens reflow at ${scale}x text scale', (
      WidgetTester tester,
    ) async {
      await _pumpAtScale(tester, scale);
      _expectNoOverflow(tester, 'home');

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'scan');

      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'shop');

      await tester.tap(find.byTooltip('Manage your shop'));
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'auth');

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Search parts'));
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'search');
    });
  }
}
