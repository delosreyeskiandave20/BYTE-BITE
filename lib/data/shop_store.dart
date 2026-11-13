import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/shop.dart';
import 'owner_auth.dart';
import 'owner_email_hash.dart';

export '../models/shop.dart';
export 'shop_search.dart';

/// Product categories offered by the owner dashboard.
const shopProductCategories = <String>[
  defaultShopProductCategory,
  'Accessories',
  'Maintenance',
];

/// Stores shop profiles and shop products.
///
/// When Firebase is initialized the data is kept in Cloud Firestore and owner
/// accounts are managed exclusively by Firebase Authentication. If Firebase is
/// not configured (for example during a local preview without credentials),
/// the store falls back to read-only in-memory demo shop data; owner
/// authentication stays unavailable.
class ShopStore extends ChangeNotifier {
  ShopStore({OwnerAuth? ownerAuth}) {
    _ownerAuth = ownerAuth ?? createOwnerAuth();
    _listenToAuthState();
    if (Firebase.apps.isNotEmpty) {
      _firestore = FirebaseFirestore.instance;
      _isLoading = true;
      _subscribeToShops();
      purgeStaleShops();
    } else {
      _seedDemoData();
      purgeStaleShops();
    }
  }

  static const _shopsCollection = 'shops';
  static const _productsCollection = 'products';
  static const _maxProductsPerShop = 500;
  static const _maxNameLength = 120;
  static const _maxLocationLength = 120;
  static const _maxShopDescriptionLength = 2000;
  static const _maxCategoryLength = 60;
  static const _maxProductDescriptionLength = 1000;
  static const _staleShopMaxAge = Duration(days: 30);
  static const _firestoreBatchLimit = 400;

  static CollectionReference<Map<String, dynamic>> _shopsRef(
    FirebaseFirestore firestore,
  ) => firestore.collection(_shopsCollection);

  static DocumentReference<Map<String, dynamic>> _shopRef(
    FirebaseFirestore firestore,
    String shopId,
  ) => _shopsRef(firestore).doc(shopId);

  static CollectionReference<Map<String, dynamic>> _productsRef(
    FirebaseFirestore firestore,
    String shopId,
  ) => _shopRef(firestore, shopId).collection(_productsCollection);

  static ShopStore? _sharedInstance;

  /// A process-wide fallback used by screens that are opened without an
  /// explicitly injected store (for example in widget tests). Production code
  /// passes the single store owned by the app shell.
  static ShopStore get shared => _sharedInstance ??= ShopStore();

  FirebaseFirestore? _firestore;
  OwnerAuth? _ownerAuth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _shopsSubscription;
  StreamSubscription<OwnerAccount?>? _authStateSubscription;

  /// Live product listeners, one per shop. Products live in a subcollection so
  /// Firestore rules can validate each product document.
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _productSubscriptions = {};

  final Map<String, Shop> _shopDocuments = {};
  final Map<String, List<ShopProduct>> _productsByShop = {};
  Object? _lastError;
  bool _isLoading = false;

  final List<Shop> _shops = [];
  int _nextProductId = 0;

  /// Whether shop data is backed by Cloud Firestore.
  bool get isCloudConnected => _firestore != null;

  /// Whether Firebase Authentication is available for owner accounts.
  bool get isOwnerAuthAvailable => _ownerAuth != null;

  /// True while the first Firestore snapshot is still being fetched, or while a
  /// manual retry is in flight.
  bool get isLoading => _isLoading;

  /// The most recent Firestore streaming error, if any.
  Object? get lastError => _lastError;

  /// A short, user-facing error description.
  String? get lastErrorMessage {
    final error = _lastError;
    if (error == null) return null;
    if (error is FirebaseException) {
      return error.message ?? error.code;
    }
    return error.toString();
  }

  /// Publicly visible shops. Unverified shops are hidden until the owner
  /// confirms their email address.
  List<Shop> get shops =>
      List.unmodifiable(_shops.where((shop) => shop.isVerified));

  /// The signed-in owner account, or null when signed out.
  OwnerAccount? get signedInAccount => _ownerAuth?.currentAccount;

  String? get signedInEmail {
    final email = signedInAccount?.email;
    return email == null || email.isEmpty ? null : email;
  }

  bool get isSignedIn => signedInEmail != null;

  /// Whether the signed-in owner has confirmed their email address.
  bool get isEmailVerified => signedInAccount?.emailVerified ?? false;

