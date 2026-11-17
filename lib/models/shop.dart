import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/painting.dart';

import '../data/marketplace_link.dart';

/// Category assigned to a product created without one.
const defaultShopProductCategory = 'Parts';

/// Item conditions a seller can choose.
const productConditions = ['New', 'Used', 'Surplus'];

/// One motorcycle's value for the item's spec, e.g. NMAX 155 → NGK CPR8EA-9.
/// It belongs to this listing only; editing it never changes the master table.
class FitSpec {
  const FitSpec({required this.motorcycle, required this.value});

  final String motorcycle;
  final String value;

  Map<String, dynamic> toMap() => {'motorcycle': motorcycle, 'value': value};

  static FitSpec? fromMap(Object? map) {
    if (map is! Map) return null;
    final motorcycle = map['motorcycle'];
    final value = map['value'];
    if (motorcycle is! String || value is! String) return null;
    if (motorcycle.trim().isEmpty || value.trim().isEmpty) return null;
    return FitSpec(motorcycle: motorcycle, value: value);
  }
}

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.quantity,
    this.imageUrl = '',
    this.imageAsset = '',
    this.motorcycles = const [],
    this.photoUrls = const [],
    this.part = '',
    this.isCustomPart = false,
    this.brand = '',
    this.condition = '',
    this.fitsAll = false,
    this.specLabel = '',
    this.specs = const [],
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final int quantity;

  /// Cover photo. Only http(s) URLs are rendered.
  final String imageUrl;

  /// Bundled photo, used by the built-in demo shop. Shown only when
  /// [imageUrl] is empty, so a photo link an owner sets always wins.
  final String imageAsset;

  /// Motorcycles the seller checked as ones this item fits.
  final List<String> motorcycles;

  /// More photos after the cover in [imageUrl], in the seller's order.
  final List<String> photoUrls;

  /// The part picked in Add Item, e.g. "Spark plug".
  final String part;

  /// True when the seller typed their own part name; admins review these.
  final bool isCustomPart;
  final String brand;

  /// One of [productConditions], or empty for older listings.
  final String condition;

  /// "Universal / Fits all motorcycles".
  final bool fitsAll;

  /// What [specs] describe, e.g. "Spark plug".
  final String specLabel;
  final List<FitSpec> specs;

  bool get isAvailable => quantity > 0;

  bool get hasImage =>
      imageUrl.trim().isNotEmpty || imageAsset.trim().isNotEmpty;

  /// The photo to draw when [hasImage] is true.
  ImageProvider get imageProvider => imageUrl.trim().isNotEmpty
      ? NetworkImage(imageUrl)
      : AssetImage(imageAsset);

  /// Every photo, cover first.
  List<ImageProvider> get gallery => [
    if (hasImage) imageProvider,
    for (final url in photoUrls) NetworkImage(url),
  ];

  /// Whether this item is listed as fitting [motorcycle].
  bool fits(String motorcycle) => fitsAll || motorcycles.contains(motorcycle);

  ShopProduct copyWith({
    String? name,
    String? category,
    String? description,
    double? price,
    int? quantity,
    String? imageUrl,
    List<String>? motorcycles,
    List<String>? photoUrls,
    String? brand,
    String? condition,
    bool? fitsAll,
    List<FitSpec>? specs,
  }) {
    return ShopProduct(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      imageAsset: imageAsset,
      motorcycles: motorcycles ?? this.motorcycles,
      photoUrls: photoUrls ?? this.photoUrls,
      part: part,
      isCustomPart: isCustomPart,
      brand: brand ?? this.brand,
      condition: condition ?? this.condition,
      fitsAll: fitsAll ?? this.fitsAll,
      specLabel: specLabel,
      specs: specs ?? this.specs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      if (imageAsset.isNotEmpty) 'imageAsset': imageAsset,
      'motorcycles': motorcycles,
      'photoUrls': photoUrls,
      'part': part,
      'customPart': isCustomPart,
      'brand': brand,
      'condition': condition,
      'fitsAll': fitsAll,
      'specLabel': specLabel,
      'specs': [for (final spec in specs) spec.toMap()],
    };
  }

  factory ShopProduct.fromMap(String id, Map<String, dynamic> map) {
    return ShopProduct(
      id: (map['id'] as String?)?.isNotEmpty == true ? map['id'] as String : id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? defaultShopProductCategory,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      imageAsset: map['imageAsset'] as String? ?? '',
      motorcycles: _stringList(map['motorcycles']),
      photoUrls: _stringList(map['photoUrls']),
      part: map['part'] as String? ?? '',
      isCustomPart: map['customPart'] as bool? ?? false,
      brand: map['brand'] as String? ?? '',
      condition: map['condition'] as String? ?? '',
      fitsAll: map['fitsAll'] as bool? ?? false,
      specLabel: map['specLabel'] as String? ?? '',
      specs: [
        if (map['specs'] case final List<dynamic> specs)
          for (final spec in specs) ?FitSpec.fromMap(spec),
      ],
    );
  }

  static List<String> _stringList(Object? value) => [
    if (value is List)
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item,
  ];
}

