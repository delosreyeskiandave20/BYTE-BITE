import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/data/accessories_maintenance_catalog.dart';
import 'package:flutter_application_1/data/design_catalog.dart';
import 'package:flutter_application_1/data/catalog_images.dart';
import 'package:flutter_application_1/data/choice_descriptions.dart';
import 'package:flutter_application_1/data/part_descriptions.dart';
import 'package:flutter_application_1/data/motorcycle_specs.dart';
import 'package:flutter_application_1/data/online_stores.dart';
import 'package:flutter_application_1/data/item_specs.dart';
import 'package:flutter_application_1/data/parts_catalog.dart';
import 'package:flutter_application_1/data/temporary_shop_store.dart';
import 'package:flutter_application_1/data/vehicle_images.dart';
import 'package:flutter_application_1/data/vehicle_parts_catalog.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screens/auth_page.dart';
import 'package:flutter_application_1/widgets/motoscan_wordmark.dart';
import 'package:flutter_application_1/screens/camera_capture_page.dart';
import 'package:flutter_application_1/screens/catalog_page.dart';
import 'package:flutter_application_1/screens/identify_page.dart';
import 'package:flutter_application_1/screens/motorcycle_parts_catalog_page.dart';
import 'package:flutter_application_1/screens/motorcycle_specs_page.dart';
import 'package:flutter_application_1/screens/online_store_page.dart';
import 'package:flutter_application_1/screens/parts_catalog_page.dart';
import 'package:flutter_application_1/screens/shop_page.dart';
import 'package:flutter_application_1/screens/shop_owner_dashboard_page.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/widgets/buy_options_button.dart';
import 'package:flutter_application_1/widgets/desktop_phone_frame.dart';
import 'package:flutter_application_1/widgets/vehicle_variant_carousel.dart';

import 'fake_owner_auth.dart';

/// The bundled asset an [Image] shows, unwrapping the [ResizeImage] that
/// `cacheWidth` adds; null for non-asset images.
/// The size shown in the Sizes page's result card.
String? _specValue(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('spec-value'))).data;

