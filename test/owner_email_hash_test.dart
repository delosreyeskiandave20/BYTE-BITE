import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/owner_email_hash.dart';

void main() {
  test('owner email hash is deterministic and normalized', () {
    final first = ownerEmailHash('Demo@MotoScan.Test ');
    final second = ownerEmailHash('demo@motoscan.test');
    expect(first, second);
    expect(first, hasLength(64));
    expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('different emails produce different hashes', () {
    expect(
      ownerEmailHash('a@example.com'),
      isNot(equals(ownerEmailHash('b@example.com'))),
    );
  });
}
