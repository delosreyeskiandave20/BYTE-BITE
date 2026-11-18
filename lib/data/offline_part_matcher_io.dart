import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'offline_part_matcher.dart';

/// Android/iOS: runs the bundled MobileNetV3 image embedder with TensorFlow
/// Lite and compares the photo with the bundled part photos.
OfflinePartMatcher createOfflinePartMatcher() => TfliteOfflinePartMatcher();

class TfliteOfflinePartMatcher implements OfflinePartMatcher {
  TfliteOfflinePartMatcher({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<PartPhotoEmbedder>? _embedder;
  Future<OfflinePartIndex>? _index;

  /// Phones only: the TensorFlow Lite runtime ships with the Android and
  /// iOS builds, not with desktop test runs.
  @override
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  Future<PartPhotoEmbedder> get embedder =>
      _embedder ??= PartPhotoEmbedder.load(_bundle);

  Future<OfflinePartIndex> _loadIndex() async {
    final vectors = await _bundle.load(offlineIndexVectorsAsset);
    final labels = jsonDecode(
      await _bundle.loadString(offlineIndexLabelsAsset),
    );
    return OfflinePartIndex.decode(
      vectors.buffer.asUint8List(vectors.offsetInBytes, vectors.lengthInBytes),
      labels as Map,
    );
  }

  @override
  Future<List<OfflineMatch>> match(
    Uint8List imageBytes, {
    int limit = 3,
  }) async {
    final index = await (_index ??= _loadIndex());
    final vector = await (await embedder).embed(imageBytes);
    return index.nearest(vector, limit: limit);
  }
}

/// Turns a photo into the model's feature vector.
class PartPhotoEmbedder {
  PartPhotoEmbedder._(this._interpreter, this._size, this._dims);

  final Interpreter _interpreter;

  /// Input width and height (224).
  final int _size;

  /// Feature vector length.
  final int _dims;

  int get dims => _dims;

  static Future<PartPhotoEmbedder> load(AssetBundle bundle) async {
    final model = await bundle.load(offlineModelAsset);
    final interpreter = Interpreter.fromBuffer(
      model.buffer.asUint8List(model.offsetInBytes, model.lengthInBytes),
    );
    final input = interpreter.getInputTensor(0).shape; // [1, 224, 224, 3]
    final output = interpreter.getOutputTensor(0).shape; // [1, dims]
    return PartPhotoEmbedder._(interpreter, input[1], output.last);
  }

  Future<List<double>> embed(Uint8List imageBytes) async {
    final pixels = await _centerSquare(imageBytes, _size);
    final input = List.generate(
      1,
      (_) => List.generate(
        _size,
        (y) => List.generate(_size, (x) {
          final i = (y * _size + x) * 4;
          // The model expects RGB values from 0 to 1.
          return [
            pixels[i] / 255.0,
            pixels[i + 1] / 255.0,
            pixels[i + 2] / 255.0,
          ];
        }),
      ),
    );
    final output = [List<double>.filled(_dims, 0)];
    _interpreter.run(input, output);
    return output.first;
  }

  /// Decodes [bytes], scales the short side to [size] and crops the middle,
  /// returning RGBA bytes.
  static Future<Uint8List> _centerSquare(Uint8List bytes, int size) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final wide = descriptor.width >= descriptor.height;
    final codec = await descriptor.instantiateCodec(
      targetWidth: wide
          ? (descriptor.width * size / descriptor.height).round()
          : size,
      targetHeight: wide
          ? size
          : (descriptor.height * size / descriptor.width).round(),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    final height = image.height;
    image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    if (data == null) throw StateError('Could not read the photo.');
    final rgba = data.buffer.asUint8List();
    final left = ((width - size) / 2).floor().clamp(0, width - 1);
    final top = ((height - size) / 2).floor().clamp(0, height - 1);
    final out = Uint8List(size * size * 4);
    for (var y = 0; y < size; y++) {
      final sy = (top + y).clamp(0, height - 1);
      for (var x = 0; x < size; x++) {
        final sx = (left + x).clamp(0, width - 1);
        final from = (sy * width + sx) * 4;
        final to = (y * size + x) * 4;
        out[to] = rgba[from];
        out[to + 1] = rgba[from + 1];
        out[to + 2] = rgba[from + 2];
        out[to + 3] = 255;
      }
    }
    return out;
  }
}
