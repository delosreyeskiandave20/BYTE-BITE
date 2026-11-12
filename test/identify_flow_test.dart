import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

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
        findsOneWidget,
      );
      expect(find.text('Preview only'), findsOneWidget);
      expect(find.text('Start with a clear photo'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('How preview works'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Frame the part'), findsOneWidget);
      expect(find.text('Capture or upload'), findsOneWidget);
      expect(find.text('Review the preview'), findsOneWidget);

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
    expect(find.text('Photo ready to review'), findsOneWidget);

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
