import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'catalog_images.dart';
import 'part_suggestions.dart';
import 'offline_part_matcher_stub.dart'
    if (dart.library.ffi) 'offline_part_matcher_io.dart'
    as impl;

/// Bundled image model: turns a 224 x 224 photo into a feature vector.
const offlineModelAsset = 'assets/ml/mobilenet_v3_small.tflite';

/// Feature vectors of the bundled part photos (see [OfflinePartIndex]).
const offlineIndexVectorsAsset = 'assets/ml/part_index.bin';

/// Part name and category of each vector in [offlineIndexVectorsAsset].
const offlineIndexLabelsAsset = 'assets/ml/part_index.json';

/// Folders whose photos are used for offline matching. Designs are left out:
/// they are styles, not parts a rider would photograph.
const offlineIndexFolders = [
  vehiclePartsImageFolder,
  accessoryImageFolder,
  maintenanceImageFolder,
  'assets/parts/',
];

/// One guess from offline matching.
@immutable
class OfflineMatch {
  const OfflineMatch({
    required this.name,
    required this.category,
    required this.similarity,
  });

  /// Catalog part name, e.g. "Air Filter".
  final String name;

  /// One of the Add Item categories, e.g. "Engine" or "Accessories".
  final String category;

  /// Cosine similarity of the closest bundled photo, 0 to 1.
  final double similarity;
}

/// Recognizes a part without internet by comparing the photo with the part
/// photos bundled in the app. Android and iOS only; [isSupported] is false on
/// the web.
abstract class OfflinePartMatcher {
  static OfflinePartMatcher? _shared;

  /// The app-wide matcher; the model and index load on first use.
  static OfflinePartMatcher get shared =>
      _shared ??= impl.createOfflinePartMatcher();

  /// Whether this platform can match offline at all.
  bool get isSupported;

  /// The closest catalog parts, best first (at most [limit]).
  Future<List<OfflineMatch>> match(Uint8List imageBytes, {int limit = 3});
}

/// The part name and category a bundled photo shows, from its path.
/// Used when building the index.
({String name, String category})? labelForPartPhoto(
  String assetPath,
  Map<String, PartSuggestion> bySlug,
) {
  final folder = offlineIndexFolders
      .where((folder) => assetPath.startsWith(folder))
      .firstOrNull;
  if (folder == null) return null;
  final file = assetPath.split('/').last;
  final dot = file.lastIndexOf('.');
  if (dot <= 0) return null;
  final slug = file.substring(0, dot);
  // Accessory and maintenance photos are "<group>-<choice>".
  final key = slug.contains('-') ? slug.split('-').last : slug;
  final known = bySlug[key];
  if (known != null) return (name: known.name, category: known.category);
  final fallbackCategory = switch (folder) {
    accessoryImageFolder => 'Accessories',
    maintenanceImageFolder => 'Maintenance',
    _ => 'Engine',
  };
  final words = key.split('_').where((w) => w.isNotEmpty).join(' ');
  if (words.isEmpty) return null;
  return (
    name: '${words[0].toUpperCase()}${words.substring(1)}',
    category: fallbackCategory,
  );
}

/// Catalog names keyed by [imageSlug], for [labelForPartPhoto].
Map<String, PartSuggestion> partSuggestionsBySlug() => {
  for (final part in buildPartSuggestions().reversed)
    imageSlug(part.name): part,
};

/// Maps an Add Item category (and the part name) to a parts-library
/// category id from `categoryNames`.
String categoryIdForOfflineMatch(OfflineMatch match) {
  if (match.name.toLowerCase().contains('brake')) return 'brakes';
  return switch (match.category) {
    'Engine' => 'engine',
    'Electrical' => 'electrical',
    'Suspension' => 'suspension',
    'Wheels and Tires' => 'wheels',
    'Body Parts' => 'body',
    'Accessories' || 'Maintenance' => 'maintenance',
    'Designs' => 'design',
    _ => 'other',
  };
}

