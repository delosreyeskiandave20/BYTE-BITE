import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/data/part_identifier.dart';
import 'package:flutter_application_1/screens/camera_capture_page.dart';
import 'package:flutter_application_1/screens/identify_page.dart';

final _photoBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAPSURBVBhXY1CvqfjPgAwAH2MCG8SNA3oAAAAASUVORK5CYII=',
  ),
);

void main() {
  testWidgets(
    'identify page offers manual library search while AI is offline',
    (WidgetTester tester) async {
      var openedLibrary = false;
      await tester.pumpWidget(
        MaterialApp(
          home: IdentifyPage(onSearchParts: () => openedLibrary = true),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Photo preview works here. AI part recognition still needs a service connection.',
        ),
        findsNothing,
      );
      expect(find.text('Start with a clear photo'), findsOneWidget);

      expect(find.text('How preview works'), findsNothing);
      expect(find.text('Frame the part'), findsNothing);

      final searchButton = find.byKey(const ValueKey('identify-search-parts'));
      await tester.ensureVisible(searchButton);
      await tester.pumpAndSettle();
      await tester.tap(searchButton);
      expect(openedLibrary, isTrue);
    },
  );

  testWidgets('photo preview keeps the manual search fallback available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IdentifyPage(
          pickImage: (source) async => XFile.fromData(
            _photoBytes,
            name: 'brake-part.png',
            mimeType: 'image/png',
          ),
          onSearchParts: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final takePhoto = find.byKey(const ValueKey('identify-take-photo'));
    await tester.ensureVisible(takePhoto);
    await tester.pumpAndSettle();
    await tester.tap(takePhoto);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('identify-photo-preview')),
      findsOneWidget,
    );
    expect(find.text('Photo ready to review'), findsNothing);

    final searchButton = find.byKey(const ValueKey('identify-search-parts'));
    await tester.ensureVisible(searchButton);
    await tester.pumpAndSettle();
    expect(searchButton, findsOneWidget);
    expect(
      find.text(
        'Photo preview ready. AI part recognition is not connected yet.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('AI identifies the photographed part and opens search', (
    WidgetTester tester,
  ) async {
    String? searched;
    String? sentMime;
    await tester.pumpWidget(
      MaterialApp(
        home: IdentifyPage(
          pickImage: (source) async => XFile.fromData(
            _photoBytes,
            name: 'caliper.png',
            mimeType: 'image/png',
          ),
          identifyPart: (bytes, mimeType) async {
            sentMime = mimeType;
            return const PartIdentification(
              isMotorcyclePart: true,
              partName: 'Brake caliper',
              categoryId: 'brakes',
              confidence: 'high',
              description: 'Squeezes the brake pads against the disc.',
              searchTerm: 'Brake',
            );
          },
          onSearchQuery: (term) => searched = term,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final takePhoto = find.byKey(const ValueKey('identify-take-photo'));
    await tester.ensureVisible(takePhoto);
    await tester.pumpAndSettle();
    await tester.tap(takePhoto);
    await tester.pumpAndSettle();

    expect(sentMime, 'image/png');
    expect(find.text('Brake caliper'), findsOneWidget);
    expect(find.text('Brakes · high confidence'), findsOneWidget);

    final findInShops = find.byKey(const ValueKey('identify-ai-find'));
    await tester.ensureVisible(findInShops);
    await tester.pumpAndSettle();
    await tester.tap(findInShops);
    expect(searched, 'Brake caliper');
  });

  testWidgets('AI errors offer a retry', (WidgetTester tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: IdentifyPage(
          pickImage: (source) async =>
              XFile.fromData(_photoBytes, name: 'part.png'),
          identifyPart: (bytes, mimeType) async {
            calls++;
            throw const PartIdentificationException('AI is busy.');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final upload = find.byKey(const ValueKey('identify-upload-photo'));
    await tester.ensureVisible(upload);
    await tester.pumpAndSettle();
    await tester.tap(upload);
    await tester.pumpAndSettle();

    expect(find.text('AI is busy.'), findsOneWidget);
    final retry = find.byKey(const ValueKey('identify-ai-retry'));
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('camera error state points to the upload fallback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CameraCapturePage(cameraLister: () async => const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Camera unavailable'), findsOneWidget);
    expect(
      find.text(
        'You can also close the camera and upload a photo from the Scan tab.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('camera-retry-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('camera-fallback-button')),
      findsOneWidget,
    );
  });
}
