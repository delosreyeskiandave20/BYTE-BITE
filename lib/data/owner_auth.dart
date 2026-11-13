import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Immutable snapshot of the signed-in shop owner.
///
/// Passwords and PINs are never kept by the app: Firebase Authentication owns
/// every credential, and this object only mirrors the public account fields the
/// UI needs.
class OwnerAccount {
  const OwnerAccount({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.emailVerified,
  });

  factory OwnerAccount.fromUser(User user) {
    return OwnerAccount(
      uid: user.uid,
      email: (user.email ?? '').trim().toLowerCase(),
      displayName: user.displayName?.trim() ?? '',
      emailVerified: user.emailVerified,
    );
  }

  final String uid;
  final String email;
  final String displayName;
  final bool emailVerified;

  OwnerAccount copyWith({String? displayName, bool? emailVerified}) {
    return OwnerAccount(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}

/// Thrown when owner authentication is requested while Firebase is not
/// configured. Shop owner accounts are intentionally Firebase-only.
class OwnerAuthUnavailableException implements Exception {
  const OwnerAuthUnavailableException();

  static const message =
      'Shop owner sign-in needs Firebase Authentication. Run '
      '`flutterfire configure`, then enable Email/Password sign-in in the '
      'Firebase console.';

  @override
  String toString() => message;
}

/// Authentication operations available to shop owners.
///
/// The interface keeps [ShopStore] independent of Firebase so the data layer
/// can be tested with a fake, while production always uses
/// [FirebaseOwnerAuth].
abstract class OwnerAuth {
  /// The currently signed-in owner, or null when signed out.
  OwnerAccount? get currentAccount;

  /// Emits on sign-in, sign-out, and token refreshes.
  Stream<OwnerAccount?> authStateChanges();

  Future<OwnerAccount> signIn({
    required String email,
    required String password,
  });

  Future<OwnerAccount> createAccount({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  /// Reloads the account so a newly verified email is reflected immediately.
  Future<OwnerAccount> reloadAccount();

  Future<void> signOut();
}

/// [OwnerAuth] backed exclusively by Firebase Authentication.
///
/// Sessions persist across app restarts using Firebase's local persistence, so
/// a signed-in owner can reopen the dashboard without entering credentials
/// again.
class FirebaseOwnerAuth implements OwnerAuth {
  FirebaseOwnerAuth(this._auth);

  final FirebaseAuth _auth;

  @override
  OwnerAccount? get currentAccount {
    final user = _auth.currentUser;
    return user == null ? null : OwnerAccount.fromUser(user);
  }

  @override
  Stream<OwnerAccount?> authStateChanges() {
    return _auth.authStateChanges().map(
      (user) => user == null ? null : OwnerAccount.fromUser(user),
    );
  }

  @override
  Future<OwnerAccount> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _accountFromCredential(credential);
  }

  @override
  Future<OwnerAccount> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Account creation did not return an account.');
    }

    final displayName = name.trim();
    if (displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }

    // A failed verification email must not undo a successfully created
    // account; the dashboard exposes a resend action instead.
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException {
      // Ignore and let the owner resend from the dashboard.
    }

    await user.reload();
    final refreshed = _auth.currentUser ?? user;
    return OwnerAccount.fromUser(refreshed);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _requireUser();
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  @override
  Future<OwnerAccount> reloadAccount() async {
    final user = _requireUser();
    await user.reload();
    final refreshed = _auth.currentUser ?? user;
    return OwnerAccount.fromUser(refreshed);
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  OwnerAccount _accountFromCredential(UserCredential credential) {
    final user = credential.user;
    if (user == null) {
      throw StateError('Sign-in did not return an account.');
    }
    return OwnerAccount.fromUser(user);
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in with your shop owner account first.');
    }
    return user;
  }
}

/// Creates the Firebase-backed auth service, or returns null when Firebase is
/// not initialized (for example an unconfigured local preview).
OwnerAuth? createOwnerAuth() {
  if (Firebase.apps.isEmpty) return null;
  return FirebaseOwnerAuth(FirebaseAuth.instance);
}