/// Feature vectors of the bundled photos, stored as signed bytes after
/// normalizing each vector to length 1 (value * 127).
///
/// File layout of [offlineIndexVectorsAsset]: the ASCII magic `MSIX`, then
/// the row count and the vector length as little-endian 32-bit integers,
/// then `rows * dims` signed bytes.
class OfflinePartIndex {
  OfflinePartIndex({
    required this.labels,
    required this.rowLabels,
    required this.dims,
    required this.vectors,
  });

  /// Distinct (name, category) pairs.
  final List<({String name, String category})> labels;

  /// Index into [labels] for each row.
  final List<int> rowLabels;
  final int dims;
  final Int8List vectors;

  int get rows => rowLabels.length;

  static Uint8List encodeVectors(int dims, List<Int8List> rows) {
    final header = ByteData(12)
      ..setUint8(0, 0x4D) // M
      ..setUint8(1, 0x53) // S
      ..setUint8(2, 0x49) // I
      ..setUint8(3, 0x58) // X
      ..setInt32(4, rows.length, Endian.little)
      ..setInt32(8, dims, Endian.little);
    final out = BytesBuilder(copy: false)..add(header.buffer.asUint8List());
    for (final row in rows) {
      out.add(row.buffer.asUint8List(row.offsetInBytes, row.length));
    }
    return out.takeBytes();
  }

  static OfflinePartIndex decode(Uint8List vectorBytes, Map labelsJson) {
    final data = ByteData.sublistView(vectorBytes);
    final magic = String.fromCharCodes(vectorBytes.sublist(0, 4));
    if (magic != 'MSIX') throw const FormatException('Not a part index.');
    final rows = data.getInt32(4, Endian.little);
    final dims = data.getInt32(8, Endian.little);
    final labels = [
      for (final label in labelsJson['labels'] as List)
        (
          name: (label as Map)['name'] as String,
          category: label['category'] as String,
        ),
    ];
    final rowLabels = [for (final i in labelsJson['rows'] as List) i as int];
    if (rowLabels.length != rows) {
      throw const FormatException('Part index rows do not match labels.');
    }
    return OfflinePartIndex(
      labels: labels,
      rowLabels: rowLabels,
      dims: dims,
      vectors: Int8List.sublistView(vectorBytes, 12, 12 + rows * dims),
    );
  }

  /// Signed-byte form of a feature vector, normalized to length 1.
  static Int8List quantize(List<double> vector) {
    var norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    final scale = norm == 0 ? 0.0 : 127 / math.sqrt(norm);
    return Int8List.fromList([
      for (final v in vector) (v * scale).round().clamp(-127, 127),
    ]);
  }

  /// Best catalog parts for [query] (a raw feature vector).
  ///
  /// Each part is scored by its photos among the closest [neighbors], so a
  /// part with many similar photos beats one lucky look-alike.
  List<OfflineMatch> nearest(
    List<double> query, {
    int limit = 3,
    int neighbors = 15,
  }) {
    final q = quantize(query);
    final scores = Float64List(rows);
    for (var row = 0; row < rows; row++) {
      var dot = 0;
      final base = row * dims;
      for (var i = 0; i < dims; i++) {
        dot += q[i] * vectors[base + i];
      }
      scores[row] = dot / (127 * 127);
    }
    final order = List<int>.generate(rows, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));
    final votes = <int, double>{};
    final best = <int, double>{};
    for (final row in order.take(neighbors)) {
      final label = rowLabels[row];
      votes[label] = (votes[label] ?? 0) + scores[row];
      best[label] = (best[label] ?? 0) > scores[row]
          ? best[label]!
          : scores[row];
    }
    final ranked = votes.keys.toList()
      ..sort((a, b) => votes[b]!.compareTo(votes[a]!));
    return [
      for (final label in ranked.take(limit))
        OfflineMatch(
          name: labels[label].name,
          category: labels[label].category,
          similarity: best[label]!.clamp(0.0, 1.0),
        ),
    ];
  }
}
