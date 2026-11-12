import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Application salt mixed into owner email hashes.
///
/// This is intentionally not a server-side secret: it keeps shop documents from
/// exposing owner email addresses in plain text, but a determined attacker could
/// still test candidate addresses against a hash. The salt is static so the same
/// owner resolves from any device without a server-side lookup table.
const _ownerEmailSalt = 'motoscan-owner-v1';

/// Salted SHA-256 of a normalized owner email address.
///
/// Shop documents store only this value, so public marketplace reads never
/// reveal the owner's email. Owners are still found by email because the store
/// hashes the signed-in email with the same function.
String ownerEmailHash(String email) {
  final normalized = email.trim().toLowerCase();
  return sha256.convert(utf8.encode('$_ownerEmailSalt:$normalized')).toString();
}