  void _listenToAuthState() {
    _authStateSubscription = _ownerAuth?.authStateChanges().listen((_) {
      // Firebase also emits when ownership changes outside this device, so the
      // dashboard reacts instead of keeping a stale session.
      notifyListeners();
    });
  }

  void _subscribeToShops() {
    _shopsSubscription = _shopsRef(_firestore!).snapshots().listen(
      (snapshot) {
        _lastError = null;
        _isLoading = false;
        _shopDocuments
          ..clear()
          ..addEntries(
            snapshot.docs.map((doc) => MapEntry(doc.id, Shop.fromDoc(doc))),
          );
        _syncProductSubscriptions(snapshot.docs.map((doc) => doc.id).toSet());
        _rebuildShops();
      },
      onError: (Object error) {
        _lastError = error;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Starts product listeners for new shops and stops them for removed shops.
  void _syncProductSubscriptions(Set<String> shopIds) {
    for (final shopId in _productSubscriptions.keys.toList()) {
      if (shopIds.contains(shopId)) continue;
      _productSubscriptions.remove(shopId)?.cancel();
      _productsByShop.remove(shopId);
    }

    for (final shopId in shopIds) {
      if (_productSubscriptions.containsKey(shopId)) continue;
      _productSubscriptions[shopId] = _productsRef(_firestore!, shopId)
          .snapshots()
          .listen(
            (snapshot) {
              _productsByShop[shopId] = snapshot.docs
                  .map((doc) => ShopProduct.fromMap(doc.id, doc.data()))
                  .toList(growable: false);
              _rebuildShops();
            },
            onError: (Object error) {
              _lastError = error;
              _isLoading = false;
              notifyListeners();
            },
          );
    }
  }

  /// Rebuilds the public shop list from the shop documents plus live products.
  void _rebuildShops() {
    _shops
      ..clear()
      ..addAll(
        _shopDocuments.values.map(
          (shop) => shop.copyWith(
            products: _productsByShop[shop.id] ?? const <ShopProduct>[],
          ),
        ),
      );
    notifyListeners();
  }

  /// Cancels the live Firestore listener and subscribes again. The public shop
  /// page calls this from its Retry action.
  void retry() {
    final firestore = _firestore;
    if (firestore == null) return;
    _shopsSubscription?.cancel();
    for (final subscription in _productSubscriptions.values) {
      subscription.cancel();
    }
    _productSubscriptions.clear();
    _shopDocuments.clear();
    _productsByShop.clear();
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    _subscribeToShops();
  }

  /// Creates a Firebase Authentication account for a shop owner.
  ///
  /// The account is signed in immediately and a verification email is sent.
  Future<void> createOwner({
    required String name,
    required String email,
    required String password,
  }) async {
    final ownerAuth = _requireOwnerAuth();
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    final displayName = _requiredText(
      name,
      'Name',
      maxLength: ownerDisplayNameMaxLength,
    );
    if (password.length < ownerPasswordMinLength) {
      throw StateError(
        'Choose a password with at least $ownerPasswordMinLength characters.',
      );
    }
    await ownerAuth.createAccount(
      name: displayName,
      email: normalizedEmail,
      password: password,
    );
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    final ownerAuth = _requireOwnerAuth();
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    if (password.isEmpty) {
      throw StateError('Password is required.');
    }
    await ownerAuth.signIn(email: normalizedEmail, password: password);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _ownerAuth?.signOut();
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final ownerAuth = _requireOwnerAuth();
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    await ownerAuth.sendPasswordResetEmail(normalizedEmail);
  }

  /// Sends (or resends) the Firebase email-verification message.
  Future<void> sendEmailVerification() async {
    final ownerAuth = _requireOwnerAuth();
    await ownerAuth.sendEmailVerification();
  }

  /// Refreshes the cached account after the owner follows the verification
  /// link, so [isEmailVerified] reflects the change without signing in again.
  Future<void> refreshOwnerAccount() async {
    final ownerAuth = _ownerAuth;
    if (ownerAuth == null) return;
    await ownerAuth.reloadAccount();
    await _syncVerifiedStatus();
    notifyListeners();
  }

  /// Publishes the owner's verified status to their shop once confirmed.
  Future<void> _syncVerifiedStatus() async {
    final account = _ownerAuth?.currentAccount;
    if (account == null || !account.emailVerified) return;

    final shop = shopForOwner(account.email);
    if (shop == null || shop.isVerified) return;

    final verifiedShop = shop.copyWith(isVerified: true);
    final firestore = _firestore;
    if (firestore == null) {
      _replaceShop(verifiedShop);
      return;
    }

    await _shopRef(
      firestore,
      shop.id,
    ).set({'verified': true}, SetOptions(merge: true));
    _shopDocuments[shop.id] = verifiedShop;
    _rebuildShops();
  }

  OwnerAuth _requireOwnerAuth() {
    final ownerAuth = _ownerAuth;
    if (ownerAuth == null) throw const OwnerAuthUnavailableException();
    return ownerAuth;
  }

  /// Ensures the signed-in owner matches [normalizedEmail].
  OwnerAccount _requireSignedInOwner(String normalizedEmail) {
    final account = _ownerAuth?.currentAccount;
    if (account == null) {
      throw StateError('Sign in with your shop owner account first.');
    }
    if (account.email != normalizedEmail) {
      throw StateError('You can only edit the shop for the signed-in account.');
    }
    return account;
  }

  Shop? shopForOwner(String email) {
    final hash = ownerEmailHash(_normalizeEmail(email));
    for (final shop in _shops) {
      if (shop.ownerEmailHash == hash) return shop;
    }
    return null;
  }

  /// Returns the owner's shop, reading it from Firestore when it is not in the
  /// live cache yet (for example right after a cold start and sign-in).
  Future<Shop?> loadShopForOwner(String email) async {
    final cached = shopForOwner(email);
    if (cached != null) return cached;

    final firestore = _firestore;
    if (firestore == null) return null;

    final snapshot = await _shopsRef(firestore)
        .where(
          'ownerEmailHash',
          isEqualTo: ownerEmailHash(_normalizeEmail(email)),
        )
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final products = await _readProducts(firestore, doc.id);
    final shop = Shop.fromDoc(doc).copyWith(products: products);
    _shopDocuments[doc.id] = shop;
    _productsByShop[doc.id] = products;
    _rebuildShops();
    return shop;
  }

  Future<List<ShopProduct>> _readProducts(
    FirebaseFirestore firestore,
    String shopId,
  ) async {
    final snapshot = await _productsRef(firestore, shopId).get();
    return snapshot.docs
        .map((doc) => ShopProduct.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  Future<void> saveShop({
    required String ownerEmail,
    required String name,
    required String location,
    required String description,
  }) async {
    final normalizedEmail = _normalizeEmail(ownerEmail);
    _validateEmail(normalizedEmail);
    final trimmedName = _requiredText(
      name,
      'Shop name',
      maxLength: _maxNameLength,
    );
    final trimmedLocation = _requiredText(
      location,
      'Location',
      maxLength: _maxLocationLength,
    );
    final trimmedDescription = _optionalText(
      description,
      'Shop information',
      maxLength: _maxShopDescriptionLength,
    );
    final account = _requireSignedInOwner(normalizedEmail);
    final firestore = _firestore;
    final shopId = firestore == null ? normalizedEmail : account.uid;
    final existing =
        shopForOwner(normalizedEmail) ??
        (firestore == null ? null : await _readShop(firestore, account.uid));
    final shop = Shop(
      id: shopId,
      ownerEmailHash: ownerEmailHash(normalizedEmail),
      ownerName: account.displayName.isEmpty
          ? (existing?.ownerName ?? normalizedEmail)
          : account.displayName,
      name: trimmedName,
      location: trimmedLocation,
      description: trimmedDescription,
      products: existing?.products ?? const <ShopProduct>[],
      isVerified: account.emailVerified || (existing?.isVerified ?? false),
      lastEditedAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (firestore == null) {
      _replaceShop(shop);
      return;
    }

    await _shopRef(
      firestore,
      account.uid,
    ).set(shop.toMap(), SetOptions(merge: true));
    _shopDocuments[account.uid] = shop;
    _productsByShop[account.uid] ??= shop.products;
    _rebuildShops();
  }

  Future<Shop?> _readShop(FirebaseFirestore firestore, String shopId) async {
    final snapshot = await _shopRef(firestore, shopId).get();
    if (!snapshot.exists) return null;
    return Shop.fromDoc(snapshot)
        .copyWith(products: await _readProducts(firestore, shopId));
  }

  Future<void> addProduct({
    required String ownerEmail,
    required String name,
    String category = defaultShopProductCategory,
    String description = '',
    double price = 0,
    int quantity = 0,
    String imageUrl = '',
  }) async {
    final shop = _requireOwnerShop(ownerEmail);
    if (shop.products.length >= _maxProductsPerShop) {
      throw StateError(
        'This shop has reached the $_maxProductsPerShop product limit.',
      );
    }
    final trimmedName = _requiredText(
      name,
      'Product name',
      maxLength: _maxNameLength,
    );
    final trimmedCategory = _requiredText(
      category,
      'Category',
      maxLength: _maxCategoryLength,
    );
    final trimmedDescription = _optionalText(
      description,
      'Product information',
      maxLength: _maxProductDescriptionLength,
    );
    _validatePrice(price);
    _validateQuantity(quantity);
    final normalizedImageUrl = _validateImageUrl(imageUrl);

    final firestore = _firestore;
    final productId = firestore == null
        ? 'product-${_nextProductId++}'
        : _shopsRef(firestore).doc().id;
    final product = ShopProduct(
      id: productId,
      name: trimmedName,
      category: trimmedCategory,
      description: trimmedDescription,
      price: price,
      quantity: quantity,
      imageUrl: normalizedImageUrl,
    );

    if (firestore == null) {
      _replaceShop(
        shop.copyWith(
          products: [...shop.products, product],
          lastEditedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return;
    }

    await _productsRef(firestore, shop.id).doc(productId).set(product.toMap());
  }

  Future<void> updateProduct({
    required String ownerEmail,
    required String productId,
    required String description,
    required double price,
    required int quantity,
    String? name,
    String? category,
    String? imageUrl,
  }) async {
    final shop = _requireOwnerShop(ownerEmail);
    final productIndex = shop.products.indexWhere(
      (product) => product.id == productId,
    );
    if (productIndex == -1) {
      throw StateError('This product no longer exists.');
    }

    _validatePrice(price);
    _validateQuantity(quantity);
    final products = [...shop.products];
    final updated = products[productIndex].copyWith(
      name: name == null
          ? null
          : _requiredText(name, 'Product name', maxLength: _maxNameLength),
      category: category == null
          ? null
          : _requiredText(category, 'Category', maxLength: _maxCategoryLength),
      description: _optionalText(
        description,
        'Product information',
        maxLength: _maxProductDescriptionLength,
      ),
      price: price,
      quantity: quantity,
      imageUrl: imageUrl == null ? null : _validateImageUrl(imageUrl),
    );
    products[productIndex] = updated;

    final firestore = _firestore;
    if (firestore == null) {
      _replaceShop(
        shop.copyWith(
          products: products,
          lastEditedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return;
    }

    await _productsRef(
      firestore,
      shop.id,
    ).doc(productId).set(updated.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct({
    required String ownerEmail,
    required String productId,
  }) async {
    final shop = _requireOwnerShop(ownerEmail);
    final products = shop.products
        .where((product) => product.id != productId)
        .toList(growable: false);
    if (products.length == shop.products.length) {
      throw StateError('This product no longer exists.');
    }

    final firestore = _firestore;
    if (firestore == null) {
      _replaceShop(
        shop.copyWith(
          products: products,
          lastEditedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return;
    }

    await _productsRef(firestore, shop.id).doc(productId).delete();
  }

  Future<void> deleteShop({required String ownerEmail}) async {
    final normalizedEmail = _normalizeEmail(ownerEmail);
    _requireSignedInOwner(normalizedEmail);
    final shop = shopForOwner(normalizedEmail);
    if (shop == null) {
      throw StateError('There is no shop profile to delete.');
    }

    final firestore = _firestore;
    if (firestore != null) {
      final products =
          _productsByShop[shop.id] ?? await _readProducts(firestore, shop.id);
      await _deleteShopDocuments(shop.id, products);
      _productSubscriptions.remove(shop.id)?.cancel();
      _shopDocuments.remove(shop.id);
      _productsByShop.remove(shop.id);
      _rebuildShops();
      return;
    }

    _shops.removeWhere((item) => item.id == shop.id);
    notifyListeners();
  }

  /// Deletes every product document in batches, then the shop document.
  Future<void> _deleteShopDocuments(
    String shopId,
    List<ShopProduct> products,
  ) async {
    final firestore = _firestore!;
    final shopRef = _shopRef(firestore, shopId);
    final productsRef = _productsRef(firestore, shopId);
    final batches = <WriteBatch>[];
    var batch = firestore.batch();
    var pending = 0;

    for (final product in products) {
      batch.delete(productsRef.doc(product.id));
      pending++;
      if (pending == _firestoreBatchLimit) {
        batches.add(batch);
        batch = firestore.batch();
        pending = 0;
      }
    }

    batch.delete(shopRef);
    batches.add(batch);

    for (final item in batches) {
      await item.commit();
    }
  }

  Shop _requireOwnerShop(String ownerEmail) {
    final normalizedEmail = _normalizeEmail(ownerEmail);
    _requireSignedInOwner(normalizedEmail);
    final shop = shopForOwner(normalizedEmail);
    if (shop == null) {
      throw StateError('Create your shop profile before adding products.');
    }
    return shop;
  }

  void purgeStaleShops() {
    final cutoff = DateTime.now()
        .subtract(_staleShopMaxAge)
        .millisecondsSinceEpoch;
    final firestore = _firestore;
    if (firestore == null) {
      final shopsBeforePurge = _shops.length;
      _shops.removeWhere((shop) => _isStale(shop, cutoff));
      if (_shops.length != shopsBeforePurge) notifyListeners();
      return;
    }
    final account = _ownerAuth?.currentAccount;
    if (account == null) return;
    final hash = ownerEmailHash(account.email);
    final stale = _shops
        .where((shop) => shop.ownerEmailHash == hash && _isStale(shop, cutoff))
        .toList(growable: false);
    if (stale.isNotEmpty) {
      // Purge runs in the background on launch, so failures are retried then.
      deleteShop(ownerEmail: account.email).catchError((_) {});
    }
  }

  static bool _isStale(Shop shop, int cutoff) {
    final lastEditedAt = shop.lastEditedAt ?? 0;
    return lastEditedAt > 0 && lastEditedAt < cutoff;
  }

  void _replaceShop(Shop shop) {
    final index = _shops.indexWhere((item) => item.id == shop.id);
    if (index == -1) {
      _shops.add(shop);
    } else {
      _shops[index] = shop;
    }
    notifyListeners();
  }

  void _seedDemoData() {
    _shops.add(
      Shop(
        id: 'demo@motoscan.test',
        ownerEmailHash: ownerEmailHash('demo@motoscan.test'),
        ownerName: 'MotoScan Demo Owner',
        name: 'MotoScan Demo Parts',
        location: 'Quezon City, Metro Manila',
        description: 'Sample motorcycle parts and accessories. Contact the shop to confirm fit and availability.',
        products: const [
          ShopProduct(
            id: 'demo-phone-holder',
            name: 'Universal phone holder',
            category: 'Accessories',
            description:
                'Handlebar-mounted phone holder with an adjustable clamp.',
            price: 450,
            quantity: 8,
          ),
          ShopProduct(
            id: 'demo-tire',
            name: 'Tubeless tire 90/90-17',
            category: defaultShopProductCategory,
            description: 'Everyday road tire. Confirm the size is compatible with your motorcycle.',
            price: 1850,
            quantity: 4,
          ),
          ShopProduct(
            id: 'demo-engine-oil',
            name: 'Motorcycle engine oil 1 L',
            category: 'Maintenance',
            description: 'Sample listing. Check your motorcycle manual for the correct oil specification.',
            price: 320,
            quantity: 0,
          ),
        ],
      ),
    );
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static void _validateEmail(String email) {
    if (!isValidOwnerEmail(email)) {
      throw StateError('Enter a valid email address.');
    }
  }

  static String _requiredText(
    String value,
    String label, {
    required int maxLength,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StateError('$label is required.');
    }
    _validateLength(trimmed, label, maxLength);
    return trimmed;
  }

  static String _optionalText(
    String value,
    String label, {
    required int maxLength,
  }) {
    final trimmed = value.trim();
    _validateLength(trimmed, label, maxLength);
    return trimmed;
  }

  static void _validateLength(String value, String label, int maxLength) {
    if (value.length > maxLength) {
      throw StateError('$label must be $maxLength characters or fewer.');
    }
  }

  static void _validatePrice(double price) {
    if (!price.isFinite || price < 0) {
      throw StateError('Enter a valid price of zero or more.');
    }
  }

  static void _validateQuantity(int quantity) {
    if (quantity < 0) {
      throw StateError('Enter a quantity of zero or more.');
    }
  }

  static String _validateImageUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError('Enter a valid http(s) image URL.');
    }
    return trimmed;
  }

  @override
  void dispose() {
    _shopsSubscription?.cancel();
    _authStateSubscription?.cancel();
    for (final subscription in _productSubscriptions.values) {
      subscription.cancel();
    }
    _productSubscriptions.clear();
    super.dispose();
  }
}

@Deprecated('Use ShopStore instead.')
typedef TemporaryShopStore = ShopStore;

@Deprecated('Use Shop instead.')
typedef TemporaryShop = Shop;

@Deprecated('Use ShopProduct instead.')
typedef TemporaryShopProduct = ShopProduct;