String? _assetName(Image image) {
  var provider = image.image;
  if (provider is ResizeImage) provider = provider.imageProvider;
  return provider is AssetImage ? provider.assetName : null;
}

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

    expect(find.byType(MotoScanWordmark), findsOneWidget);
    expect(find.bySemanticsLabel('MotoScan'), findsOneWidget);
    expect(find.byTooltip('Search parts'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsNothing);
    expect(find.text('Search for a part'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome front page opens the home tab', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MotoScanApp(showWelcome: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('welcome-hero-image')), findsOneWidget);
    expect(find.text('The right parts for your ride.'), findsNothing);
    expect(find.text('Browse parts'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('welcome-get-started')), findsNothing);
    expect(find.text('Browse parts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome front page fits a small phone with large text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MotoScanApp(showWelcome: true));
    await tester.pumpAndSettle();

    final layoutException = tester.takeException();
    expect(
      layoutException,
      isNull,
      reason: layoutException is FlutterError
          ? layoutException.toStringDeep()
          : '$layoutException',
    );
    final getStarted = find.byKey(const ValueKey('welcome-get-started'));
    await tester.ensureVisible(getStarted);
    await tester.pumpAndSettle();
    await tester.tap(getStarted);
    await tester.pumpAndSettle();
    expect(find.text('Browse parts'), findsOneWidget);
  });

  testWidgets('login page shows the MotoScan logo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MotoScanAuthPage()));

    expect(find.byKey(const ValueKey('motoscan-logo')), findsOneWidget);
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

  test('vehicle catalog contains the 45 model records', () {
    final modelCount = vehicleCatalog.values.fold<int>(
      0,
      (count, models) => count + models.length,
    );

    expect(modelCount, 45);
    expect(vehicleCatalog.keys, ['Honda', 'Yamaha', 'Suzuki', 'Kawasaki']);
    expect(
      vehicleCatalog.values
          .expand((models) => models.values)
          .expand((variants) => variants)
          .length,
      69,
    );
  });

  test('parts catalog has a record for every catalog variant', () async {
    final catalog = await loadVehiclePartsCatalog();
    // Model spellings differ between the two sources ("Beat" vs "BeAT"), so
    // compare how many variants each brand has.
    final expected = {
      for (final brand in vehicleCatalog.entries)
        brand.key: brand.value.values.expand((variants) => variants).length,
    };
    final actual = <String, int>{};
    for (final vehicle in catalog) {
      actual[vehicle.brand] = (actual[vehicle.brand] ?? 0) + 1;
    }

    expect(catalog, hasLength(69));
    expect(actual, expected);
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

      expect(variantCount, 69);
      expect(vehicleVariantImageAssets, hasLength(69));
    },
  );

  test(
    'motorcycle parts catalog contains all supplied variant records',
    () async {
      final catalog = await loadVehiclePartsCatalog();

      expect(catalog, hasLength(69));
      expect(
        catalog.fold<int>(0, (total, vehicle) => total + vehicle.partCount),
        5225,
      );
      final beat = catalog.firstWhere(
        (vehicle) =>
            vehicle.brand == 'Honda' &&
            vehicle.model == 'Beat' &&
            vehicle.variant == 'Playful',
      );
      expect(beat.partCount, 76);
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

  test('maintenance has all 24 items and their supplied choices', () {
    expect(maintenanceItemCount, 24);
    expect(maintenanceChoiceCount, 244);
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
      'Cables',
      'Gaskets and Seals',
      'Engine Tune-Up Items',
      'Workshop Tools',
    ]);
    expect(
      maintenanceGroups
          .expand((group) => group.itemChoices.values)
          .every((choices) => choices.isNotEmpty),
      isTrue,
    );
  });

  test('accessories has all supplied groups and unique choices', () {
    expect(accessoryItemCount, 35);
    expect(accessoryChoiceCount, 317);
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
      'Body Armor and Protective Gear',
      'Neck, Face and Base Layers',
      'Camera and Recording',
    ]);

    final choices = accessoryGroups
        .expand((group) => group.itemChoices[group.title] ?? const <String>[])
        .toList();
    expect(choices, hasLength(317));
    expect(choices.toSet(), hasLength(317));
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
    expect(find.text('Design ideas'), findsOneWidget);
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
    expect(find.text('₱1,850.00'), findsOneWidget);
    expect(find.textContaining('Temporary demo:'), findsNothing);

    // Online marketplaces are a fallback listed after the local shops.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('marketplace-Shopee')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Shop online'), findsOneWidget);
    expect(find.byKey(const ValueKey('marketplace-Lazada')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('marketplace-Shopee'))).dy,
      greaterThan(tester.getTopLeft(find.text('MotoScan Demo Parts')).dy),
    );
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
    expect(find.text('Out of stock'), findsOneWidget);

    await store.updateProduct(
      ownerEmail: 'test-owner@example.com',
      productId: product.id,
      description: product.description,
      price: product.price,
      quantity: 0,
    );
    await tester.pumpAndSettle();
    expect(find.text('Out of stock'), findsWidgets);
    expect(find.text('3 in stock'), findsNothing);
    expect(find.text('0 in stock'), findsNothing);
  });

  testWidgets('owner adds an item with photos and motorcycles, edits stock', (
    WidgetTester tester,
  ) async {
    var didFinishEditing = false;
    final uploads = _FakePhotoStorage();
    final store = ShopStore(ownerAuth: FakeOwnerAuth(), photoStorage: uploads);
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
          specRows: parseItemSpecs(File(itemSpecsAssetPath).readAsStringSync()),
          pickPhotos: (source, limit) async => [
            PickedPhoto(bytes: _onePixelPng, extension: 'png'),
            PickedPhoto(bytes: _onePixelPng, extension: 'png'),
          ],
        ),
      ),
    );

    expect(find.textContaining('Temporary demo only'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Add Item'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    // 1 Category → 2 Part → 3 Details.
    await tester.tap(find.byKey(const ValueKey('category-Body Parts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('part-Handlebar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('proceed')));
    await tester.pumpAndSettle();
    expect(find.text('Body Parts › Handlebar'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-item-add-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product name *'),
      'Brake lever',
    );
    await tester.tap(find.byKey(const ValueKey('condition-New')));
    await tester.enterText(find.byKey(const ValueKey('add-item-price')), '200');
    await tester.enterText(
      find.byKey(const ValueKey('add-item-quantity')),
      '2',
    );
    await tester.pumpAndSettle();
    final details = find
        .descendant(
          of: find.byKey(const ValueKey('step-details')),
          matching: find.byType(Scrollable),
        )
        .first;
    for (final model in ['Honda BeAT', 'Honda Click 125i']) {
      await tester.enterText(find.byKey(const ValueKey('fit-search')), model);
      await tester.pumpAndSettle();
      final box = find.byKey(ValueKey('fit-model-$model'));
      await tester.scrollUntilVisible(box, 200, scrollable: details);
      await tester.pumpAndSettle();
      await tester.tap(box);
      await tester.pumpAndSettle();
    }
    final post = find.byKey(const ValueKey('add-item-post'));
    await tester.scrollUntilVisible(post, 200, scrollable: details);
    await tester.pumpAndSettle();
    await tester.tap(post);
    await tester.pumpAndSettle();
    expect(find.text('Item posted!'), findsOneWidget);
    await tester.tap(find.text('View my items'));
    await tester.pumpAndSettle();
    final added = store.shopForOwner('test-owner@example.com')!.products.last;
    expect(added.name, 'Brake lever');
    expect(added.category, 'Body Parts');
    expect(added.condition, 'New');
    expect(added.quantity, 2);
    expect(added.motorcycles, ['Honda BeAT', 'Honda Click 125i']);
    // Both photos were uploaded; the first is the main image.
    expect(uploads.count, 2);
    expect(added.imageUrl, 'https://photos.example.com/1.png');
    expect(added.photoUrls, ['https://photos.example.com/2.png']);

    await tester.scrollUntilVisible(
      find.text('Brake lever'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Brake lever'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Brake lever'), findsOneWidget);
    // Replace the cover photo from the edit sheet.
    final changePhoto = find.byKey(const ValueKey('edit-product-change-photo'));
    await tester.ensureVisible(changePhoto);
    await tester.pumpAndSettle();
    await tester.tap(changePhoto);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(find.text('The new photo uploads when you save.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description or information'),
      'Replacement brake lever.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price (PHP)'),
      '275',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '0');
    await tester.ensureVisible(find.text('Save product details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save product details'));
    await tester.pumpAndSettle();

    final product = store.shopForOwner('test-owner@example.com')!.products.last;
    expect(product.description, 'Replacement brake lever.');
    expect(uploads.count, 3);
    expect(product.imageUrl, 'https://photos.example.com/3.png');
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
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('gallery-brand-Kawasaki')),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Barako II'), findsOneWidget);

    // Kawasaki comes last, then the carousel wraps to Honda.
    final remainingVariantCount = vehicleCatalog['Kawasaki']!.values
        .expand((variants) => variants)
        .length;
    await advanceVariants(remainingVariantCount);
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
            find.byKey(const ValueKey('gallery-brand-Kawasaki')),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Versys 650'), findsOneWidget);
    for (final removed in ['RUSI', 'MotorStar']) {
      expect(find.byKey(ValueKey('gallery-brand-$removed')), findsNothing);
    }
  });

  test('design photos are found by item file name', () async {
    expect(
      designImageSlug('LED Daytime Running Light (DRL)'),
      'led_daytime_running_light_drl',
    );
    expect(designImageSlug('Body Stickers'), 'body_stickers');

    final images = await loadDesignImages(rootBundle);
    expect(images['led_headlight'], 'assets/design/led_headlight.png');
    expect(images, hasLength(greaterThanOrEqualTo(5)));
    final allSlugs = designGroups
        .expand((group) => group.items)
        .map(designImageSlug)
        .toList();
    // Every photo must belong to an item, and no two items share a name.
    expect(allSlugs.toSet(), hasLength(allSlugs.length));
    expect(allSlugs, containsAll(images.keys));
  });

  test('maintenance photos are named by group and choice', () async {
    expect(
      maintenanceImageSlug('Air Filter', 'Paper filter'),
      'air_filter-paper_filter',
    );
    expect(
      maintenanceImageSlug('Oil Filter or Oil Strainer', 'Paper filter'),
      'oil_filter_or_oil_strainer-paper_filter',
    );

    final allSlugs = [
      for (final group in maintenanceGroups)
        for (final choice in group.itemChoices.values.expand((c) => c))
          maintenanceImageSlug(group.title, choice),
    ];
    expect(allSlugs, hasLength(maintenanceChoiceCount));
    expect(allSlugs.toSet(), hasLength(allSlugs.length));

    // Every bundled photo must belong to a choice, so a typo fails here
    // instead of silently showing an icon.
    final photos = await loadMaintenanceImages(rootBundle);
    expect(allSlugs, containsAll(photos.keys));
  });

  testWidgets('design items show their bundled photo, not the group icon', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    final seatRow = find.byKey(const ValueKey('design-row-Seat Designs'));
    await tester.scrollUntilVisible(
      seatRow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: seatRow,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              (_assetName(widget)?.startsWith('assets/design/') ?? false),
        ),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: seatRow,
        matching: find.byIcon(Icons.event_seat_outlined),
      ),
      findsNothing,
    );
    expect(find.text('Add an image to this choice'), findsNothing);
  });

  testWidgets('design buy buttons show shops without a detail panel', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    // Each design group is a sideways row on Home; its first card is built.
    expect(find.text('Design ideas'), findsOneWidget);
    for (final group in designGroups) {
      final item = group.items.first;
      expect(find.text(group.title), findsOneWidget);
      expect(find.byKey(ValueKey('design-image-$item')), findsOneWidget);
      expect(find.byKey(ValueKey('buy-$item')), findsOneWidget);
    }
    expect(find.text('Add an image to this choice'), findsNothing);

    await tester.ensureVisible(find.text('LED Headlight'));
    await tester.pumpAndSettle();
    final lightingRow = find.descendant(
      of: find.byKey(const ValueKey('design-row-Lighting Designs')),
      matching: find.byType(Scrollable),
    );
    for (final entry in {
      'LED Headlight': 'assets/design/led_headlight.png',
      'LED Tail Light': 'assets/design/led_tail_light.png',
      'LED Signal Light': 'assets/design/led_signal_light.png',
      'LED Turn Signal': 'assets/design/led_turn_signal.png',
      'LED Daytime Running Light (DRL)':
          'assets/design/led_daytime_running_light_drl.png',
    }.entries) {
      final card = find.byKey(ValueKey('design-image-${entry.key}'));
      await tester.scrollUntilVisible(card, 120, scrollable: lightingRow);
      expect(
        find.descendant(
          of: card,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Image && _assetNameOf(widget.image) == entry.value,
          ),
        ),
        findsOneWidget,
      );
    }
    final headlightBuy = find.byKey(const ValueKey('buy-LED Headlight'));
    await tester.scrollUntilVisible(
      headlightBuy,
      -120,
      scrollable: lightingRow,
    );
    // Centre the button so the bottom navigation bar cannot cover it.
    await Scrollable.ensureVisible(
      tester.element(headlightBuy),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(headlightBuy);
    await tester.pumpAndSettle();

    expect(find.text('Where to buy LED Headlight'), findsOneWidget);
    expect(find.text('No local shop has this item in stock.'), findsOneWidget);
    expect(find.byKey(const ValueKey('marketplace-Shopee')), findsOneWidget);
    expect(find.byKey(const ValueKey('marketplace-Lazada')), findsOneWidget);
    expect(find.text('WHERE TO FIND THIS PRODUCT'), findsNothing);
  });

  testWidgets('search tab filters the sample catalog', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    await tester.tap(find.byTooltip('Search parts'));
    await tester.pumpAndSettle();

    expect(find.text('Parts library'), findsOneWidget);
    expect(find.text('7 matches'), findsNothing);
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
    expect(find.byKey(const ValueKey('marketplace-Shopee')), findsOneWidget);
    expect(find.byKey(const ValueKey('marketplace-Lazada')), findsOneWidget);
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
    expect(find.byKey(const ValueKey('marketplace-Shopee')), findsNothing);

    await tester.tap(find.text('View shop'));
    await tester.pumpAndSettle();
    expect(
      find.text('Available shops for Universal phone holder'),
      findsOneWidget,
    );
    expect(find.text('8 in stock'), findsOneWidget);
  });

  testWidgets('shop tab lists online stores and filters them by search', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OnlineStoresSection(searchQuery: ''),
          ),
        ),
      ),
    );
    for (final store in onlineStores) {
      expect(find.text(store.name), findsOneWidget);
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OnlineStoresSection(searchQuery: 'nmax brake pad'),
          ),
        ),
      ),
    );
    expect(find.text('Sh0pNStyle'), findsOneWidget);
    expect(find.text('Bike World 2020'), findsNothing);

    await tester.tap(find.text('Sh0pNStyle'));
    await tester.pumpAndSettle();
    expect(find.text('NMAX brake pad front and rear V1 V2 V3'), findsOneWidget);
    expect(find.text('Buy'), findsWidgets);
  });

  test('online store item links open that store\'s own search', () {
    final store = onlineStores.first;
    final uri = store.itemUri(store.items.first);
    expect(uri.host, 'www.lazada.com.ph');
    expect(uri.path, '/${store.slug}/');
    expect(uri.queryParameters['q'], store.items.first.name);
  });

  testWidgets('tapping a photo opens a zoomable full-screen view', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MotorcycleSpecsPage()));
    await tester.pumpAndSettle();

    final photo = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('spec-image-'),
    );
    await tester.ensureVisible(photo);
    await tester.pumpAndSettle();
    await tester.tap(photo);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byKey(const ValueKey('zoomed-image')), findsOneWidget);

    await tester.tap(find.byTooltip('Close zoomed image'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  test(
    'every accessory, maintenance and motorcycle part has a description',
    () async {
      for (final group in [...maintenanceGroups, ...accessoryGroups]) {
        for (final choice in group.itemChoices.values.expand((c) => c)) {
          expect(
            choiceDescription(group.title, choice),
            isNotNull,
            reason: '${group.title} / $choice',
          );
        }
      }
      for (final vehicle in await loadVehiclePartsCatalog()) {
        for (final category in vehicle.categories) {
          for (final part in category.parts) {
            expect(partDescription(part), isNotNull, reason: part);
          }
        }
      }
    },
  );

  test('every spec motorcycle and listed value has a bundled photo', () async {
    expect(motorcycleSpecs, hasLength(37));
    for (final bike in motorcycleSpecs) {
      await rootBundle.load(bike.imageAsset);
      for (final item in SpecItem.values) {
        final value = bike.valueOf(item);
        if (value == null) continue;
        final photo = specImageAsset(item, value);
        if (photo != null) await rootBundle.load(photo);
      }
    }
  });

  testWidgets('specs page shows the chosen item for the chosen motorcycle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MotorcycleSpecsPage()));
    await tester.pumpAndSettle();

    // First motorcycle and Front tire are selected by default.
    expect(_specValue(tester), '80/90-14');

    await tester.tap(find.byKey(const ValueKey('spec-item-Spark plug')));
    await tester.pumpAndSettle();
    expect(_specValue(tester), 'NGK CPR7EA-9');

    final nmax = find.byKey(const ValueKey('spec-bike-Yamaha NMAX 155'));
    await tester.scrollUntilVisible(
      nmax,
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('spec-bike-row')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(nmax);
    await tester.pumpAndSettle();
    expect(_specValue(tester), 'NGK CPR8EA-9');

    await tester.tap(find.byKey(const ValueKey('spec-item-Engine oil')));
    await tester.pumpAndSettle();
    expect(_specValue(tester), 'Capacity: 1.0 L');

    // A value missing from the table says so instead of showing a photo.
    final beat = find.byKey(const ValueKey('spec-bike-Honda BeAT'));
    await tester.scrollUntilVisible(
      beat,
      -200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('spec-bike-row')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(beat);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Not listed for this motorcycle'),
      findsOneWidget,
    );
  });

  testWidgets('maintenance groups sit in a sideways row above the choices', (
    WidgetTester tester,
  ) async {
    final store = TemporaryShopStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CatalogPage(type: 'maintenance', shopStore: store),
      ),
    );
    await tester.pumpAndSettle();

    final first = find.byKey(const ValueKey('catalog-group-Engine Oil'));
    final second = find.byKey(
      const ValueKey('catalog-group-Oil Filter or Oil Strainer'),
    );
    expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
    // The first group's choices show without any tap.
    expect(find.text('Mineral oil'), findsOneWidget);

    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(find.text('Spin-on filter'), findsOneWidget);
    expect(find.text('Mineral oil'), findsNothing);
  });

  test('demo shop products show bundled photos', () async {
    final store = TemporaryShopStore();
    addTearDown(store.dispose);
    final demo = store.shops.singleWhere(
      (shop) => shop.name == 'MotoScan Demo Parts',
    );

    expect(demo.products, hasLength(3));
    for (final product in demo.products) {
      expect(product.hasImage, isTrue, reason: product.name);
      expect(product.imageProvider, isA<AssetImage>());
      await rootBundle.load(product.imageAsset);
    }

    // A photo link set by the owner replaces the bundled photo.
    final linked = demo.products.first.copyWith(
      imageUrl: 'https://example.com/holder.jpg',
    );
    expect(linked.imageProvider, isA<NetworkImage>());
    expect(linked.imageAsset, demo.products.first.imageAsset);
  });

  testWidgets('motorcycle parts catalog selects and lists vehicle parts', (
    WidgetTester tester,
  ) async {
    final store = TemporaryShopStore();
    addTearDown(store.dispose);
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
          shopStore: store,
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
      AppColors.primary,
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
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Engine oil'), findsOneWidget);
    expect(find.text('CVT drive belt'), findsOneWidget);
    final partImageAssets = tester
        .widgetList<Image>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                _assetNameOf(widget.image)
                        ?.startsWith('assets/vehicle_parts/beat_playful/') ==
                    true,
          ),
        )
        .map((image) => _assetNameOf(image.image))
        .toSet();
    final partImages = tester.widgetList<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            _assetNameOf(widget.image)
                    ?.startsWith('assets/vehicle_parts/beat_playful/') ==
                true,
      ),
    );
    expect(partImageAssets, {
      'assets/vehicle_parts/beat_playful/engine_oil.jpg',
      'assets/vehicle_parts/beat_playful/cvt_drive_belt.png',
    });
    expect(partImages, isNotEmpty);
    expect(partImages.every((image) => image.fit == BoxFit.contain), isTrue);

    expect(find.text('Add image'), findsNothing);
    expect(
      find.textContaining('lubricates the engine, gearbox and clutch'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('part-description-Engine-CVT drive belt')),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('part-image-box-engine_oil.jpg')),
      ),
      const Size(92, 92),
    );

    // Categories are side-by-side tabs; only the chosen one's parts show.
    expect(find.text('12-V battery'), findsNothing);
    final electricalTab = find.byKey(
      const ValueKey('part-category-Electrical'),
    );
    expect(
      tester.getTopLeft(electricalTab).dy,
      tester.getTopLeft(find.byKey(const ValueKey('part-category-Engine'))).dy,
    );
    await tester.tap(electricalTab);
    await tester.pumpAndSettle();
    expect(find.text('12-V battery'), findsOneWidget);
    expect(find.text('Engine oil'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('part-category-Engine')));
    await tester.pumpAndSettle();

    final shopButton = find.byKey(const ValueKey('go-to-shop-Engine oil'));
    await tester.ensureVisible(shopButton);
    await tester.pumpAndSettle();
    await tester.tap(shopButton);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('MotoScan Shop'), findsOneWidget);
    expect(find.text('Available shops for Engine oil'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Engine oil',
    );
  });

  test('Honda Beat Playful body photos are bundled by part name', () async {
    const bodyParts = [
      'Leg shield/floor panel',
      'Front fender',
      'Rear fender/mudguard',
      'Seat assembly/seat cover',
      'Grab rail',
      'Side mirror',
      'Headlight assembly',
      'Tail-light/turn-signal assembly',
    ];

    for (final part in bodyParts) {
      final asset = vehiclePartImageAsset(
        brand: 'Honda',
        model: 'Beat',
        variant: 'Playful',
        category: 'Body',
        part: part,
      );
      await rootBundle.load(asset!);
    }
  });

  test(
    'Honda Click125 Standard photos match supplied parts and order',
    () async {
      final catalog = await loadVehiclePartsCatalog();
      final click125 = catalog.firstWhere(
        (vehicle) =>
            vehicle.brand == 'Honda' &&
            vehicle.model == 'Click125' &&
            vehicle.variant == 'Standard',
      );
      const imageFiles = <String, String>{
        'Engine oil': 'engine_oil.png',
        'Oil screen/filter': 'oil_screen_filter.jpg',
        'Drain-plug washer': 'drain_plug_washer.png',
        'Air filter': 'air_filter.png',
        'Spark plug': 'spark_plug.webp',
        'CVT drive belt': 'cvt_drive_belt.jpg',
        'Variator roller set': 'variator_roller_set.jpg',
        'CVT slider set': 'cvt_slider_set.png',
        'Clutch shoe set': 'clutch_shoe_set.png',
        'Final-drive gear oil': 'final_drive_gear_oil.png',
        '12-V battery': '12_v_battery.jpg',
        'Main fuse': 'main_fuse.png',
        'Starter relay': 'starter_relay.png',
        'Regulator/rectifier': 'regulator_rectifier.png',
        'Stator/charging coil': 'stator_charging_coil.webp',
        'Spark-plug cap': 'spark_plug_cap.jpg',
        'Ignition coil': 'ignition_coil.png',
        'ECU/PGM-FI unit': 'ecu_pgm_fi_unit.png',
        'Oxygen sensor': 'oxygen_sensor.png',
        'Brake-light switch': 'brake_light_switch.png',
        'Front-fork oil': 'front_fork_oil.jpg',
        'Fork oil seal': 'fork_oil_seal.png',
        'Fork dust seal': 'fork_dust_seal.png',
        'Front fork spring': 'front_fork_spring.png',
        'Rear shock absorber': 'rear_shock_absorber.png',
        'Rear-shock bushing': 'rear_shock_bushing.png',
        'Steering-head bearing': 'steering_head_bearing.png',
        'Swingarm/pivot bushing': 'swingarm_pivot_bushing.png',
        'Side-stand switch': 'side_stand_switch.png',
        'Front tire': 'front_tire.png',
        'Rear tire': 'rear_tire.png',
        'Front wheel bearing': 'front_wheel_bearing.jpg',
        'Rear wheel bearing': 'rear_wheel_bearing.png',
        'Wheel oil seal': 'wheel_oil_seal.jpg',
        'Front axle/collar': 'front_axle_collar.png',
        'Rear axle/collar': 'rear_axle_collar.png',
        'Tubeless valve stem': 'tubeless_valve_stem.jpg',
        'Brake disc or drum': 'brake_disc_or_drum.png',
        'Tire-pressure valve/core': 'tire_pressure_valve_core.png',
        'Front cowl/fairing': 'front_cowl_fairing.png',
        'Leg shield/floor panel': 'leg_shield_floor_panel.png',
        'Front fender': 'front_fender.jpg',
        'Rear fender/mudguard': 'rear_fender_mudguard.jpg',
        'Side cover': 'side_cover.png',
        'Seat assembly/seat cover': 'seat_assembly_seat_cover.png',
        'Side mirror': 'side_mirror.png',
        'Headlight assembly': 'headlight_assembly.png',
        'Tail-light/turn-signal assembly':
            'tail_light_turn_signal_assembly.png',
      };

      // The supplied photos cover the original 10 parts of each category;
      // parts added later sit after them.
      final orderedParts = click125.categories
          .expand((category) => category.parts.take(10))
          .toList();
      expect([
        ...orderedParts.take(23),
        ...orderedParts.skip(24).take(22),
        ...orderedParts.skip(47).take(3),
      ], imageFiles.keys);

      for (final entry in imageFiles.entries) {
        final category = click125.categories.firstWhere(
          (category) => category.parts.contains(entry.key),
        );
        final asset = vehiclePartImageAsset(
          brand: click125.brand,
          model: click125.model,
          variant: click125.variant,
          category: category.name,
          part: entry.key,
        );
        expect(asset, 'assets/vehicle_parts/click125_standard/${entry.value}');
        await rootBundle.load(asset!);
      }

      expect(
        vehiclePartImageAsset(
          brand: click125.brand,
          model: click125.model,
          variant: click125.variant,
          category: 'Suspension',
          part: 'Fork bushing',
        ),
        'assets/vehicle_parts/click125_standard/fork_bushing.jpg',
      );
      expect(
        vehiclePartImageAsset(
          brand: click125.brand,
          model: click125.model,
          variant: click125.variant,
          category: 'Body',
          part: 'Grab rail',
        ),
        'assets/vehicle_parts/click125_standard/grab_rail.jpg',
      );
    },
  );

  test(
    'Honda Beat Premium reuses only compatible Playful part photos',
    () async {
      const compatibleParts = {
        'Leg shield/floor panel': 'leg_shield_floor_panel.jpg',
        'Rear fender/mudguard': 'rear_fender_mudguard.jpg',
        'Engine oil': 'engine_oil.jpg',
      };

      for (final entry in compatibleParts.entries) {
        final asset = vehiclePartImageAsset(
          brand: 'Honda',
          model: 'Beat',
          variant: 'Premium',
          category: entry.key == 'Engine oil' ? 'Engine' : 'Body',
          part: entry.key,
        );
        expect(asset, 'assets/vehicle_parts/beat_playful/${entry.value}');
        await rootBundle.load(asset!);
      }

      const premiumSpecificParts = {
        'Front fender': 'front_fender.jpg',
        'Grab rail': 'grab_rail.png',
        'Side mirror': 'side_mirror.png',
        'Headlight assembly': 'headlight_assembly.jpg',
        'Tail-light/turn-signal assembly':
            'tail_light_turn_signal_assembly.png',
      };
      for (final entry in premiumSpecificParts.entries) {
        final asset = vehiclePartImageAsset(
          brand: 'Honda',
          model: 'Beat',
          variant: 'Premium',
          category: 'Body',
          part: entry.key,
        );
        expect(asset, 'assets/vehicle_parts/beat_premium/${entry.value}');
        await rootBundle.load(asset!);
      }

      const brakeAsset =
          'assets/vehicle_parts/beat_premium/brake_disc_or_drum.png';
      expect(
        vehiclePartImageAsset(
          brand: 'Honda',
          model: 'Beat',
          variant: 'Premium',
          category: 'Wheels & Tires',
          part: 'Brake disc or drum',
        ),
        brakeAsset,
      );
      await rootBundle.load(brakeAsset);
    },
  );

  test(
    'Click125 Smart Edition and Street use their own body panel photos',
    () async {
      final catalog = await loadVehiclePartsCatalog();
      // These panels differ from the Standard's, so each variant has its own
      // photo instead of borrowing the Standard one.
      const variantBodyParts = [
        'Front cowl/fairing',
        'Leg shield/floor panel',
        'Rear fender/mudguard',
        'Side cover',
        'Seat assembly/seat cover',
      ];

      for (final variant in ['Smart Edition', 'Street']) {
        final click125 = catalog.singleWhere(
          (vehicle) =>
              vehicle.brand == 'Honda' &&
              vehicle.model == 'Click125' &&
              vehicle.variant == variant,
        );
        final bodyParts = click125.categories
            .singleWhere((category) => category.name == 'Body')
            .parts;

        expect(click125.partCount, 76);
        final folder = variant == 'Smart Edition'
            ? 'click125_smart_edition'
            : 'click125_street';
        for (final part in variantBodyParts) {
          expect(bodyParts, contains(part));
          final imageAsset = vehiclePartImageAsset(
            brand: click125.brand,
            model: click125.model,
            variant: click125.variant,
            category: 'Body',
            part: part,
          );
          expect(imageAsset, startsWith('assets/vehicle_parts/$folder/'));
          await rootBundle.load(imageAsset!);
        }

        for (final part in [
          'Front fender',
          'Side mirror',
          'Headlight assembly',
          'Tail-light/turn-signal assembly',
        ]) {
          expect(bodyParts, contains(part));
          final imageAsset = vehiclePartImageAsset(
            brand: click125.brand,
            model: click125.model,
            variant: click125.variant,
            category: 'Body',
            part: part,
          );
          expect(imageAsset, startsWith('assets/vehicle_parts/click125_'));
          await rootBundle.load(imageAsset!);
        }
      }
    },
  );

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

    expect(find.bySemanticsLabel('MotoScan Shop'), findsOneWidget);
  });

  testWidgets('accessory and maintenance cards open their catalogs', (
    WidgetTester tester,
  ) async {
    await _pumpIntoMotoScan(tester);

    await tester.ensureVisible(find.text('Accessories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accessories').first);
    await tester.pumpAndSettle();

    expect(find.text('32 accessory groups · 296 choices'), findsNothing);
    await tester.tap(find.text('Helmet'));
    await tester.pumpAndSettle();
    expect(find.text('Full-face helmet'), findsOneWidget);
    expect(find.textContaining('compatibility'), findsNothing);
    // Every accessory choice has a bundled photo in assets/accessories/.
    expect(
      find.byKey(const ValueKey('choice-image-placeholder')),
      findsNothing,
    );
    final helmetCard = find.byKey(
      const ValueKey('catalog-choice-Full-face helmet'),
    );
    expect(helmetCard, findsOneWidget);
    final helmetPhoto = find.descendant(
      of: helmetCard,
      matching: find.byType(Image),
    );
    expect(helmetPhoto, findsOneWidget);
    expect(
      _assetName(tester.widget<Image>(helmetPhoto)),
      startsWith('assets/accessories/helmet-full_face_helmet.'),
    );
    final helmetName = find.descendant(
      of: helmetCard,
      matching: find.text('Full-face helmet'),
    );
    expect(
      tester.getTopLeft(helmetPhoto).dx,
      lessThan(tester.getTopLeft(helmetName).dx),
    );
    expect(find.text('Buy'), findsWidgets);

    await tester.tap(find.byTooltip('Back to home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maintenance').first);
    await tester.pumpAndSettle();

    expect(find.text('20 maintenance items · 209 choices'), findsNothing);
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
    // Every Engine Oil choice has a bundled photo in assets/maintenance/.
    expect(
      find.byKey(const ValueKey('choice-image-placeholder')),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            (_assetName(widget)?.startsWith('assets/maintenance/engine_oil-') ??
                false),
      ),
      findsNWidgets(13),
    );
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
      findsNothing,
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
    expect(find.text('Photo ready to review'), findsNothing);
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

/// A valid 1×1 PNG.
final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// Records uploads and hands back predictable https URLs.
class _FakePhotoStorage implements ProductPhotoStorage {
  int count = 0;

  @override
  Future<String> upload({
    required String shopId,
    required PickedPhoto photo,
  }) async => 'https://photos.example.com/${++count}.${photo.extension}';
}
