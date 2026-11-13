import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Minimum password length accepted when creating a shop owner account.
///
/// Firebase allows shorter passwords, but owner accounts protect shop data, so
/// the app asks for a little more.
const ownerPasswordMinLength = 8;

/// Longest display name stored for a shop owner.
const ownerDisplayNameMaxLength = 120;

final _ownerEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Whether [email] looks like a valid address.
///
/// Firebase performs the authoritative check; this only rejects obvious typos
/// before a network request is made.
bool isValidOwnerEmail(String email) => _ownerEmailPattern.hasMatch(email);

/// Immutable snapshot of the signed-in shop owner.
///
/// Credentials are never kept by the app: Firebase Authentication owns them,
/// and this object only mirrors the public account fields the UI needs.
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

  /// Emits whenever the signed-in owner changes, including sign-out.
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
  Future<void> reloadAccount();

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
    return OwnerAccount.fromUser(_requireCredentialUser(credential));
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
    final user = _requireCredentialUser(credential);

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

    return OwnerAccount.fromUser(user);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _requireSignedInUser();
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  @override
  Future<void> reloadAccount() async {
    await _requireSignedInUser().reload();
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  User _requireCredentialUser(UserCredential credential) {
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication did not return an account.');
    }
    return user;
  }

  User _requireSignedInUser() {
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
