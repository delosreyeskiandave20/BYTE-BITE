import 'dart:typed_data';

import 'offline_part_matcher.dart';

/// Web: the on-device model needs dart:ffi, so offline matching is off.
OfflinePartMatcher createOfflinePartMatcher() => _UnsupportedMatcher();

class _UnsupportedMatcher implements OfflinePartMatcher {
  @override
  bool get isSupported => false;

  @override
  Future<List<OfflineMatch>> match(
    Uint8List imageBytes, {
    int limit = 3,
  }) async => const [];
}
