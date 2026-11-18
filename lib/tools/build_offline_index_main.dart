// Developer tool, not part of the app: builds the offline scanning index on a
// phone, because the model runtime runs there and not on every PC.
//
//   flutter build apk --release -t lib/tools/build_offline_index_main.dart
//   adb install -r build/app/outputs/flutter-apk/app-release.apk
//   (open the app on the phone and wait for "Done")
//   adb pull /sdcard/Android/data/com.example.flutter_application_1/files/offline_index/part_index.bin assets/ml/
//   adb pull /sdcard/Android/data/com.example.flutter_application_1/files/offline_index/part_index.json assets/ml/
//
// Then rebuild and reinstall the normal app.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/offline_part_matcher.dart';
import '../data/offline_part_matcher_io.dart';

/// App-specific external storage: readable over adb without root, and
/// writable by the app without permissions.
const _outDir =
    '/storage/emulated/0/Android/data/com.example.flutter_application_1/files/offline_index';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final status = ValueNotifier<String>('Starting…');
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ValueListenableBuilder<String>(
              valueListenable: status,
              builder: (context, text, _) =>
                  Text(text, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    ),
  );
  _build(status);
}

Future<void> _build(ValueNotifier<String> status) async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final photos =
        manifest
            .listAssets()
            .where(
              (path) =>
                  offlineIndexFolders.any(path.startsWith) &&
                  RegExp(
                    r'\.(jpe?g|png|webp)$',
                    caseSensitive: false,
                  ).hasMatch(path),
            )
            .toList()
          ..sort();
    final bySlug = partSuggestionsBySlug();
    final embedder = await PartPhotoEmbedder.load(rootBundle);

    final labels = <({String name, String category})>[];
    final labelIds = <String, int>{};
    final rowLabels = <int>[];
    final rows = <Int8List>[];
    var skipped = 0;
    for (final (n, path) in photos.indexed) {
      final label = labelForPartPhoto(path, bySlug);
      if (label == null) {
        skipped++;
        continue;
      }
      try {
        final data = await rootBundle.load(path);
        final vector = await embedder.embed(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        rows.add(OfflinePartIndex.quantize(vector));
        rowLabels.add(
          labelIds.putIfAbsent('${label.category}|${label.name}', () {
            labels.add(label);
            return labels.length - 1;
          }),
        );
      } catch (error) {
        skipped++;
        debugPrint('SKIP $path: $error');
      }
      if (n % 25 == 0) {
        status.value = 'Indexing part photos…\n${n + 1} / ${photos.length}';
      }
    }

    final dir = await Directory(_outDir).create(recursive: true);
    await File('${dir.path}/part_index.bin').writeAsBytes(
      OfflinePartIndex.encodeVectors(embedder.dims, rows),
    );
    await File('${dir.path}/part_index.json').writeAsString(
      jsonEncode({
        'model': offlineModelAsset,
        'labels': [
          for (final label in labels)
            {'name': label.name, 'category': label.category},
        ],
        'rows': rowLabels,
      }),
    );
    // Written last, so its presence means both files are complete.
    await File('${dir.path}/done.txt').writeAsString(
      '${rows.length} photos, ${labels.length} parts, $skipped skipped\n',
    );
    status.value =
        'Done\n${rows.length} photos · ${labels.length} parts · '
        '$skipped skipped';
  } catch (error) {
    status.value = 'Failed: $error';
    debugPrint('INDEX failed: $error');
  }
}
