import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/phone_frame.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the MediaQuery the app sees inside the frame.
class _Probe extends StatelessWidget {
  const _Probe(this.onMedia);

  final ValueChanged<MediaQueryData> onMedia;

  @override
  Widget build(BuildContext context) {
    onMedia(MediaQuery.of(context));
    return const Scaffold(body: SafeArea(child: Text('Hello')));
  }
}

Future<MediaQueryData?> _pump(
  WidgetTester tester,
  Size window, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  MediaQueryData? seen;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          PhoneFrame(enabled: true, child: child ?? const SizedBox.shrink()),
      home: _Probe((media) => seen = media),
    ),
  );
  await tester.pumpAndSettle();
  return seen;
}

void main() {
  for (final window in const [
    Size(1920, 1080),
    Size(1366, 768),
    Size(1024, 600),
    Size(800, 1300),
  ]) {
    testWidgets('a ${window.width.toInt()}x${window.height.toInt()} window '
        'shows a real-phone-shaped frame that fits', (tester) async {
      final media = await _pump(tester, window);
      final frame = find.byKey(const ValueKey('desktop-phone-frame'));
      final size = tester.getSize(frame);

      // Same shape as a 390 x 844 phone plus bezel, at every window size.
      final expectedRatio =
          PhoneFrame.frameSize.width / PhoneFrame.frameSize.height;
      expect(size.width / size.height, closeTo(expectedRatio, 0.001));
      // Fits inside the window with at least 24 px around it.
      expect(size.height, lessThanOrEqualTo(window.height - 48 + 0.01));
      expect(size.width, lessThanOrEqualTo(window.width - 48 + 0.01));
      final topLeft = tester.getTopLeft(frame);
      expect(topLeft.dy, greaterThanOrEqualTo(24 - 0.01));

      // The app lays out exactly as on a 390 x 844 phone.
      expect(media!.size, PhoneFrame.screenSize);
      expect(media.padding, PhoneFrame.screenPadding);
      expect(media.devicePixelRatio, 3);
    });
  }

  testWidgets('narrow windows (real phones) are shown full screen', (
    tester,
  ) async {
    final media = await _pump(tester, const Size(430, 900));
    expect(find.byKey(const ValueKey('desktop-phone-frame')), findsNothing);
    expect(media!.size, const Size(430, 900));
  });

  testWidgets('browser text scaling does not distort the preview', (
    tester,
  ) async {
    final media = await _pump(tester, const Size(1366, 768), textScale: 1.6);
    expect(media!.textScaler, TextScaler.noScaling);
  });

  testWidgets('the app content sits below the dynamic island', (tester) async {
    await _pump(tester, const Size(1366, 768));
    final island = find.byKey(const ValueKey('desktop-camera-cutout'));
    expect(
      tester.getTopLeft(find.text('Hello')).dy,
      greaterThan(tester.getBottomLeft(island).dy),
    );
  });

  testWidgets('without web or an override the app is not framed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: PhoneFrame(child: Text('App'))),
    );
    expect(find.byKey(const ValueKey('desktop-phone-frame')), findsNothing);
  });
}
