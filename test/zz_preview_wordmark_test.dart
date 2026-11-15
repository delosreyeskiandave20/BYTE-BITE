// Temporary: renders the wordmark to PNG for a visual check.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_application_1/widgets/motoscan_wordmark.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview', (tester) async {
    await tester.runAsync(() async {
      for (final f in ['roboto-black', 'roboto-blackitalic']) {
        final bytes = File(
          '/src/flutter/bin/cache/artifacts/material_fonts/$f.ttf',
        ).readAsBytesSync();
        await ui.loadFontFromList(bytes, fontFamily: 'Roboto');
      }
    });
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        home: RepaintBoundary(
          key: key,
          child: Material(child: DefaultTextStyle(style: const TextStyle(fontFamily: "Roboto"), child: Container(
            color: const Color(0xFFF7F5F0),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 9, 18, 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A2A20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const MotoScanWordmark(size: 24, onDark: true),
                ),
                const SizedBox(height: 20),
                const MotoScanWordmark(size: 23),
              ],
            ),
          ))),
        ),
      ),
    );
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        r'C:\Users\User\AppData\Local\Temp\claude\325b313d5dc5e589\b0ac45cb-cfd9-4d56-a29f-c31695d6a0d8\scratchpad\wordmark.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
