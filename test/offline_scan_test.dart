import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/offline_part_matcher.dart';
import 'package:flutter_application_1/data/part_identifier.dart';
import 'package:flutter_application_1/screens/identify_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

final _photoBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAPSURBVBhXY1CvqfjPgAwAH2MCG8SNA3oAAAAASUVORK5CYII=',
  ),
);

class _FakeOfflineMatcher implements OfflinePartMatcher {
  _FakeOfflineMatcher(this.matches);

  final List<OfflineMatch> matches;
  var calls = 0;

  @override
  bool get isSupported => true;

  @override
  Future<List<OfflineMatch>> match(
    Uint8List imageBytes, {
    int limit = 3,
  }) async {
    calls++;
    return matches;
  }
}

Future<void> _takePhoto(WidgetTester tester) async {
  final takePhoto = find.byKey(const ValueKey('identify-take-photo'));
  await tester.ensureVisible(takePhoto);
  await tester.pumpAndSettle();
  await tester.tap(takePhoto);
  await tester.pumpAndSettle();
}

void main() {
  group('OfflinePartIndex', () {
    test('saves and reads back the index', () {
      final rows = [
        OfflinePartIndex.quantize([1, 0, 0]),
        OfflinePartIndex.quantize([0, 2, 0]),
      ];
      final bytes = OfflinePartIndex.encodeVectors(3, rows);
      final index = OfflinePartIndex.decode(bytes, {
        'labels': [
          {'name': 'Battery', 'category': 'Electrical'},
          {'name': 'Air Filter', 'category': 'Engine'},
        ],
        'rows': [0, 1],
      });
      expect(index.rows, 2);
      expect(index.dims, 3);
      expect(index.vectors, [127, 0, 0, 0, 127, 0]);
    });

    test('ranks the part with the most similar photos first', () {
      final vectors = <List<double>>[
        [1, 0, 0, 0], // Battery
        [0.95, 0.1, 0, 0], // Battery
        [0.9, 0.2, 0, 0], // Battery
        [0, 1, 0, 0], // Air Filter
        [0, 0, 1, 0], // Spark Plug
      ];
      final index = OfflinePartIndex.decode(
        OfflinePartIndex.encodeVectors(4, [
          for (final v in vectors) OfflinePartIndex.quantize(v),
        ]),
        {
          'labels': [
            {'name': 'Battery', 'category': 'Electrical'},
            {'name': 'Air Filter', 'category': 'Engine'},
            {'name': 'Spark Plug', 'category': 'Engine'},
          ],
          'rows': [0, 0, 0, 1, 2],
        },
      );
      final matches = index.nearest([0.9, 0.3, 0, 0], neighbors: 4);
      expect(matches.first.name, 'Battery');
      expect(matches.first.similarity, greaterThan(0.9));
      expect(matches.map((m) => m.name), contains('Air Filter'));
      expect(matches.length, lessThanOrEqualTo(3));
    });
  });

  test('photo paths map to catalog part names', () {
    final bySlug = partSuggestionsBySlug();
    final battery = labelForPartPhoto(
      'assets/vehicle_parts/click125_standard/air_filter.jpg',
      bySlug,
    );
    expect(battery, isNotNull);
    expect(battery!.name.toLowerCase(), 'air filter');
    expect(
      labelForPartPhoto('assets/design/3d_stickers.jpg', bySlug),
      isNull,
      reason: 'design styles are not scanned',
    );
    final accessory = labelForPartPhoto(
      'assets/accessories/body_armor_and_protective_gear-back_protector.jpg',
      bySlug,
    );
    expect(accessory!.name.toLowerCase(), 'back protector');
  });

  testWidgets('without internet the scan falls back to an offline match', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? searched;
    final offline = _FakeOfflineMatcher(const [
      OfflineMatch(name: 'Battery', category: 'Electrical', similarity: 0.82),
      OfflineMatch(name: 'Stator', category: 'Electrical', similarity: 0.6),
      OfflineMatch(
        name: 'Starter Relay',
        category: 'Electrical',
        similarity: 0.5,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: IdentifyPage(
          pickImage: (source) async => XFile.fromData(
            _photoBytes,
            name: 'battery.png',
            mimeType: 'image/png',
          ),
          identifyPart: (bytes, mimeType) async =>
              throw const PartIdentificationException(
                'Could not reach the AI service. Check your connection and try again.',
              ),
          offlineMatcher: offline,
          onSearchQuery: (term) => searched = term,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _takePhoto(tester);

    expect(offline.calls, 1);
    expect(find.text('Offline match'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('Electrical · medium confidence'), findsOneWidget);
    expect(
      find.text(
        'Could not reach the AI service. Check your connection and try again.',
      ),
      findsNothing,
    );

    // Other guesses can be searched directly.
    final stator = find.byKey(const ValueKey('identify-alternative-Stator'));
    await tester.ensureVisible(stator);
    await tester.tap(stator);
    expect(searched, 'Stator');

    final findInShops = find.byKey(const ValueKey('identify-ai-find'));
    await tester.ensureVisible(findInShops);
    await tester.tap(findInShops);
    expect(searched, 'Battery');
  });

  testWidgets('online results are used first and labelled AI match', (
    tester,
  ) async {
    final offline = _FakeOfflineMatcher(const [
      OfflineMatch(name: 'Battery', category: 'Electrical', similarity: 0.9),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: IdentifyPage(
          pickImage: (source) async => XFile.fromData(
            _photoBytes,
            name: 'caliper.png',
            mimeType: 'image/png',
          ),
          identifyPart: (bytes, mimeType) async => const PartIdentification(
            isMotorcyclePart: true,
            partName: 'Brake caliper',
            categoryId: 'brakes',
            confidence: 'high',
            description: '',
            searchTerm: 'Brake',
          ),
          offlineMatcher: offline,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _takePhoto(tester);

    expect(offline.calls, 0);
    expect(find.text('AI match'), findsOneWidget);
    expect(find.text('Brake caliper'), findsOneWidget);
  });

  testWidgets('if offline matching finds nothing the error is shown', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IdentifyPage(
          pickImage: (source) async =>
              XFile.fromData(_photoBytes, name: 'x.png', mimeType: 'image/png'),
          identifyPart: (bytes, mimeType) async =>
              throw const PartIdentificationException(
                'Could not reach the AI service. Check your connection and try again.',
              ),
          offlineMatcher: _FakeOfflineMatcher(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _takePhoto(tester);

    expect(find.text('Offline match'), findsNothing);
    expect(
      find.text(
        'Could not reach the AI service. Check your connection and try again.',
      ),
      findsOneWidget,
    );
  });
}
