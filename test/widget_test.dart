import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/data/accessories_maintenance_catalog.dart';
import 'package:flutter_application_1/data/design_catalog.dart';
import 'package:flutter_application_1/data/parts_catalog.dart';
import 'package:flutter_application_1/data/temporary_shop_store.dart';
import 'package:flutter_application_1/data/vehicle_images.dart';
import 'package:flutter_application_1/data/vehicle_parts_catalog.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screens/auth_page.dart';
import 'package:flutter_application_1/screens/camera_capture_page.dart';
import 'package:flutter_application_1/screens/identify_page.dart';
import 'package:flutter_application_1/screens/motorcycle_parts_catalog_page.dart';
import 'package:flutter_application_1/screens/parts_catalog_page.dart';
import 'package:flutter_application_1/screens/shop_page.dart';
import 'package:flutter_application_1/screens/shop_owner_dashboard_page.dart';
import 'package:flutter_application_1/widgets/buy_options_button.dart';
import 'package:flutter_application_1/widgets/desktop_phone_frame.dart';
import 'package:flutter_application_1/widgets/vehicle_variant_carousel.dart';

import 'fake_owner_auth.dart';

Future<void> _pumpIntoMotoScan(WidgetTester tester) async {
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

/// Returns the bundled asset name behind [provider], unwrapping the decode-size
/// wrapper that `Image.asset(cacheWidth: ...)` creates.
String? _assetNameOf(ImageProvider provider) {
  if (provider is AssetImage) return provider.assetName;
  if (provider is ResizeImage) return _assetNameOf(provider.imageProvider);
  return null;
}

Finder _motorcycleImage(String assetName) => find.byWidgetPredicate(
  (widget) => widget is Image && _assetNameOf(widget.image) == assetName,
);

void main() {
  testWidgets('home app bar fits a narrow web viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MotoScanApp());
    await tester.pumpAndSettle();

    expect(find.text('MotoScan'), findsOneWidget);
    expect(find.byTooltip('Search parts'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsNothing);
    expect(find.text('Search for a part'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login account entry points use a person icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MotoScanAuthPage()));

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsNothing);
  });

  test('Google search targets the selected motorcycle and video reviews', () {
    final uri = motorcycleGoogleSearchUri(
      brand: 'Honda',
      model: 'BeAT',
      variant: 'Playful',
    );

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/search');
    expect(
      uri.queryParameters['q'],
      'Honda BeAT Playful motorcycle video review',
    );
  });

  test('vehicle catalog removes the final 21 motorcycle versions', () {
    final modelCount = vehicleCatalog.values.fold<int>(
      0,
      (count, models) => count + models.length,
    );

    expect(modelCount, 33);
    expect(vehicleCatalog.keys, ['Honda', 'Yamaha', 'Suzuki']);
    expect(vehicleCatalog['Suzuki']!.keys, [
      'Burgman 15',
      'Access',
      'Avenis',
      'Burgman Street 125 EX',
    ]);
    expect(
      vehicleCatalog.values
          .expand((models) => models.values)
          .expand((variants) => variants)
          .length,
      53,
    );
  });

  test('parts catalog omits the removed motorcycle versions', () async {
    final catalog = await loadVehiclePartsCatalog();

    expect(catalog, hasLength(53));
    expect(
      catalog.any(
        (vehicle) =>
            vehicle.brand == 'Kawasaki' ||
            vehicle.brand == 'RUSI' ||
            vehicle.brand == 'MotorStar' ||
            (vehicle.brand == 'Suzuki' &&
                !vehicleCatalog['Suzuki']!.containsKey(vehicle.model)),
      ),
      isFalse,
    );
  });

  test(
    'every catalog vehicle variant resolves to a motorcycle image',
    () async {
      var variantCount = 0;
      for (final brand in vehicleCatalog.entries) {
        for (final model in brand.value.entries) {
          for (final variant in model.value) {
            variantCount += 1;
            final imageAsset = vehicleVariantImageAsset(
              brand.key,
              model.key,
              variant,
            );
            expect(
              imageAsset,
              isNotNull,
              reason: '${brand.key} ${model.key} $variant',
            );
            await rootBundle.load(imageAsset!);
          }
        }
      }

      expect(variantCount, 53);
      expect(vehicleVariantImageAssets, hasLength(53));
    },
  );

  test(
    'motorcycle parts catalog contains the remaining variant records',
    () async {
      final catalog = await loadVehiclePartsCatalog();

      expect(catalog, hasLength(53));
      expect(
        catalog.fold<int>(0, (total, vehicle) => total + vehicle.partCount),
        2650,
      );
      final beat = catalog.firstWhere(
        (vehicle) =>
            vehicle.brand == 'Honda' &&
            vehicle.model == 'Beat' &&
            vehicle.variant == 'Playful',
      );
      expect(beat.partCount, 50);
      expect(beat.categories, hasLength(5));
      expect(beat.categories.first.name, 'Engine');
      expect(beat.categories.first.parts.first, 'Engine oil');
      for (final vehicle in catalog) {
        final imageAsset = vehiclePartsVariantImageAsset(
          brand: vehicle.brand,
          model: vehicle.model,
          variant: vehicle.variant,
        );
        expect(
          imageAsset,
          isNotNull,
          reason: '${vehicle.brand} ${vehicle.model} ${vehicle.variant}',
        );
        await rootBundle.load(imageAsset!);
      }
      for (final image in [
        'engine-showcase.png',
        'electrical-showcase.png',
        'suspension-showcase.png',
        'wheels-showcase.png',
        'body-showcase.png',
      ]) {
        await rootBundle.load('assets/parts/$image');
      }
    },
  );

  test('maintenance has all 20 items and their supplied choices', () {
    expect(maintenanceItemCount, 20);
    expect(maintenanceChoiceCount, 209);
    expect(maintenanceGroups.map((group) => group.title), [
      'Engine Oil',
      'Oil Filter or Oil Strainer',
      'Gear Oil or Final-Drive Oil',
      'Air Filter',
      'Spark Plug',
      'Coolant',
      'Brake Fluid',
      'Brake Pads and Brake Shoes',
      'Drive Chain',
      'Sprockets',
      'Chain Lubricant',
      'Scooter CVT Parts',
      'Tires',
      'Battery',
      'Fork and Suspension Items',
      'Fuel-System Cleaners',
      'Electrical Maintenance Items',
      'Grease and Protective Chemicals',
      'Cleaning Products',
      'Electric Motorcycle Maintenance Items',
    ]);
    expect(
      maintenanceGroups
          .expand((group) => group.itemChoices.values)
          .every((choices) => choices.isNotEmpty),
      isTrue,
    );
  });

  test('accessories has all supplied groups and unique choices', () {
    expect(accessoryItemCount, 32);
    expect(accessoryChoiceCount, 296);
    expect(accessoryGroups.map((group) => group.title), [
      'Helmet',
      'Helmet Accessories',
      'Riding Jacket',
      'Riding Pants',
      'Riding Gloves',
      'Motorcycle Boots',
      'Rain Gear',
      'Motorcycle Cover',
      'Top Box',
      'Side Case and Saddlebag',
      'Tank and Tail Bag',
      'Motorcycle Backpack',
      'Phone Holder',
      'Navigation and Communication',
      'USB and Charging Accessories',
      'Security Accessories',
      'Crash Protection',
      'Wind Protection',
      'Handlebar Accessories',
      'Lighting Accessories',
      'Horn and Visibility Accessories',
      'Comfort Accessories',
      'Passenger Accessories',
      'Storage Accessories',
      'Maintenance and Emergency Accessories',
      'Tire Accessories',
      'Stand and Parking Accessories',
      'Cleaning Accessories',
      'Protection and Appearance Accessories',
      'Performance Accessories',
      'Scooter Accessories',
      'Electric Motorcycle Accessories',
    ]);

    final choices = accessoryGroups
        .expand((group) => group.itemChoices[group.title] ?? const <String>[])
        .toList();
    expect(choices, hasLength(296));
    expect(choices.toSet(), hasLength(296));
    expect(choices, contains('Full-face helmet'));
    expect(choices, contains('Electric-motor diagnostic tool'));
  });

  testWidgets('MotoScan public browsing starts without login', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MotoScanApp());

    await tester.pumpAndSettle();

    expect(find.text('Shop owner sign in'), findsNothing);
    expect(find.text('Browse parts'), findsOneWidget);
    expect(find.text('View motorcycles'), findsOneWidget);
    expect(find.text('Accessories'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);
  });

  testWidgets('shop owners have a separate sign-in route', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MotoScanApp());
    await tester.tap(find.byTooltip('Shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Manage your shop'));
    await tester.pumpAndSettle();

    expect(find.text('Shop owner sign in'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('6-digit PIN'), findsNothing);
    expect(find.textContaining('Temporary demo only'), findsNothing);
    expect(find.textContaining('Firebase Authentication'), findsOneWidget);
  });

  testWidgets('shop tab lists demo products, prices, location, and markets', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    await tester.tap(find.byTooltip('Shop'));
    await tester.pumpAndSettle();

    expect(find.text('MotoScan Demo Parts'), findsOneWidget);
    expect(find.text('Quezon City, Metro Manila'), findsOneWidget);
    expect(find.text('Universal phone holder'), findsOneWidget);
    expect(find.text('₱450.00'), findsOneWidget);
    expect(find.textContaining('Temporary demo:'), findsNothing);
    expect(find.text('Shopee'), findsOneWidget);
    expect(find.text('Lazada'), findsOneWidget);
  });

  testWidgets('new owner products appear in the public shop list', (
    WidgetTester tester,
  ) async {
    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    addTearDown(store.dispose);
    await store.createOwner(
      name: 'Test Owner',
      email: 'test-owner@example.com',
      password: 'temporary123',
    );
    await store.saveShop(
      ownerEmail: 'test-owner@example.com',
      name: 'Test Parts Shop',
      location: 'Cebu City, Cebu',
      description: 'Local motorcycle parts.',
    );
    await store.addProduct(
      ownerEmail: 'test-owner@example.com',
      name: 'Brake lever',
    );
    final product = store.shopForOwner('test-owner@example.com')!.products.last;
    await store.updateProduct(
      ownerEmail: 'test-owner@example.com',
      productId: product.id,
      description: 'Replacement brake lever.',
      price: 275,
      quantity: 3,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ShopPage(store: store, onOwnerSignIn: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Test Parts Shop'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Test Parts Shop'), findsOneWidget);
    expect(find.text('Cebu City, Cebu'), findsOneWidget);
    expect(find.text('Brake lever'), findsOneWidget);
    expect(find.text('₱275.00'), findsOneWidget);
    expect(find.text('3 in stock'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);

    await store.updateProduct(
      ownerEmail: 'test-owner@example.com',
      productId: product.id,
      description: product.description,
      price: product.price,
      quantity: 0,
    );
    await tester.pumpAndSettle();
    expect(find.text('Unavailable'), findsNWidgets(2));
    expect(find.text('0 in stock'), findsNothing);
  });

  testWidgets('owner posts only a name and can edit details and stock', (
    WidgetTester tester,
  ) async {
    var didFinishEditing = false;
    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    addTearDown(store.dispose);
    await store.createOwner(
      name: 'Test Owner',
      email: 'test-owner@example.com',
      password: 'temporary123',
    );
    await store.saveShop(
      ownerEmail: 'test-owner@example.com',
      name: 'Test Parts Shop',
      location: 'Cebu City, Cebu',
      description: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ShopOwnerDashboardPage(
          store: store,
          ownerEmail: 'test-owner@example.com',
          onDone: () => didFinishEditing = true,
        ),
      ),
    );

    expect(find.textContaining('Temporary demo only'), findsNothing);
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Product name'), findsOneWidget);
    expect(find.text('Description or information'), findsNothing);
    expect(find.text('Price (PHP)'), findsNothing);
    expect(find.text('Quantity'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product name'),
      'Brake lever',
    );
    await tester.tap(find.text('Post name'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Brake lever'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Brake lever'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Brake lever'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description or information'),
      'Replacement brake lever.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price (PHP)'),
      '275',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '0');
    await tester.tap(find.text('Save product details'));
    await tester.pumpAndSettle();

    final product = store.shopForOwner('test-owner@example.com')!.products.last;
    expect(product.description, 'Replacement brake lever.');
    expect(product.price, 275);
    expect(product.quantity, 0);
    expect(product.isAvailable, isFalse);
    expect(find.textContaining('Unavailable'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Shop name'),
      'Updated Parts Shop',
    );
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Save shop changes?'), findsOneWidget);
    await tester.tap(find.text('Back to editing'));
    await tester.pumpAndSettle();
    expect(find.text('Manage your shop'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Shop name'),
          )
          .controller!
          .text,
      'Updated Parts Shop',
    );

    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and view shop'));
    await tester.pumpAndSettle();
    expect(find.text('Save shop changes?'), findsNothing);
    expect(didFinishEditing, isTrue);
    expect(
      store.shopForOwner('test-owner@example.com')!.name,
      'Updated Parts Shop',
    );
  });

  testWidgets('motorcycle browser shows and zooms variant images', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    expect(find.text('Browse motorcycle variants'), findsNothing);
    await tester.tap(find.text('View motorcycles'));
    await tester.pumpAndSettle();

    expect(find.text('Motorcycle gallery'), findsOneWidget);
    expect(find.text('View motorcycles'), findsNothing);
    final hondaVariantCount = vehicleCatalog['Honda']!.values
        .expand((variants) => variants)
        .length;
    expect(find.text('1 / $hondaVariantCount'), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-brand-Honda')), findsOneWidget);
    expect(find.text('BeAT'), findsOneWidget);
    expect(find.text('Playful'), findsNWidgets(2));
    expect(find.text('Available variants'), findsOneWidget);
    expect(find.text('Find videos & details on Google'), findsOneWidget);
    expect(find.text('95 model-level part candidates'), findsNothing);
    expect(
      _motorcycleImage('assets/motorcycles/honda_beat_playful.png'),
      findsWidgets,
    );
    expect(find.text('No vehicle image available'), findsNothing);

    await tester.tap(find.byTooltip('Next motorcycle variant'));
    await tester.pumpAndSettle();
    expect(find.text('Premium'), findsNWidgets(2));
    expect(
      _motorcycleImage('assets/motorcycles/honda_beat_premium.png'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Zoom motorcycle image'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close zoomed image'), findsOneWidget);
    expect(
      _motorcycleImage('assets/motorcycles/honda_beat_premium.png'),
      findsNWidgets(2),
    );
    await tester.tap(find.byTooltip('Close zoomed image'));
    await tester.pumpAndSettle();

    Future<void> advanceVariants(int count) async {
      for (var index = 0; index < count; index++) {
        await tester.tap(find.byTooltip('Next motorcycle variant'));
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle();
    }

    final yamahaVariantCount = vehicleCatalog['Yamaha']!.values
        .expand((variants) => variants)
        .length;
    final suzukiVariantCount = vehicleCatalog['Suzuki']!.values
        .expand((variants) => variants)
        .length;
    await advanceVariants(hondaVariantCount - 1);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('gallery-brand-Yamaha')),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Mio Gear'), findsOneWidget);
    expect(
      _motorcycleImage('assets/motorcycles/yamaha_mio_gear_standard.png'),
      findsWidgets,
    );

    await advanceVariants(yamahaVariantCount);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('gallery-brand-Suzuki')),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Burgman 15'), findsOneWidget);

    await advanceVariants(suzukiVariantCount);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('gallery-brand-Honda')))
          .selected,
      isTrue,
    );
    expect(find.text('BeAT'), findsOneWidget);
    expect(find.text('Playful'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Previous motorcycle variant'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('gallery-brand-Suzuki')),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Burgman Street 125 EX'), findsOneWidget);
  });

  testWidgets('design buy buttons show shops without a detail panel', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    for (final item in designGroups.expand((group) => group.items)) {
      expect(find.byKey(ValueKey('design-image-$item')), findsOneWidget);
      expect(find.byKey(ValueKey('design-description-$item')), findsOneWidget);
      expect(find.byKey(ValueKey('buy-$item')), findsOneWidget);
    }

    await tester.ensureVisible(find.text('LED Headlight'));
    await tester.pumpAndSettle();
    for (final imageAsset in [
      'assets/design/lighting_led_headlight.png',
      'assets/design/lighting_led_tail_light.png',
      'assets/design/lighting_led_signal_light.png',
      'assets/design/lighting_led_turn_signal.png',
      'assets/design/lighting_led_drl.png',
    ]) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image && _assetNameOf(widget.image) == imageAsset,
        ),
        findsOneWidget,
      );
    }
    expect(find.text('Add an image to this choice'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('buy-LED Headlight')));
    await tester.pumpAndSettle();

    expect(find.text('Where to buy LED Headlight'), findsOneWidget);
    expect(find.text('No local shop has this item in stock.'), findsOneWidget);
    expect(find.text('Shopee'), findsOneWidget);
    expect(find.text('Lazada'), findsOneWidget);
    expect(find.text('WHERE TO FIND THIS PRODUCT'), findsNothing);
  });

  testWidgets('search tab filters the sample catalog', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    await tester.tap(find.byTooltip('Search parts'));
    await tester.pumpAndSettle();

    expect(find.text('Parts library'), findsOneWidget);
    expect(find.text('7 matches'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'clutch friction');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Clutch friction plate'),
      120,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Clutch friction plate'), findsOneWidget);
    expect(find.text('Air filter element'), findsNothing);
    expect(find.text('Rear brake cable'), findsNothing);
  });

  testWidgets('category catalog lists parts without motorcycle filtering', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PartsCatalogPage(categoryId: 'engine')),
    );

    expect(find.text('1 catalog entry'), findsOneWidget);
    expect(find.text('Air filter element'), findsNothing);
    expect(find.text('Clutch friction plate'), findsOneWidget);
    expect(find.text('Choose your vehicle brand'), findsNothing);
    expect(find.textContaining('compatible'), findsNothing);
    for (final category in [
      'Engine',
      'Electrical',
      'Suspension',
      'Wheels & Tires',
      'Body',
    ]) {
      expect(find.text(category), findsOneWidget);
    }

    await tester.tap(find.text('Clutch friction plate'));
    await tester.pumpAndSettle();
    expect(find.text('DESCRIPTION'), findsOneWidget);
    final buyButton = find.byKey(
      const ValueKey('buy-MotoScan clutch friction plate'),
    );
    expect(buyButton, findsOneWidget);
    await tester.tap(buyButton);
    await tester.pumpAndSettle();
    expect(
      find.text('Where to buy MotoScan clutch friction plate'),
      findsOneWidget,
    );
    expect(find.text('Shopee'), findsOneWidget);
    expect(find.text('Lazada'), findsOneWidget);
  });

  testWidgets('Buy shows matching in-stock local shops first', (
    WidgetTester tester,
  ) async {
    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuyOptionsButton(
            store: store,
            productQuery: 'Universal phone holder',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buy'));
    await tester.pumpAndSettle();

    expect(find.text('MotoScan Demo Parts'), findsOneWidget);
    expect(
      find.text('Universal phone holder · ₱450.00 · 8 in stock'),
      findsOneWidget,
    );
    expect(find.textContaining('₱450.00'), findsOneWidget);
    expect(find.text('Shopee'), findsNothing);

    await tester.tap(find.text('View shop'));
    await tester.pumpAndSettle();
    expect(
      find.text('Available shops for Universal phone holder'),
      findsOneWidget,
    );
    expect(find.text('8 in stock'), findsOneWidget);
  });

  testWidgets('motorcycle parts catalog selects and lists vehicle parts', (
    WidgetTester tester,
  ) async {
    const vehicle = VehiclePartsVariant(
      brand: 'Honda',
      model: 'Beat',
      variant: 'Playful',
      categories: [
        VehiclePartsCategory(
          name: 'Engine',
          parts: ['Engine oil', 'CVT drive belt'],
        ),
        VehiclePartsCategory(name: 'Electrical', parts: ['12-V battery']),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MotorcyclePartsCatalogPage(
          catalogOverride: Future.value([vehicle]),
          initialCategory: 'Engine',
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final brandLogo = find.byKey(const ValueKey('vehicle-BRAND-honda'));
    expect(brandLogo, findsOneWidget);
    expect(
      find.descendant(of: brandLogo, matching: find.byType(Text)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: brandLogo,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              _assetNameOf(widget.image) == 'assets/brands/honda.png',
        ),
      ),
      findsOneWidget,
    );
    final brandTile = tester.widget<Material>(
      find.descendant(of: brandLogo, matching: find.byType(Material)),
    );
    expect(brandTile.color, Colors.white);
    expect(
      (brandTile.shape! as RoundedRectangleBorder).side.color,
      const Color(0xFF277C78),
    );
    expect(find.text('Honda Beat Playful'), findsOneWidget);
    expect(find.text('3 listed parts across 2 categories'), findsNothing);
    expect(find.text('2 listed parts'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            _assetNameOf(widget.image) ==
                'assets/motorcycles/honda_beat_playful.png',
      ),
      findsNWidgets(2),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Engine oil'), findsOneWidget);
    expect(find.text('CVT drive belt'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            _assetNameOf(widget.image)
                    ?.startsWith('assets/vehicle_parts/engine/') ==
                true,
      ),
      findsNWidgets(2),
    );

    expect(find.text('Add image'), findsNWidgets(2));
    expect(find.textContaining('Lubricates engine components'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('part-description-Engine-CVT drive belt')),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('part-image-box-engine_oil.png')),
      ),
      const Size(92, 92),
    );
    final buyButton = find.byKey(
      const ValueKey('buy-Honda Beat Playful Engine oil'),
    );
    await tester.ensureVisible(buyButton);
    await tester.pumpAndSettle();
    await tester.tap(buyButton);
    await tester.pumpAndSettle();
    expect(
      find.text('Where to buy Honda Beat Playful Engine oil'),
      findsOneWidget,
    );
    expect(find.text('Shopee'), findsOneWidget);
    expect(find.text('Lazada'), findsOneWidget);
  });

  testWidgets('Buy options only dismiss from an explicit dialog action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuyOptionsButton(
            store: TemporaryShopStore(),
            productQuery: 'Universal phone holder',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buy'));
    await tester.pumpAndSettle();
    expect(find.text('MotoScan Demo Parts'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('MotoScan Demo Parts'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('MotoScan Demo Parts'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('MotoScan Demo Parts'), findsNothing);
  });

  testWidgets('home hides the motorcycle shortcut and opens the shop tab', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    expect(find.text('Browse parts by motorcycle'), findsNothing);
    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    expect(find.text('MotoScan Shop'), findsOneWidget);
  });

  testWidgets('accessory and maintenance cards open their catalogs', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    await tester.ensureVisible(find.text('Accessories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accessories').first);
    await tester.pumpAndSettle();

    expect(find.text('32 accessory groups · 296 choices'), findsOneWidget);
    await tester.tap(find.text('Helmet'));
    await tester.pumpAndSettle();
    expect(find.text('Full-face helmet'), findsOneWidget);
    expect(find.textContaining('compatibility'), findsNothing);
    expect(find.text('Add an image to this choice'), findsWidgets);
    final helmetCard = find.byKey(
      const ValueKey('catalog-choice-Full-face helmet'),
    );
    expect(helmetCard, findsOneWidget);
    final helmetPlaceholder = find.descendant(
      of: helmetCard,
      matching: find.text('Add an image to this choice'),
    );
    final helmetName = find.descendant(
      of: helmetCard,
      matching: find.text('Full-face helmet'),
    );
    expect(
      tester.getTopLeft(helmetPlaceholder).dx,
      lessThan(tester.getTopLeft(helmetName).dx),
    );
    expect(find.text('Buy'), findsWidgets);

    await tester.tap(find.byTooltip('Back to home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maintenance').first);
    await tester.pumpAndSettle();

    expect(find.text('20 maintenance items · 209 choices'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Engine Oil'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engine Oil'));
    await tester.pumpAndSettle();
    expect(find.text('AVAILABLE CHOICES'), findsOneWidget);
    expect(find.text('Mineral oil'), findsOneWidget);
    expect(find.text('JASO MB'), findsOneWidget);
    expect(find.textContaining('compatibility'), findsNothing);
    expect(find.text('Add an image to this choice'), findsNWidgets(13));
    expect(find.text('Buy'), findsWidgets);
    expect(find.text('Maintenance record fields'), findsNothing);
    expect(
      find.textContaining('Choices are maintenance-supply candidates'),
      findsNothing,
    );
    expect(find.text('Suggested accessory listing fields'), findsNothing);
  });

  testWidgets('scan tab clearly describes the photo preview limitation', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Photo preview works here. AI part recognition still needs a service connection.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('scan tab previews a captured photo', (
    WidgetTester tester,
  ) async {
    final photoBytes = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAPSURBVBhXY1CvqfjPgAwAH2MCG8SNA3oAAAAASUVORK5CYII=',
      ),
    );
    ImageSource? requestedSource;

    await tester.pumpWidget(
      MaterialApp(
        home: IdentifyPage(
          pickImage: (source) async {
            requestedSource = source;
            return XFile.fromData(
              photoBytes,
              name: 'part.png',
              mimeType: 'image/png',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final takePhoto = find.byKey(const ValueKey('identify-take-photo'));
    await tester.ensureVisible(takePhoto);
    await tester.pumpAndSettle();
    await tester.tap(takePhoto);
    await tester.pumpAndSettle();

    expect(requestedSource, ImageSource.camera);
    expect(
      find.byKey(const ValueKey('identify-photo-preview')),
      findsOneWidget,
    );
    expect(find.text('Photo ready to review'), findsOneWidget);
    expect(
      find.text(
        'Photo preview ready. AI part recognition is not connected yet.',
      ),
      findsOneWidget,
    );

    final removePhoto = find.byKey(const ValueKey('identify-remove-photo'));
    await tester.ensureVisible(removePhoto);
    await tester.pumpAndSettle();
    await tester.tap(removePhoto);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('identify-photo-preview')), findsNothing);
    expect(find.text('Start with a clear photo'), findsOneWidget);
  });

  testWidgets('camera page explains when no camera is available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CameraCapturePage(cameraLister: () async => const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Camera unavailable'), findsOneWidget);
    expect(find.text('No camera was found on this device.'), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-retry-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('camera-fallback-button')),
      findsOneWidget,
    );
  });

  testWidgets('scan controls stay readable in the desktop phone preview', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1365, 630);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MotoScanApp());
    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();

    final takePhoto = find.byKey(const ValueKey('identify-take-photo'));
    final uploadPhoto = find.byKey(const ValueKey('identify-upload-photo'));
    expect(takePhoto, findsOneWidget);
    expect(uploadPhoto, findsOneWidget);
    expect(tester.getSize(takePhoto).height, greaterThanOrEqualTo(46));
    expect(tester.getSize(uploadPhoto).height, greaterThanOrEqualTo(46));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop frame scales to smaller laptop viewports', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            DesktopPhoneFrame(child: child ?? const SizedBox.shrink()),
        home: const MotoScanAuthPage(),
      ),
    );
    await tester.pumpAndSettle();

    final frame = find.byKey(const ValueKey('desktop-phone-frame'));
    final cameraCutout = find.byKey(const ValueKey('desktop-camera-cutout'));
    final loginHeading = find.text('Shop owner access');

    expect(find.byType(DesktopPhoneFrame), findsOneWidget);
    expect(frame, findsOneWidget);
    expect(tester.getSize(frame).width, lessThanOrEqualTo(430));
    expect(tester.getSize(frame).width, greaterThan(230));
    expect(
      tester.getTopLeft(loginHeading).dy,
      greaterThan(tester.getBottomLeft(cameraCutout).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop window fits the app inside a safe phone frame', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MotoScanApp());
    await tester.pumpAndSettle();

    final frame = find.byKey(const ValueKey('desktop-phone-frame'));
    final cameraCutout = find.byKey(const ValueKey('desktop-camera-cutout'));
    final loginHeading = find.text('Browse parts');

    expect(find.byType(DesktopPhoneFrame), findsOneWidget);
    expect(frame, findsOneWidget);
    expect(tester.getSize(frame).width, lessThanOrEqualTo(430));
    expect(
      tester.getTopLeft(loginHeading).dy,
      greaterThan(tester.getBottomLeft(cameraCutout).dy),
    );
    expect(tester.takeException(), isNull);

    await _pumpIntoMotoScan(tester);
    for (final element in tester.allElements) {
      final renderObject = element.renderObject;
      if (renderObject is! RenderFlex ||
          renderObject.direction != Axis.horizontal ||
          !renderObject.hasSize) {
        continue;
      }
      var child = renderObject.firstChild;
      while (child != null) {
        final parentData = child.parentData! as FlexParentData;
        child = parentData.nextSibling;
      }
    }
    final homeLayoutException = tester.takeException();
    expect(
      homeLayoutException,
      isNull,
      reason: homeLayoutException is FlutterError
          ? homeLayoutException.toStringDeep()
          : '$homeLayoutException',
    );
  });
}