class Shop {
  const Shop({
    required this.id,
    required this.ownerEmailHash,
    required this.ownerName,
    required this.name,
    required this.location,
    required this.description,
    required this.products,
    this.contact = '',
    this.marketplaceUrl = '',
    this.marketplaceApproved = false,
    this.isVerified = false,
    this.lastEditedAt,
    this.bannerUrl = '',
  });

  /// Firestore document ID. This is the owner's Firebase Auth UID in cloud
  /// mode, and the owner email in local demo mode.
  final String id;

  /// Salted SHA-256 of the owner's email address. Shop documents are public, so
  /// the plaintext email is never stored on them.
  final String ownerEmailHash;
  final String ownerName;
  final String name;
  final String location;
  final String description;

  /// How buyers reach the seller: a mobile number or a Messenger/Facebook
  /// link. Empty when the seller has not added one.
  final String contact;

  /// The seller's own Shopee or Lazada store link, or empty.
  final String marketplaceUrl;

  /// Set by the app admin in Firebase after checking the store link really
  /// belongs to this seller. Owners can never set it themselves.
  final bool marketplaceApproved;

  /// The store link once approved, so buyers are sent to it; null before.
  MarketplaceLink? get liveMarketplaceLink =>
      marketplaceApproved ? parseMarketplaceLink(marketplaceUrl) : null;

  final List<ShopProduct> products;

  /// Banner picture for the shop page and shop list. Set by the app admin in
  /// the Firebase console; the app never writes it, and the rules stop owners
  /// from changing it. Only http(s) URLs are shown.
  final String bannerUrl;

  bool get hasBanner {
    final uri = Uri.tryParse(bannerUrl.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  /// Whether the owner confirmed their email address. Unverified shops are
  /// hidden from the public shop list.
  final bool isVerified;

  /// Epoch milliseconds of the last shop or product edit. Used by the store to
  /// purge shops that have been idle for more than 30 days.
  final int? lastEditedAt;

  /// Distinct product categories in first-seen order.
  List<String> get categories {
    final seen = <String>{};
    final result = <String>[];
    for (final product in products) {
      final category = product.category.trim();
      if (category.isEmpty || !seen.add(category)) continue;
      result.add(category);
    }
    return List.unmodifiable(result);
  }

  Shop copyWith({
    String? ownerName,
    String? name,
    String? location,
    String? description,
    String? contact,
    String? marketplaceUrl,
    bool? marketplaceApproved,
    List<ShopProduct>? products,
    bool? isVerified,
    int? lastEditedAt,
  }) {
    return Shop(
      id: id,
      ownerEmailHash: ownerEmailHash,
      ownerName: ownerName ?? this.ownerName,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      contact: contact ?? this.contact,
      marketplaceUrl: marketplaceUrl ?? this.marketplaceUrl,
      marketplaceApproved: marketplaceApproved ?? this.marketplaceApproved,
      products: products ?? this.products,
      isVerified: isVerified ?? this.isVerified,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      bannerUrl: bannerUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerEmailHash': ownerEmailHash,
      'ownerName': ownerName,
      'name': name,
      'location': location,
      'description': description,
      'contact': contact,
      'marketplaceUrl': marketplaceUrl,
      'verified': isVerified,
      if (lastEditedAt != null) 'lastEditedAt': lastEditedAt,
    };
  }

  factory Shop.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    return Shop(
      id: doc.id,
      ownerEmailHash: data['ownerEmailHash'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      contact: data['contact'] as String? ?? '',
      marketplaceUrl: data['marketplaceUrl'] as String? ?? '',
      marketplaceApproved: data['marketplaceApproved'] as bool? ?? false,
      products: const <ShopProduct>[],
      isVerified: data['verified'] as bool? ?? false,
      lastEditedAt: (data['lastEditedAt'] as num?)?.toInt(),
      bannerUrl: data['bannerUrl'] as String? ?? '',
    );
  }
}
