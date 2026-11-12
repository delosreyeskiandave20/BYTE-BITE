import 'package:cloud_firestore/cloud_firestore.dart';

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.quantity,
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final int quantity;

  /// Optional product photo. Only http(s) URLs are rendered.
  final String imageUrl;

  bool get isAvailable => quantity > 0;

  bool get hasImage => imageUrl.trim().isNotEmpty;

  ShopProduct copyWith({
    String? name,
    String? category,
    String? description,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return ShopProduct(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
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
    };
  }

  factory ShopProduct.fromMap(String id, Map<String, dynamic> map) {
    return ShopProduct(
      id: (map['id'] as String?)?.isNotEmpty == true ? map['id'] as String : id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Parts',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }
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
    this.lastEditedAt,
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

  final List<ShopProduct> products;

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
    List<ShopProduct>? products,
    int? lastEditedAt,
  }) {
    return Shop(
      id: id,
      ownerEmailHash: ownerEmailHash,
      ownerName: ownerName ?? this.ownerName,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      products: products ?? this.products,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerEmailHash': ownerEmailHash,
      'ownerName': ownerName,
      'name': name,
      'location': location,
      'description': description,
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
      products: const <ShopProduct>[],
      lastEditedAt: (data['lastEditedAt'] as num?)?.toInt(),
    );
  }
}
