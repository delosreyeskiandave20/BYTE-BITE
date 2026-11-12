import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/auth_page.dart';
import 'package:flutter_application_1/screens/shop_owner_dashboard_page.dart';

const _owner = 'owner@example.com';

Future<TemporaryShopStore> _storeWithShop() async {
  final store = TemporaryShopStore();
  await store.createOwner(
    name: 'Test Owner',
    email: _owner,
    password: 'temporary123',
    pin: '123456',
  );
  await store.saveShop(
    ownerEmail: _owner,
    name: 'Test Parts Shop',
    location: 'Cebu City, Cebu',
    description: 'Parts for every ride.',
  );
  addTearDown(store.dispose);
  return store;
}

TextFormField _field(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(find.widgetWithText(TextFormField, label));

void main() {
  testWidgets('demo login fills the owner form and submits', (
    WidgetTester tester,
  ) async {
    String? email;
    String? password;
    await tester.pumpWidget(
      MaterialApp(
        home: MotoScanAuthPage(
          onLogin: (submittedEmail, submittedPassword, _) async {
            email = submittedEmail;
            password = submittedPassword;
          },
        ),
      ),
    );

    expect(find.text('Demo shop owner'), findsOneWidget);
    await tester.ensureVisible(find.text('Use demo login'));
    await tester.tap(find.text('Use demo login'));
    await tester.pumpAndSettle();

    expect(
      _field(tester, 'Email address').controller!.text,
      'demo@motoscan.test',
    );
    expect(_field(tester, 'Password').controller!.text, 'demo1234');

    final loginButton = find.widgetWithText(ElevatedButton, 'Log in');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(email, 'demo@motoscan.test');
    expect(password, 'demo1234');
  });

  testWidgets('demo helper is hidden when Firebase Auth is connected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MotoScanAuthPage(isDemoMode: false)),
    );

    expect(find.text('Use demo login'), findsNothing);
    expect(find.textContaining('Temporary demo only'), findsNothing);
  });

  testWidgets('owner sign-in shows inline validation errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MotoScanAuthPage(onLogin: (_, _, _) async {})),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'not-an-email',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'short',
    );
    final loginButton = find.widgetWithText(ElevatedButton, 'Log in');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });

  testWidgets('typed auth failures become friendly inline messages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MotoScanAuthPage(
          onLogin: (_, _, _) async =>
              throw FirebaseAuthException(code: 'too-many-requests'),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'owner@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'temporary123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '6-digit PIN'),
      '123456',
    );
    final loginButton = find.widgetWithText(ElevatedButton, 'Log in');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Too many attempts. Wait a moment and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('leaving unchanged shop details pops without a prompt', (
    WidgetTester tester,
  ) async {
    final store = await _storeWithShop();
    await tester.pumpWidget(
      MaterialApp(home: _DashboardLauncher(store: store)),
    );
    await tester.tap(find.text('Open shop'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back to owner sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Open shop'), findsOneWidget);
  });

  testWidgets('editing shop details asks before discarding changes', (
    WidgetTester tester,
  ) async {
    final store = await _storeWithShop();
    await tester.pumpWidget(
      MaterialApp(home: _DashboardLauncher(store: store)),
    );
    await tester.tap(find.text('Open shop'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Shop name'),
      'Unsaved Shop',
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Back to owner sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Manage your shop'), findsOneWidget);
    expect(find.text('Unsaved Shop'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to owner sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Open shop'), findsOneWidget);
    expect(store.shopForOwner(_owner)!.name, 'Test Parts Shop');
  });

  testWidgets('saving shop details clears the unsaved-changes guard', (
    WidgetTester tester,
  ) async {
    final store = await _storeWithShop();
    await tester.pumpWidget(
      MaterialApp(home: _DashboardLauncher(store: store)),
    );
    await tester.tap(find.text('Open shop'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Shop name'),
      'Saved Shop',
    );
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and view shop'));
    await tester.pumpAndSettle();

    expect(find.text('Open shop'), findsOneWidget);
    expect(store.shopForOwner(_owner)!.name, 'Saved Shop');
  });
}

/// Pushes the dashboard over a host route so back navigation can be observed.
class _DashboardLauncher extends StatelessWidget {
  const _DashboardLauncher({required this.store});

  final ShopStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ShopOwnerDashboardPage(
                store: store,
                ownerEmail: _owner,
                onDone: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          child: const Text('Open shop'),
        ),
      ),
    );
  }
}
