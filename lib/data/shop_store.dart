import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/shop.dart';
import 'owner_email_hash.dart';

export '../models/shop.dart';

/// Product categories offered by the owner dashboard.
const shopProductCategories = <String>['Parts', 'Accessories', 'Maintenance'];

/// Stores shop profiles and shop products.
///
/// When Firebase is initialized the data is kept in Cloud Firestore and owner
/// accounts are managed by Firebase Authentication. If Firebase is not
/// configured (for example during a local preview without credentials), the
/// store falls back to the in-memory demo data used by earlier builds.
class ShopStore extends ChangeNotifier {
  ShopStore() {
    if (Firebase.apps.isNotEmpty) {
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _isLoading = true;
      _listenToAuthState();
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

  static ShopStore? _sharedInstance;

  /// A process-wide fallback used by screens that are opened without an
  /// explicitly injected store (for example in widget tests). Production code
  /// passes the single store owned by the app shell.
  static ShopStore get shared => _sharedInstance ??= ShopStore();

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _shopsSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  /// Live product listeners, one per shop. Products live in a subcollection so
  /// Firestore rules can validate each product document.
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _productSubscriptions = {};

  final Map<String, Shop> _shopDocuments = {};
  final Map<String, List<ShopProduct>> _productsByShop = {};
  Object? _lastError;
  bool _isLoading = false;
  String? _demoSignedInEmail;

  final List<Shop> _shops = [];
  final Map<String, _DemoOwner> _demoOwners = {
    'demo@motoscan.test': const _DemoOwner(
      name: 'MotoScan Demo Owner',
      password: 'demo1234',
      pin: '123456',
    ),
  };

  /// In-memory 6-digit PINs for cloud owners. Firebase Auth still authenticates
  /// with the password, but the app additionally requires the PIN.
  final Map<String, String> _ownerPins = {};
  int _nextProductId = 0;

  /// Whether shop data is backed by Cloud Firestore.
  bool get isCloudConnected => _firestore != null;

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

  List<Shop> get shops => List.unmodifiable(_shops);

  String? get signedInEmail =>
      _auth?.currentUser?.email?.toLowerCase() ?? _demoSignedInEmail;

  bool get isSignedIn => signedInEmail != null;

  void _listenToAuthState() {
    _authStateSubscription = _auth?.authStateChanges().listen((user) {
      // Keep the in-memory demo session consistent when Firebase signs the
      // owner out (for example after a password reset on another device).
      if (user == null) _demoSignedInEmail = null;
      notifyListeners();
    });
  }

  void _subscribeToShops() {
    _shopsSubscription = _firestore!
        .collection(_shopsCollection)
        .snapshots()
        .listen(
          (snapshot) {
            _lastError = null;
            _isLoading = false;
            _shopDocuments
              ..clear()
              ..addEntries(
                snapshot.docs.map((doc) => MapEntry(doc.id, Shop.fromDoc(doc))),
              );
            _syncProductSubscriptions(
              snapshot.docs.map((doc) => doc.id).toSet(),
            );
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
      _productSubscriptions[shopId] = _firestore!
          .collection(_shopsCollection)
          .doc(shopId)
          .collection(_productsCollection)
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

  Future<void> createOwner({
    required String name,
    required String email,
    required String password,
    String pin = '',
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    if (password.length < 8) {
      throw StateError('Choose a password with at least 8 characters.');
    }
    if (pin.length != 6 || int.tryParse(pin) == null) {
      throw StateError('Enter a 6-digit PIN.');
    }
    final auth = _auth;
    if (auth == null) {
      if (_demoOwners.containsKey(normalizedEmail)) {
        throw StateError('An owner account already exists for this email.');
      }
      _demoOwners[normalizedEmail] = _DemoOwner(
        name: name.trim(),
        password: password,
        pin: pin,
      );
      _demoSignedInEmail = normalizedEmail;
      notifyListeners();
      return;
    }

    final credential = await auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final displayName = name.trim();
    if (displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }
    final uid = credential.user?.uid;
    if (uid != null) _ownerPins[uid] = pin;
  }

  Future<void> signIn({
    required String email,
    required String password,
    String pin = '',
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    final auth = _auth;
    if (auth == null) {
      final owner = _demoOwners[normalizedEmail];
      if (owner == null || owner.password != password || owner.pin != pin) {
        throw StateError('Email, password, or PIN is incorrect.');
      }
      _demoSignedInEmail = normalizedEmail;
      notifyListeners();
      return;
    }

    await auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = auth.currentUser;
    if (user != null) {
      final storedPin = _ownerPins[user.uid];
      if (storedPin != null && storedPin != pin) {
        await auth.signOut();
        throw StateError('Email, password, or PIN is incorrect.');
      }
      _ownerPins[user.uid] = pin;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth?.signOut();
    _demoSignedInEmail = null;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    _validateEmail(normalizedEmail);
    final auth = _auth;
    if (auth == null) {
      throw StateError(
        'Password reset is only available when Firebase is connected.',
      );
    }
    await auth.sendPasswordResetEmail(email: normalizedEmail);
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

    final snapshot = await firestore
        .collection(_shopsCollection)
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
    final snapshot = await firestore
        .collection(_shopsCollection)
        .doc(shopId)
        .collection(_productsCollection)
        .get();
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
    final trimmedName = _requiredText(name, 'Shop name', maxLength: 120);
    final trimmedLocation = _requiredText(location, 'Location', maxLength: 120);
    final trimmedDescription = _optionalText(
      description,
      'Shop information',
      maxLength: 2000,
    );
    final firestore = _firestore;

    if (firestore == null) {
      final owner = _demoOwners[normalizedEmail];
      if (owner == null) {
        throw StateError('Sign in with a demo owner account first.');
      }
      final existing = shopForOwner(normalizedEmail);
      final shop = Shop(
        id: normalizedEmail,
        ownerEmailHash: ownerEmailHash(normalizedEmail),
        ownerName: owner.name,
        name: trimmedName,
        location: trimmedLocation,
        description: trimmedDescription,
        products: existing?.products ?? const <ShopProduct>[],
        lastEditedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _replaceShop(shop);
      return;
    }

    final user = _auth?.currentUser;
    if (user == null) {
      throw StateError('Sign in with your shop owner account first.');
    }
    if (_normalizeEmail(user.email ?? '') != normalizedEmail) {
      throw StateError('You can only edit the shop for the signed-in account.');
    }

    final existing =
        shopForOwner(normalizedEmail) ?? await _readShop(firestore, user.uid);
    final displayName = user.displayName?.trim();
    final shop = Shop(
      id: user.uid,
      ownerEmailHash: ownerEmailHash(normalizedEmail),
      ownerName: displayName == null || displayName.isEmpty
          ? (existing?.ownerName ?? normalizedEmail)
          : displayName,
      name: trimmedName,
      location: trimmedLocation,
      description: trimmedDescription,
      products: existing?.products ?? const <ShopProduct>[],
      lastEditedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await firestore
        .collection(_shopsCollection)
        .doc(user.uid)
        .set(shop.toMap(), SetOptions(merge: true));
    _shopDocuments[user.uid] = shop;
    _productsByShop[user.uid] ??= shop.products;
    _rebuildShops();
  }

  Future<Shop?> _readShop(FirebaseFirestore firestore, String shopId) async {
    final snapshot = await firestore
        .collection(_shopsCollection)
        .doc(shopId)
        .get();
    if (!snapshot.exists) return null;
    return Shop.fromDoc(snapshot)
        .copyWith(products: await _readProducts(firestore, shopId));
  }

  Future<void> addProduct({
    required String ownerEmail,
    required String name,
    String category = 'Parts',
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
    final trimmedName = _requiredText(name, 'Product name', maxLength: 120);
    final trimmedCategory = _requiredText(category, 'Category', maxLength: 60);
    final trimmedDescription = _optionalText(
      description,
      'Product information',
      maxLength: 1000,
    );
    _validatePrice(price);
    _validateQuantity(quantity);
    final normalizedImageUrl = _validateImageUrl(imageUrl);

    final firestore = _firestore;

    if (firestore == null) {
      final productId = 'product-${_nextProductId++}';
      final product = ShopProduct(
        id: productId,
        name: trimmedName,
        category: trimmedCategory,
        description: trimmedDescription,
        price: price,
        quantity: quantity,
        imageUrl: normalizedImageUrl,
      );
      _replaceShop(
        shop.copyWith(
          products: [...shop.products, product],
          lastEditedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return;
    }

    final user = _auth?.currentUser;
    if (user == null) {
      throw StateError('Sign in with your shop owner account first.');
    }
    if (_normalizeEmail(user.email ?? '') != _normalizeEmail(ownerEmail)) {
      throw StateError('You can only edit the shop for the signed-in account.');
    }

    final productId = firestore.collection(_shopsCollection).doc().id;
    final product = ShopProduct(
      id: productId,
      name: trimmedName,
      category: trimmedCategory,
      description: trimmedDescription,
      price: price,
      quantity: quantity,
      imageUrl: normalizedImageUrl,
    );

    await firestore
        .collection(_shopsCollection)
        .doc(shop.id)
        .collection(_productsCollection)
        .doc(productId)
        .set(product.toMap());
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
          : _requiredText(name, 'Product name', maxLength: 120),
      category: category == null
          ? null
          : _requiredText(category, 'Category', maxLength: 60),
      description: _optionalText(
        description,
        'Product information',
        maxLength: 1000,
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

    await firestore
        .collection(_shopsCollection)
        .doc(shop.id)
        .collection(_productsCollection)
        .doc(productId)
        .set(updated.toMap(), SetOptions(merge: true));
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

    await firestore
        .collection(_shopsCollection)
        .doc(shop.id)
        .collection(_productsCollection)
        .doc(productId)
        .delete();
  }

  Future<void> deleteShop({required String ownerEmail}) async {
    final normalizedEmail = _normalizeEmail(ownerEmail);
    final shop = shopForOwner(normalizedEmail);
    if (shop == null) {
      throw StateError('There is no shop profile to delete.');
    }

    final firestore = _firestore;
    if (firestore != null) {
      final user = _auth?.currentUser;
      if (user == null) {
        throw StateError('Sign in with your shop owner account first.');
      }
      if (_normalizeEmail(user.email ?? '') != normalizedEmail) {
        throw StateError(
          'You can only delete the shop for the signed-in account.',
        );
      }
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
    final shopRef = firestore.collection(_shopsCollection).doc(shopId);
    final batches = <WriteBatch>[];
    var batch = firestore.batch();
    var pending = 0;

    for (final product in products) {
      batch.delete(shopRef.collection(_productsCollection).doc(product.id));
      pending++;
      if (pending == 400) {
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
    final shop = shopForOwner(normalizedEmail);
    if (shop == null) {
      throw StateError('Create your shop profile before adding products.');
    }
    return shop;
  }

  void purgeStaleShops() {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;
    final firestore = _firestore;
    if (firestore == null) {
      final before = _shops.length;
      _shops.removeWhere(
        (shop) =>
            (shop.lastEditedAt ?? 0) > 0 && (shop.lastEditedAt ?? 0) < cutoff,
      );
      if (_shops.length != before) notifyListeners();
      return;
    }
    final user = _auth?.currentUser;
    if (user == null) return;
    final hash = ownerEmailHash(_normalizeEmail(user.email ?? ''));
    final stale = _shops
        .where(
          (shop) =>
              shop.ownerEmailHash == hash &&
              (shop.lastEditedAt ?? 0) > 0 &&
              (shop.lastEditedAt ?? 0) < cutoff,
        )
        .toList(growable: false);
    if (stale.isNotEmpty) {
      deleteShop(ownerEmail: user.email!).catchError((_) {});
    }
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
            category: 'Parts',
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
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
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
    if (trimmed.length > maxLength) {
      throw StateError('$label must be $maxLength characters or fewer.');
    }
    return trimmed;
  }

  static String _optionalText(
    String value,
    String label, {
    required int maxLength,
  }) {
    final trimmed = value.trim();
    if (trimmed.length > maxLength) {
      throw StateError('$label must be $maxLength characters or fewer.');
    }
    return trimmed;
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

List<ShopProduct> availableProductsForQuery(Shop shop, String query) {
  return shop.products
      .where(
        (product) =>
            product.isAvailable && matchesShopProductQuery(product.name, query),
      )
      .toList(growable: false);
}

bool matchesShopProductQuery(String productName, String query) {
  final queryWords = _searchWords(query);
  final productWords = _searchWords(productName);
  if (productWords.isEmpty) return false;
  final matchingWords = productWords.intersection(queryWords).length;
  return matchingWords >= (productWords.length < 2 ? productWords.length : 2);
}

Set<String> _searchWords(String value) => value
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where(
      (word) =>
          word.length > 1 &&
          word != 'motorcycle' &&
          word != 'motoscan' &&
          word != 'universal' &&
          word != 'replacement' &&
          word != 'with' &&
          word != 'and' &&
          word != 'for',
    )
    .toSet();

class _DemoOwner {
  const _DemoOwner({
    required this.name,
    required this.password,
    required this.pin,
  });

  final String name;
  final String password;
  final String pin;
}

@Deprecated('Use ShopStore instead.')
typedef TemporaryShopStore = ShopStore;

@Deprecated('Use Shop instead.')
typedef TemporaryShop = Shop;

@Deprecated('Use ShopProduct instead.')
typedef TemporaryShopProduct = ShopProduct;
