import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/item_details.dart';
import 'package:flutter_application_1/data/item_parts.dart';
import 'package:flutter_application_1/data/item_specs.dart';
import 'package:flutter_application_1/data/part_suggestions.dart';
import 'package:flutter_application_1/data/product_photo_storage.dart';
import 'package:flutter_application_1/screens/add_item_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

final _rows = parseItemSpecs(File(itemSpecsAssetPath).readAsStringSync());

ItemSpecRow _row(String name) =>
    _rows.firstWhere((row) => row.motorcycle == name);

/// A valid 1×1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

Future<List<PickedPhoto>> _twoPhotos(ImageSource source, int limit) async => [
  PickedPhoto(bytes: _png, extension: 'png'),
  PickedPhoto(bytes: _png, extension: 'png'),
];

/// Pushes [AddItemPage] on a tall screen and returns the popped results.
Future<List<AddItemResult?>> _open(
  WidgetTester tester, {
  UrlImageBuilder? imageForUrl,
}) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final results = <AddItemResult?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(
            await Navigator.of(context).push<AddItemResult>(
              MaterialPageRoute(
                builder: (_) => AddItemPage(
                  pickPhotos: _twoPhotos,
                  imageForUrl: imageForUrl,
                  specRows: _rows,
                ),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

Finder _key(String key) => find.byKey(ValueKey(key));

/// Scrolls the details form until [finder] is built, then taps it.
Future<void> _tapInForm(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find
        .descendant(of: _key('step-details'), matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Steps 1 and 2 with a listed part.
Future<void> _choosePart(
  WidgetTester tester,
  String category,
  String part,
) async {
  await tester.tap(_key('category-$category'));
  await tester.pumpAndSettle();
  await tester.tap(_key('part-$part'));
  await tester.pumpAndSettle();
  await tester.tap(_key('proceed'));
  await tester.pumpAndSettle();
}

Future<void> _addGalleryPhotos(WidgetTester tester) async {
  await tester.tap(_key('add-item-add-photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choose from gallery'));
  await tester.pumpAndSettle();
}

/// Photos, condition, price and quantity; motorcycles are left to the test.
Future<void> _fillBasics(WidgetTester tester) async {
  await _addGalleryPhotos(tester);
  await tester.tap(_key('condition-New'));
  await tester.enterText(_key('add-item-price'), '350');
  await tester.enterText(_key('add-item-quantity'), '4');
  await tester.pumpAndSettle();
}

Future<void> _checkModel(WidgetTester tester, String model) async {
  await tester.enterText(_key('fit-search'), model);
  await tester.pumpAndSettle();
  await _tapInForm(tester, _key('fit-model-$model'));
}

Future<void> _post(WidgetTester tester) async {
  await _tapInForm(tester, _key('add-item-post'));
}

void main() {
  test('master table loads all 37 motorcycles', () {
    expect(_rows, hasLength(37));
  });

  test('"—" is unknown and never guessed', () {
    final beat = _row('Honda BeAT');
    expect(beat.valueOf(ItemSpecField.battery), isNull);
    expect(beat.valueOf(ItemSpecField.frontTire)?.value, '80/90-14');
  });

  test('source notes are kept apart from the value', () {
    final raider = _row('Suzuki Raider R150 Fi')
        .valueOf(ItemSpecField.fuelTank)!;
    expect(raider.value, '4.0–4.9 L');
    expect(raider.note, 'sources differ');
  });

  test('categories are the eight required ones in order', () {
    expect(itemCategories, [
      'Engine',
      'Electrical',
      'Suspension',
      'Wheels and Tires',
      'Body Parts',
      'Accessories',
      'Maintenance',
      'Designs',
    ]);
    expect(partsByCategory.keys, itemCategories);
  });

  test('typed names close to a listed part are matched', () {
    expect(closestPart('Sparkplug', 'Engine')?.part, 'Spark plug');
    expect(closestPart('batery', 'Engine')?.part, 'Battery');
    expect(closestPart('Spark plug', 'Engine'), isNull);
    expect(closestPart('Dashcam mount', 'Accessories'), isNull);
  });

  testWidgets('step 1 shows the 8 categories and a step bar', (tester) async {
    await _open(tester);
    expect(find.text('What kind of part are you selling?'), findsOneWidget);
    for (final category in itemCategories) {
      expect(_key('category-$category'), findsOneWidget);
    }
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Part'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('step 2 lists, searches and selects one part', (tester) async {
    await _open(tester);
    await tester.tap(_key('category-Engine'));
    await tester.pumpAndSettle();
    expect(find.text('Which part is it?'), findsOneWidget);
    expect(_key('part-Spark plug'), findsOneWidget);
    expect(_key('part-Battery'), findsNothing);

    // Proceed stays disabled until a part is chosen.
    FilledButton proceed() => tester.widget(_key('proceed'));
    expect(proceed().onPressed, isNull);

    await tester.enterText(_key('part-search'), 'filter');
    await tester.pumpAndSettle();
    expect(_key('part-Spark plug'), findsNothing);
    await tester.tap(_key('part-Air filter'));
    await tester.pumpAndSettle();
    expect(proceed().onPressed, isNotNull);

    // Back keeps the choices.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(_key('category-Engine'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListTile>(
            find.descendant(
              of: _key('part-Air filter'),
              matching: find.byType(ListTile),
            ),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('a close custom name asks "Did you mean"', (tester) async {
    await _open(tester);
    await tester.tap(_key('category-Engine'));
    await tester.pumpAndSettle();
    await tester.tap(_key('part-custom-open'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('part-custom'), 'S');
    await tester.pumpAndSettle();
    expect(find.text('Please type at least 2 letters.'), findsOneWidget);
    await tester.enterText(_key('part-custom'), 'Sparkplug');
    await tester.pumpAndSettle();
    await tester.tap(_key('proceed'));
    await tester.pumpAndSettle();
    expect(find.text('Did you mean Spark plug?'), findsOneWidget);

    await tester.tap(_key('did-you-mean-yes'));
    await tester.pumpAndSettle();
    expect(find.text('Engine › Spark plug'), findsOneWidget);
    expect(find.text('Custom'), findsNothing);
    // The product name starts as the part name.
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Spark plug',
    );
  });

  testWidgets('"No, keep mine" posts a custom part without specs', (
    tester,
  ) async {
    final results = await _open(tester);
    await tester.tap(_key('category-Engine'));
    await tester.pumpAndSettle();
    await tester.tap(_key('part-custom-open'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('part-custom'), 'Sparkplug');
    await tester.pumpAndSettle();
    await tester.tap(_key('proceed'));
    await tester.pumpAndSettle();
    await tester.tap(_key('did-you-mean-no'));
    await tester.pumpAndSettle();
    expect(find.text('Engine › Sparkplug'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);

    await _fillBasics(tester);
    await _checkModel(tester, 'Yamaha NMAX 155');
    expect(find.text('Specs'), findsNothing);
    await _post(tester);
    final item = results.single!;
    expect(item.part, 'Sparkplug');
    expect(item.isCustomPart, isTrue);
    expect(item.specs, isEmpty);
  });

  testWidgets('Post Item shows what is missing', (tester) async {
    final results = await _open(tester);
    await _choosePart(tester, 'Engine', 'Spark plug');
    await _post(tester);
    expect(results, isEmpty);
    expect(find.text('Please add at least 1 photo'), findsOneWidget);
    expect(find.text('Please choose the condition.'), findsOneWidget);
    expect(find.text('Please enter a price above 0.'), findsOneWidget);
    expect(
      find.text('Please enter a whole number, 1 or more.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Please check at least 1 motorcycle, or choose Universal.'),
      300,
      scrollable: find
          .descendant(
            of: _key('step-details'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  });

  testWidgets('specs are saved from the table without a Specs section', (
    tester,
  ) async {
    final results = await _open(tester);
    await _choosePart(tester, 'Engine', 'Spark plug');
    await _fillBasics(tester);
    await _checkModel(tester, 'Yamaha NMAX 155');
    await _checkModel(tester, 'Honda BeAT');
    expect(find.text('2 motorcycles selected'), findsOneWidget);

    expect(find.text('Specs'), findsNothing);
    expect(_key('spec-Yamaha NMAX 155'), findsNothing);

    await _post(tester);
    final item = results.single!;
    expect(item.category, 'Engine');
    expect(item.name, 'Spark plug');
    expect(item.condition, 'New');
    expect(item.price, 350);
    expect(item.quantity, 4);
    expect(item.photos, hasLength(2));
    expect(item.motorcycles, ['Yamaha NMAX 155', 'Honda BeAT']);
    expect(item.fitsAll, isFalse);
    expect(item.specLabel, 'Spark plug');
    // "—" in the table is never guessed, so BeAT has no spec saved.
    expect(item.specs.map((s) => '${s.motorcycle}=${s.value}'), [
      'Yamaha NMAX 155=NGK CPR8EA-9',
    ]);
  });

  testWidgets('Universal disables the model boxes', (tester) async {
    final results = await _open(tester);
    await _choosePart(tester, 'Accessories', 'Phone holder');
    await _fillBasics(tester);
    await _tapInForm(tester, _key('fit-universal'));
    await _tapInForm(tester, _key('fit-toggle'));
    expect(
      tester.widget<CheckboxListTile>(_key('fit-brand-Honda')).enabled,
      isFalse,
    );
    await _post(tester);
    expect(results.single!.fitsAll, isTrue);
    expect(results.single!.motorcycles, isEmpty);
  });

  testWidgets('the motorcycle list opens from search and closes again', (
    tester,
  ) async {
    await _open(tester);
    await _choosePart(tester, 'Accessories', 'Helmet');
    // Hidden until the seller taps the search.
    expect(_key('fit-brand-Honda'), findsNothing);
    await _tapInForm(tester, _key('fit-search'));
    expect(_key('fit-brand-Honda'), findsOneWidget);
    await _tapInForm(tester, _key('fit-model-Honda BeAT'));
    expect(find.text('1 motorcycle selected'), findsOneWidget);

    // Closing keeps the choice and shows it as a chip.
    await _tapInForm(tester, _key('fit-toggle'));
    expect(_key('fit-brand-Honda'), findsNothing);
    expect(_key('fit-chip-Honda BeAT'), findsOneWidget);
    expect(find.text('1 motorcycle selected'), findsOneWidget);

    // Tapping anywhere outside the checklist closes the list too.
    await _tapInForm(tester, _key('fit-search'));
    expect(_key('fit-brand-Honda'), findsOneWidget);
    await _tapInForm(tester, _key('add-item-summary'));
    expect(_key('fit-brand-Honda'), findsNothing);

    // Checking Universal closes it as well.
    await _tapInForm(tester, _key('fit-search'));
    await _tapInForm(tester, _key('fit-universal'));
    expect(_key('fit-brand-Honda'), findsNothing);
  });

  testWidgets('pasting an image URL hides the upload box', (tester) async {
    await _open(tester, imageForUrl: (url) => MemoryImage(_png));
    await _choosePart(tester, 'Accessories', 'Helmet');
    expect(_key('add-item-add-photo'), findsOneWidget);
    await _tapInForm(tester, _key('add-item-url-open'));
    expect(_key('add-item-add-photo'), findsNothing);

    // Going back to uploading brings it back.
    await _tapInForm(tester, _key('add-item-upload-instead'));
    expect(_key('add-item-add-photo'), findsOneWidget);
  });

  testWidgets('photos show a cover, can be reordered and removed', (
    tester,
  ) async {
    await _open(tester);
    await _choosePart(tester, 'Accessories', 'Helmet');
    await _addGalleryPhotos(tester);
    expect(_key('add-item-photo-0'), findsOneWidget);
    expect(_key('add-item-photo-1'), findsOneWidget);
    expect(find.text('Cover'), findsOneWidget);

    await tester.tap(find.byTooltip('Set as cover'));
    await tester.pumpAndSettle();
    expect(find.text('Cover'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove photo').first);
    await tester.pumpAndSettle();
    expect(_key('add-item-photo-1'), findsNothing);
    expect(find.text('1 of 8 · drag to reorder'), findsOneWidget);
  });

  testWidgets('a pasted link must be https and load as an image', (
    tester,
  ) async {
    final results = await _open(
      tester,
      imageForUrl: (url) => url.contains('bad')
          ? MemoryImage(Uint8List.fromList(const [1, 2, 3]))
          : MemoryImage(_png),
    );
    await _choosePart(tester, 'Accessories', 'Helmet');
    await tester.tap(_key('add-item-url-open'));
    await tester.pumpAndSettle();

    await tester.enterText(_key('add-item-image-url'), 'http://x.com/a.png');
    await tester.tap(_key('add-item-url-add'));
    await tester.pumpAndSettle();
    expect(find.text('The link must start with https://'), findsOneWidget);

    Future<void> addLink(String url) async {
      await tester.enterText(_key('add-item-image-url'), url);
      await tester.tap(_key('add-item-url-add'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
    }

    await addLink('https://x.com/bad.png');
    expect(find.text(notAnImageMessage), findsOneWidget);
    expect(_key('add-item-photo-0'), findsNothing);

    await addLink('https://x.com/good.png');
    expect(_key('add-item-photo-0'), findsOneWidget);
    expect(find.text('Cover'), findsOneWidget);

    await tester.tap(_key('condition-Used'));
    await tester.enterText(_key('add-item-price'), '900');
    await tester.enterText(_key('add-item-quantity'), '1');
    await _tapInForm(tester, _key('fit-universal'));
    await _post(tester);
    expect(results.single!.photos.single.url, 'https://x.com/good.png');
    expect(results.single!.condition, 'Used');
  });

  test('suggestions come from every catalog, mapped to the 8 categories', () {
    final suggestions = buildPartSuggestions(const []);
    final categories = suggestions.map((s) => s.category).toSet();
    expect(categories, containsAll(['Accessories', 'Maintenance', 'Designs']));
    expect(categories.every(itemCategories.contains), isTrue);
  });

  test('item names map to the right follow-up questions', () {
    expect(detailKindFor('Front tire'), DetailKind.tire);
    expect(detailKindFor('Tubeless tyre 110/70-13'), DetailKind.tire);
    expect(detailKindFor('Tire pressure gauge'), isNull);
    expect(detailKindFor('12-V battery'), DetailKind.battery);
    expect(detailKindFor('Battery charger'), isNull);
    expect(detailKindFor('Spark plug'), DetailKind.sparkPlug);
    expect(detailKindFor('Spark-plug cap'), isNull);
    expect(detailKindFor('Engine oil'), DetailKind.engineOil);
    expect(detailKindFor('Oil filter'), isNull);
    expect(detailKindFor('Drive chain'), DetailKind.chain);
    expect(detailKindFor('Chain lube'), isNull);
    expect(detailKindFor('Rear sprocket'), DetailKind.sprocket);
    expect(detailKindFor('Brake lever'), isNull);
  });

  List<String> optionValues(
    DetailKind kind,
    String id,
    Map<String, String> answers,
  ) => detailQuestionsFor(
    kind,
    _rows,
    answers,
  ).firstWhere((q) => q.id == id).options.map((o) => o.value).toList();

  test('tire sizes follow the chosen position and come from the table', () {
    final front = optionValues(DetailKind.tire, 'size', {'position': 'Front'});
    final rear = optionValues(DetailKind.tire, 'size', {'position': 'Rear'});
    expect(front, containsAll(['110/70-13', '80/90-14', '70/100-21']));
    expect(front, isNot(contains('130/70-13')));
    expect(rear, containsAll(['130/70-13', '90/90-14', '150/60-17']));
    expect(rear, isNot(contains('70/100-21')));
  });

  test('battery asks volts, then lists capacities and model codes', () {
    final before = detailQuestionsFor(DetailKind.battery, _rows, {});
    expect(before.first.label, 'What volts?');
    expect(optionValues(DetailKind.battery, 'capacity', {'volts': '12V'}), [
      '3Ah',
      '3.5Ah',
      '5Ah',
      '6Ah',
    ]);
    // No 6V batteries are listed, so nothing is suggested (never guessed).
    expect(
      optionValues(DetailKind.battery, 'capacity', {'volts': '6V'}),
      isEmpty,
    );
  });
}
