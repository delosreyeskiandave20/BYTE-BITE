import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/data/owner_auth.dart';

/// In-memory [OwnerAuth] used only by tests. Production always uses
/// [FirebaseOwnerAuth], which keeps credentials inside Firebase.
class FakeOwnerAuth implements OwnerAuth {
  FakeOwnerAuth({this.emailVerified = true});

  final Map<String, _FakeAccount> _accounts = {};
  final StreamController<OwnerAccount?> _stateController =
      StreamController<OwnerAccount?>.broadcast();

  OwnerAccount? _current;
  bool emailVerified;
  int _nextUid = 0;

  @override
  OwnerAccount? get currentAccount => _current;

  @override
  Stream<OwnerAccount?> authStateChanges() => _stateController.stream;

  @override
  Future<OwnerAccount> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalize(email);
    if (_accounts.containsKey(normalizedEmail)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    final account = OwnerAccount(
      uid: 'fake-uid-${_nextUid++}',
      email: normalizedEmail,
      displayName: name.trim(),
      emailVerified: emailVerified,
    );
    _accounts[normalizedEmail] = _FakeAccount(
      account: account,
      password: password,
    );
    _current = account;
    _stateController.add(account);
    return account;
  }

  @override
  Future<OwnerAccount> signIn({
    required String email,
    required String password,
  }) async {
    final stored = _accounts[_normalize(email)];
    if (stored == null || stored.password != password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    _current = stored.account;
    _stateController.add(_current);
    return stored.account;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<OwnerAccount> reloadAccount() async {
    final account = _current;
    if (account == null) {
      throw StateError('Sign in with your shop owner account first.');
    }
    _stateController.add(account);
    return account;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _stateController.add(null);
  }

  /// Simulates the owner following the verification link.
  void markEmailVerified() {
    final account = _current;
    if (account == null) return;
    final verified = account.copyWith(emailVerified: true);
    _current = verified;
    _accounts[verified.email] = _FakeAccount(
      account: verified,
      password: _accounts[verified.email]!.password,
    );
    _stateController.add(verified);
  }

  Future<void> dispose() => _stateController.close();

  static String _normalize(String email) => email.trim().toLowerCase();
}

class _FakeAccount {
  const _FakeAccount({required this.account, required this.password});

  final OwnerAccount account;
  final String password;
}
